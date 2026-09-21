#!/usr/bin/env bash
# Gera o cloud-init de um nó a partir do template, injetando a chave pública
# do usuário e o hostname pedido.
#
# A saída vai para build/, que não é versionado: chave e hostname pertencem à
# máquina, não ao projeto. O repositório guarda só o template.
#
# Uso:
#   ./scripts/render-cloud-init.sh            # gera para o nó "head"
#   ./scripts/render-cloud-init.sh node01
#   ./scripts/render-cloud-init.sh node01 ~/.ssh/outra_chave.pub

set -euo pipefail

no="${1:-head}"
chave="${2:-$HOME/.ssh/id_ed25519.pub}"

raiz="$(cd "$(dirname "$0")/.." && pwd)"
template="$raiz/config/cloud-init-head.yaml"
saida="$raiz/build/cloud-init-$no.yaml"

if [ ! -f "$template" ]; then
  echo "template ausente: $template" >&2
  exit 1
fi

if [ ! -f "$chave" ]; then
  echo "chave pública ausente: $chave" >&2
  echo "gere uma com: ssh-keygen -t ed25519" >&2
  exit 1
fi

mkdir -p "$raiz/build"
pub="$(cat "$chave")"

sed -e "s|^hostname: .*|hostname: ${no}|" \
    -e "s|^fqdn: .*|fqdn: ${no}.lab|" \
    -e "s|^\( *\)- ssh-ed25519 SUBSTITUA.*|\1- ${pub}|" \
    "$template" > "$saida"

if grep -q 'SUBSTITUA' "$saida"; then
  echo "ERRO: a chave não foi injetada — o marcador do template mudou?" >&2
  exit 1
fi

echo "gerado: $saida"
echo "  hostname: $(awk '/^hostname:/ {print $2}' "$saida")"
echo "  chave:    $(awk '/ssh-ed25519/ {print $3}' "$saida")"
