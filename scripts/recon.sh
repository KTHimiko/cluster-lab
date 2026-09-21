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

linha "sistema"
uname -srm
grep -m1 PRETTY /etc/os-release

linha "cpu"
lscpu | grep -E '^(Model name|Nome do modelo|CPU\(s\)|Thread|Core)' | sed 's/  */ /g'

linha "memória"
free -h | head -2

linha "disco"
df -h / /home 2>/dev/null | grep -v tmpfs

linha "virtualização por hardware"
n=$(grep -c -E 'vmx|svm' /proc/cpuinfo)
if [ "$n" -gt 0 ]; then
  echo "suportada (flags em $n threads)"
else
  echo "NÃO suportada — verifique VT-x/AMD-V na BIOS"
fi

linha "ferramentas"
for t in qemu-system-x86_64 virsh virt-install virt-manager virt-clone \
         dnsmasq docker git python3 wget qemu-img; do
  if p=$(command -v "$t" 2>/dev/null); then
    printf 'OK   %-22s %s\n' "$t" "$p"
  else
    printf '--   %-22s ausente\n' "$t"
  fi
done

linha "pacotes (Arch)"
pacman -Q libvirt qemu-desktop qemu-base virt-install dnsmasq iptables-nft 2>&1 \
  | sed 's/^error.*was not found/ausente:/'

linha "grupos do usuário"
id -nG

linha "estado do libvirt"
echo "libvirtd: $(systemctl is-active libvirtd 2>/dev/null || echo inativo)"
echo "libvirtd habilitado no boot: $(systemctl is-enabled libvirtd 2>/dev/null || echo não)"

linha "redes libvirt"
virsh net-list --all 2>&1 | head -8

linha "pools de armazenamento"
virsh pool-list --all 2>&1 | head -8

linha "VMs existentes"
virsh list --all 2>&1 | head -8

linha "capacidade estimada"
disp=$(free -m | awk '/^Mem|^Mem\./ {print $7}')
if [ -n "${disp:-}" ] && [ "$disp" -gt 0 ] 2>/dev/null; then
  # reserva 4 GB para o hospedeiro, 2 GB por nó
  nos=$(( (disp - 4096) / 2048 ))
  [ "$nos" -lt 0 ] && nos=0
  echo "memória disponível: ${disp} MB"
  echo "nós de 2 GB que cabem (reservando 4 GB para o hospedeiro): ${nos}"
  [ "$nos" -lt 3 ] && echo "AVISO: menos de 3 nós cabem — reduza para 1 GB por nó ou use 2 nós"
else
  echo "não foi possível estimar"
fi

printf '\n'
