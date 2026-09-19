import 'dart:ui';

import 'package:flame/components.dart';

import '../game/model/column.dart';
import '../game/model/row_index.dart';

/// A geometria do tabuleiro em pixels, para **um** quadro: onde cada célula
/// cai na tela, dado o tamanho do board, a medida da célula e o quanto a
/// pilha já subiu.
///
/// Imutável de propósito. Quem desenha recebe um viewport novo a cada quadro
/// em vez de guardar as medidas em campos — assim nenhum método consegue ler
/// por engano a medida do quadro anterior, e a conversão célula→pixel tem um
/// dono só em vez de estar repetida em cada `* cellSize` espalhado.
class BoardViewport {
  const BoardViewport({
    required this.size,
    required this.cellSize,
    required this.riseOffset,
    required this.zoom,
  });

  /// Tamanho do board na tela, em unidades do canvas de referência.
  final Vector2 size;

  /// Lado da célula. O bloco é desenhado exatamente nesse tamanho.
  final double cellSize;

  /// Fração da linha que a pilha já subiu, de 0 a 1.
  final double riseOffset;

  /// Escala da câmera. Só serve para saber onde ficam os pixels de tela reais
  /// na hora de arredondar.
  final double zoom;

  /// Topo da linha na posição visual [row], arredondado para pixel inteiro.
  ///
  /// A pilha sobe ~0,1 pixel de tela por quadro. Em posição fracionária os
  /// traços finos não cabem num pixel exato: a amostragem ora concentra o
  /// traço em 1 pixel, ora espalha em 2, e a espessura pulsa. Arredondando,
  /// a cena anda junta de 1 em 1 pixel e cada quadro sai idêntico ao
  /// anterior — passo pequeno e lento demais para aparecer.
  double topOf(RowIndex row) {
    final top = (row.value - riseOffset) * cellSize;
    return _snap(top);
  }

  /// Borda esquerda da coluna [col].
  double leftOf(Column col) => col.value * cellSize;

  /// A célula inteira, já arredondada.
  Rect cellRect(RowIndex row, Column col) =>
      Rect.fromLTWH(leftOf(col), topOf(row), cellSize, cellSize);

  /// Altura, em linhas, contada do topo do board. Usado pela linha de perigo.
  double rowsToPixels(int rows) => rows * cellSize;

  /// Arredonda para o pixel de tela real. Sem zoom não há o que arredondar.
  double _snap(double value) =>
      zoom > 0 ? (value * zoom).roundToDouble() / zoom : value;
}
