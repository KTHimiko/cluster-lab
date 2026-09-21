#!/usr/bin/env bash
# Liga e desliga o cluster sob demanda.
#
# POR QUE NÃO AUTOSTART
# Esta máquina também é um computador pessoal. Três VMs de 4 GB tomam 12 GB de
# RAM e sobem a cada boot, mesmo quando você só quer usar o navegador. Ligar à
# mão custa um comando e devolve a memória quando não está em uso.
#
# A ORDEM IMPORTA
# Os nós montam o /home do head por NFS. Subir um nó antes do head deixa a
# montagem falhando; desligar o head antes dos nós trava os nós numa montagem
# que não responde mais. Por isso:
#
#   ligar:    rede → pool → head → nós
#   desligar: nós → head
#
# Uso:
#   ./scripts/cluster.sh start     liga tudo e espera ficar pronto
#   ./scripts/cluster.sh stop      desliga na ordem correta
#   ./scripts/cluster.sh status    estado atual, sem mexer em nada
#   ./scripts/cluster.sh ssh       conecta no head

set -uo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system

HEAD_IP=192.168.122.10
VMS_NOS=(node01 node02)
TODAS=(head "${VMS_NOS[@]}")
ESPERA_MAX=180        # segundos aguardando o cluster responder

azul()    { printf '\033[34m%s\033[0m\n' "$*"; }
ok()      { printf '  \033[32mok\033[0m    %s\n' "$*"; }
aviso()   { printf '  \033[33m!\033[0m     %s\n' "$*"; }
erro()    { printf '  \033[31mfalha\033[0m %s\n' "$*"; }
passo()   { printf '  ...   %s\n' "$*"; }

sshx() { ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=4 "luan@$HEAD_IP" "$@" 2>/dev/null; }

verificar_libvirt() {
    if ! systemctl is-active --quiet libvirtd; then
        passo "libvirtd parado, iniciando"
        sudo systemctl start libvirtd || { erro "não foi possível iniciar o libvirtd"; exit 1; }
    fi
    ok "libvirtd ativo"
}

ligar() {
    azul "Ligando o cluster"
    verificar_libvirt

    # A rede precisa existir antes de qualquer VM: é dela que vêm os endereços
    # fixos por reserva DHCP.
    # `net-list --name` imprime só as redes ATIVAS, e são nomes, não texto
    # traduzido. Comparar contra "Ativo: sim" quebra em inglês, e o pool nem
    # usa essa palavra — diz "Estado: executando".
    if ! virsh net-list --name 2>/dev/null | grep -qx default; then
        passo "subindo a rede default"
        sudo virsh net-start default >/dev/null 2>&1
    fi
    ok "rede default ativa"

    if ! virsh pool-list --name 2>/dev/null | grep -qx default; then
        passo "subindo o pool de armazenamento"
        sudo virsh pool-start default >/dev/null 2>&1
    fi
    ok "pool default ativo"

    # head primeiro: ele serve o NFS que os nós montam no boot.
    for vm in "${TODAS[@]}"; do
        if virsh list --name 2>/dev/null | grep -qx "$vm"; then
            ok "$vm já estava rodando"
        else
            passo "iniciando $vm"
            virsh start "$vm" >/dev/null 2>&1 && ok "$vm iniciada" || erro "$vm não iniciou"
        fi
        [ "$vm" = "head" ] && sleep 12   # dá tempo do NFS subir antes dos nós
    done

    azul "Aguardando o cluster responder"
    local t=0
    while [ $t -lt $ESPERA_MAX ]; do
        # -N força uma linha por nó. Sem ela o sinfo AGRUPA os nós por
        # estado, e três nós ociosos viram uma única linha "idle" — o teste
        # nunca alcançava três e o script dava timeout com o cluster no ar.
        local prontos
        prontos=$(sshx 'sinfo -h -N -o "%T" 2>/dev/null | grep -c idle' || echo 0)
        if [ "${prontos:-0}" -ge 3 ]; then
            ok "três nós em idle após ${t}s"
            sshx 'sinfo' | sed 's/^/  /'
            return 0
        fi
        sleep 6; t=$((t+6))
    done

    aviso "não ficou pronto em ${ESPERA_MAX}s — veja o estado abaixo"
    estado
    return 1
}

desligar() {
    azul "Desligando o cluster"

    # Nós primeiro: eles têm o /home do head montado por NFS e travariam se o
    # servidor sumisse debaixo deles.
    for vm in "${VMS_NOS[@]}" head; do
        if ! virsh list --name 2>/dev/null | grep -qx "$vm"; then
            ok "$vm já estava desligada"
            continue
        fi
        passo "desligando $vm"
        virsh shutdown "$vm" >/dev/null 2>&1

        local t=0
        while [ $t -lt 60 ]; do
            virsh list --name 2>/dev/null | grep -qx "$vm" || break
            sleep 3; t=$((t+3))
        done

        if virsh list --name 2>/dev/null | grep -qx "$vm"; then
            aviso "$vm não respondeu ao desligamento, forçando"
            virsh destroy "$vm" >/dev/null 2>&1
        fi
        ok "$vm desligada"
    done

    azul "Memória devolvida"
    free -h | awk '/^Mem|^Mem\./ {print "  disponível agora: "$7}'
}

estado() {
    azul "Estado"
    verificar_libvirt >/dev/null 2>&1
    printf "  %-8s %-14s %s\n" "VM" "estado" "endereço"
    for vm in "${TODAS[@]}"; do
        local st ip
        if virsh list --name 2>/dev/null | grep -qx "$vm"; then st="executando"
        elif virsh list --all --name 2>/dev/null | grep -qx "$vm"; then st="desligada"
        else st="não existe"; fi
        ip=$(virsh domifaddr "$vm" 2>/dev/null | awk '/ipv4/{print $4}')
        printf "  %-8s %-14s %s\n" "$vm" "${st:-?}" "${ip:--}"
    done

    if sshx true; then
        echo
        sshx 'sinfo' | sed 's/^/  /'
        local fila; fila=$(sshx 'squeue -h | wc -l')
        echo "  jobs na fila: ${fila:-?}"
    else
        echo
        aviso "head não responde por SSH"
    fi
}

case "${1:-status}" in
    start|ligar)    ligar ;;
    stop|desligar)  desligar ;;
    status|estado)  estado ;;
    ssh)            exec ssh "luan@$HEAD_IP" ;;
    *)
        echo "uso: $0 {start|stop|status|ssh}"
        exit 1 ;;
esac
