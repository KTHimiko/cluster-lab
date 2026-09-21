#!/usr/bin/env bash
# Constrói o seed ISO NoCloud de um nó.
#
# POR QUE ESTE SCRIPT EXISTE
# O `virt-install --cloud-init` anexa um ISO que o cloud-init do Debian não
# encontra: ele procura um dispositivo com rótulo de volume `cidata` e o ISO
# gerado não chega com esse rótulo. O resultado é silencioso e cruel — a VM
# sobe normalmente, sem o usuário e sem a chave, e você só descobre ao tentar
# entrar. Aqui o ISO é construído com o rótulo certo e fica em disco, podendo
# ser inspecionado.
#
# Uso:
#   ./scripts/make-seed.sh            # nó "head"
#   ./scripts/make-seed.sh node01

set -euo pipefail

no="${1:-head}"
raiz="$(cd "$(dirname "$0")/.." && pwd)"
ci="$raiz/build/cloud-init-$no.yaml"
saida="$raiz/build/seed-$no.iso"

if [ ! -f "$ci" ]; then
  echo "cloud-init do nó '$no' não existe: $ci" >&2
  echo "gere antes com: ./scripts/render-cloud-init.sh $no" >&2
  exit 1
fi

if ! command -v xorrisofs >/dev/null 2>&1; then
  echo "xorrisofs ausente — instale: sudo pacman -S libisoburn" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp "$ci" "$tmp/user-data"

# instance-id novo a cada build: se repetir, o cloud-init considera a
# instância já provisionada e não refaz nada.
cat > "$tmp/meta-data" <<EOF
instance-id: ${no}-$(date +%s)
local-hostname: ${no}
EOF

xorrisofs -quiet -output "$saida" -volid cidata -joliet -rock \
  "$tmp/user-data" "$tmp/meta-data"

rotulo=$(blkid -s LABEL -o value "$saida" 2>/dev/null || echo "?")
if [ "$rotulo" != "cidata" ]; then
  echo "ERRO: rótulo do ISO saiu como '$rotulo', esperado 'cidata'" >&2
  exit 1
fi

echo "gerado: $saida"
echo "  rótulo:      $rotulo"
echo "  instance-id: $(awk '/instance-id/ {print $2}' "$tmp/meta-data")"
echo "  tamanho:     $(du -h "$saida" | cut -f1)"
