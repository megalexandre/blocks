#!/usr/bin/env bash
#
# Compõe as folhas de interface a partir do pacote Treasure Hunters.
#
# Por que folhas compostas, e não os 344 arquivos soltos: o pubspec não inclui
# subpastas, então declarar o pacote inteiro custaria uma linha por família; os
# nomes de origem (`1.png`..`16.png`) não dizem o que é cada tile; e o projeto
# já tem um jeito de fatiar folha por índice (`BlockSprites`). Uma folha por
# tamanho de tile é o mesmo objeto que já existe, com outro conteúdo.
#
# A pasta de origem fica fora do bundle de graça: `assets/images/` é declarado
# no pubspec, e declarar um diretório não inclui os subdiretórios dele.
#
# Uso: tool/build_ui_sheets.sh
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
origem="$raiz/assets/images/adventures"
destino="$raiz/assets/images/ui"

if [ ! -d "$origem" ]; then
  echo "não achei $origem" >&2
  exit 1
fi

mkdir -p "$destino"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Os arquivos 1..9 de cada painel já são o nine-slice em ordem de leitura:
# 1 = canto superior esquerdo, 5 = miolo, 9 = canto inferior direito. Os
# 10..16 são extras (trilho divisor, tira estreita) que nada aqui usa.
#
# A lista é explícita de propósito: o glob ordena 1, 10, 11, ..., 2, 3.
nove_slice() {
  local pasta="$1" saida="$2"
  local partes=()
  for i in 1 2 3 4 5 6 7 8 9; do
    partes+=("$origem/$pasta/$i.png")
  done
  convert -background none "${partes[@]}" -append "$saida"
}

# Painéis: cada família vira um bloco de 96×96 (3×3 de 32), e as famílias
# empilham. A ordem aqui é a mesma do enum `PanelFamily` em Dart.
for familia in "Green Board" "Yellow Board" "Orange Paper" "Yellow Paper"; do
  linhas=()
  for linha in 0 1 2; do
    trio=()
    for coluna in 1 2 3; do
      trio+=("$origem/$familia/$((linha * 3 + coluna)).png")
    done
    convert -background none "${trio[@]}" +append "$tmp/linha$linha.png"
    linhas+=("$tmp/linha$linha.png")
  done
  convert -background none "${linhas[@]}" -append "$tmp/${familia// /_}.png"
done
convert -background none \
  "$tmp/Green_Board.png" "$tmp/Yellow_Board.png" \
  "$tmp/Orange_Paper.png" "$tmp/Yellow_Paper.png" \
  -append "$destino/panels.png"

# Fontes e ícones: fitas horizontais, um glifo por índice.
fita() {
  local pasta="$1" quantos="$2" saida="$3"
  local partes=()
  for i in $(seq 1 "$quantos"); do
    partes+=("$origem/$pasta/$i.png")
  done
  convert -background none "${partes[@]}" +append "$saida"
}

fita "Big Text" 36 "$destino/big_text.png"
fita "Small Text/Small Text" 52 "$destino/small_text.png"
fita "Small Text/Small Icons" 25 "$destino/icons.png"

echo "folhas em $destino:"
identify -format '  %f  %wx%h\n' "$destino"/*.png
