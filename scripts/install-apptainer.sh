#!/usr/bin/env bash
# Instala o Apptainer em todos os nós do cluster.
#
# POR QUE ESTE SCRIPT EXISTE
# O Apptainer não está nos repositórios do Debian 12 — nem como `apptainer`
# nem como `singularity-container`. Vem do .deb oficial do upstream.
#
# O download acontece UMA vez, no /home do head, que é exportado por NFS.
# Os outros nós instalam a partir do mesmo arquivo. É o mesmo princípio que
# faz uma imagem de container servir o cluster inteiro: armazenamento
# compartilhado existe para não multiplicar trabalho por nó.
#
# Usamos a variante SEM setuid: o kernel do guest tem namespaces de usuário
# sem privilégio habilitados (max_user_namespaces > 0), então o Apptainer
# roda sem binário privilegiado — menos superfície de ataque.
#
# Uso:
#   ./scripts/install-apptainer.sh            # versão padrão abaixo
#   ./scripts/install-apptainer.sh 1.5.3

set -euo pipefail

versao="${1:-1.5.3}"
raiz="$(cd "$(dirname "$0")/.." && pwd)"
hosts_file="$raiz/config/hosts"

if [ ! -f "$hosts_file" ]; then
  echo "config/hosts não encontrado: $hosts_file" >&2
  exit 1
fi

# lê os nós do /etc/hosts do cluster, ignorando comentários e loopback
mapfile -t nos < <(awk '!/^#/ && /^192\./ {print $2}' "$hosts_file")
if [ "${#nos[@]}" -eq 0 ]; then
  echo "nenhum nó encontrado em $hosts_file" >&2
  exit 1
fi

head_no="${nos[0]}"
url="https://github.com/apptainer/apptainer/releases/download/v${versao}/apptainer_${versao}_amd64.deb"
deb="/home/luan/apptainer_${versao}.deb"

remoto() { ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "luan@$1" "${@:2}"; }

echo "nós: ${nos[*]}"
echo "versão: $versao"

echo
echo "-> baixando no $head_no (chega aos demais pelo NFS)"
remoto "$head_no" "test -f '$deb' || curl -sSL -o '$deb' '$url'; ls -lh '$deb' | awk '{print \$5}'"

for no in "${nos[@]}"; do
  echo "-> instalando em $no"
  remoto "$no" "export DEBIAN_FRONTEND=noninteractive
    sudo apt-get install -y -qq '$deb' >/dev/null 2>&1
    printf '   %s: %s\n' \"\$(hostname)\" \"\$(apptainer --version)\""
done

echo
echo "-> verificando namespaces de usuário (necessários para a variante sem setuid)"
for no in "${nos[@]}"; do
  remoto "$no" 'printf "   %s: max_user_namespaces=%s\n" "$(hostname)" "$(cat /proc/sys/user/max_user_namespaces)"'
done
