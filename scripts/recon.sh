#!/usr/bin/env bash
# Levantamento do ambiente antes de provisionar o cluster.
#
# Documentar o estado da máquina alvo antes de mexer nela é prática padrão de
# infraestrutura — e é o que permite reproduzir ou depurar o que der errado.
#
# Uso:
#   ./scripts/recon.sh | tee notas/recon-$(hostname).txt

set -uo pipefail

linha() { printf '\n== %s\n' "$1"; }
item()  { printf '%-6s %-22s %s\n' "$1" "$2" "${3:-}"; }

linha "sistema"
uname -srm
grep -m1 PRETTY /etc/os-release

linha "cpu"
lscpu | grep -E '^(Model name|Nome do modelo|CPU\(s\)|Thread|Core)' | sed 's/  */ /g'

linha "memória"
free -h | head -2

linha "disco"
df -h / /home /var/lib/libvirt 2>/dev/null | grep -v tmpfs | sort -u

linha "virtualização por hardware"
n=$(grep -c -E 'vmx|svm' /proc/cpuinfo)
if [ "$n" -gt 0 ]; then
  echo "suportada (flags em $n threads)"
else
  echo "NÃO suportada — verifique VT-x/AMD-V na BIOS"
fi
if [ -c /dev/kvm ]; then
  echo "/dev/kvm presente: $(stat -c '%A %U:%G' /dev/kvm)"
else
  echo "/dev/kvm AUSENTE — módulo kvm não carregado"
fi

linha "outros hipervisores (podem disputar a CPU)"
lsmod | grep -iE '^(vbox|vmw)' | awk '{print $1}' | paste -sd' ' || true
lsmod | grep -qiE '^vbox' && echo "VirtualBox carregado — não rode VMs dele junto com o cluster" || echo "nenhum conflito detectado"

linha "ferramentas"
for t in qemu-system-x86_64 virsh virt-install virt-manager virt-clone \
         qemu-img dnsmasq git python3 wget rsync; do
  if p=$(command -v "$t" 2>/dev/null); then
    item "OK" "$t" "$p"
  else
    item "FALTA" "$t" "ausente"
  fi
done

linha "pacotes (Arch)"
for p in libvirt qemu-desktop qemu-base virt-install virt-manager dnsmasq iptables-nft; do
  if v=$(pacman -Q "$p" 2>/dev/null); then
    item "OK" "$p" "${v#* }"
  else
    item "FALTA" "$p" "não instalado"
  fi
done

linha "grupos do usuário"
id -nG
id -nG | grep -qw libvirt && echo "-> pertence ao grupo libvirt" \
  || echo "-> NÃO pertence ao grupo libvirt (necessário; exige relogar após usermod)"

linha "estado do libvirt"
echo "ativo agora: $(systemctl is-active libvirtd 2>/dev/null; true)"
echo "habilitado no boot: $(systemctl is-enabled libvirtd 2>/dev/null; true)"

if command -v virsh >/dev/null 2>&1; then
  linha "redes libvirt";        virsh net-list --all 2>&1 | head -8
  linha "pools de armazenamento"; virsh pool-list --all 2>&1 | head -8
  linha "VMs existentes";       virsh list --all 2>&1 | head -8
else
  linha "libvirt"
  echo "virsh ausente — rode a etapa 0 de docs/01-sessao-sabado.md antes de seguir"
fi

linha "capacidade estimada"
disp=$(free -m | awk '/^Mem/ {print $7}')
livre_gb=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
if [ -n "${disp:-}" ] && [ "$disp" -gt 0 ] 2>/dev/null; then
  nos=$(( (disp - 4096) / 2048 ))
  [ "$nos" -lt 0 ] && nos=0
  echo "memória disponível: ${disp} MB  ->  ${nos} nós de 2 GB (reservando 4 GB ao hospedeiro)"
fi
if [ -n "${livre_gb:-}" ]; then
  echo "disco livre em /: ${livre_gb} GB"
  if [ "$livre_gb" -lt 40 ]; then
    echo "AVISO: pouco espaço — use discos de 10 GB por nó, não 20 GB"
  fi
fi

printf '\n'
