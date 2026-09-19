import 'dart:math' as math;

import '../model/block.dart';
import '../model/block_grid.dart';
import '../color_runs.dart';
import '../model/column.dart';
import '../model/row_index.dart';
import '../model/scan_axis.dart';
import 'block_dealer.dart';

/// Quem **põe** bloco na grade: a pilha de abertura e cada linha que entra
/// por baixo.
///
/// Sabe a única coisa que o carteador não pode saber — que cor não pode
/// entrar onde. Essa divisão é o que desfez o ciclo que existia entre a grade
/// e o carteador: a grade era quem criava o carteador, e o carteador guardava
/// a grade de volta só para poder vetar cor. Agora o veto mora aqui, num
/// terceiro objeto que depende dos dois e de quem nenhum dos dois depende.
class StackFiller {
  StackFiller({required this.grid, required this.dealer});

  /// Monta tudo de uma vez: a pilha de abertura e a primeira linha de
  /// entrada. É como uma partida começa.
  factory StackFiller.opening({
    required BlockGrid grid,
    required BlockDealer dealer,
  }) => StackFiller(grid: grid, dealer: dealer)
    ..dealOpeningStack()
    ..fillIncomingRow();

  /// Pública como nos outros sistemas do jogo: quem monta a partida já tem a
  /// grade na mão, e escondê-la aqui não esconderia nada.
  final BlockGrid grid;
  final BlockDealer dealer;

  /// O veto lê a grade crua: está montando a pilha, não jogando, então conta
  /// qualquer bloco já posto — inclusive o da linha que ainda vai entrar.
  late final ColorRuns _runs = ColorRuns.raw(grid);

  /// Pilha de abertura: cada coluna recebe uma altura sorteada, para o
  /// tabuleiro não começar com o topo reto.
  void dealOpeningStack() {
    final geometry = grid.geometry;
    final heights = dealer.startHeights(geometry.columnCount);
    final tallest = heights.reduce(math.max);
    // Camada por camada, a partir do piso: assim o veto enxerga os vizinhos
    // de baixo e da esquerda já postos, e consegue recusar a cor deles.
    for (var layer = 0; layer < tallest; layer++) {
      final row = geometry.floorRow.shifted(-layer);
      for (final col in geometry.columns) {
        if (layer < heights[col.value]) {
          grid.put(row, col, Block(_colorFor(row, col)));
        }
      }
    }
  }

  /// Enche a linha que está entrando por baixo. Chamada uma vez na abertura e
  /// uma vez a cada subida da pilha.
  void fillIncomingRow() {
    final row = grid.geometry.incomingRow;
    for (final col in grid.geometry.columns) {
      grid.put(row, col, Block(_colorFor(row, col)));
    }
  }

  /// Sorteia uma cor que não feche uma combinação de saída. Sem isso o
  /// tabuleiro estouraria sozinho no primeiro frame, e cada linha nova
  /// entraria já estourando.
  ///
  /// Depende de a grade ser preenchida em ordem — os vizinhos que já estão
  /// postos são os que vetam cor. Preencher fora de ordem não quebra nada,
  /// só deixa passar combinação que este veto teria evitado.
  BlockColor _colorFor(RowIndex row, Column col) {
    final allowed = BlockColor.values
        .where(
          (color) => ScanAxis.values.every(
            (axis) =>
                _runs.through(row, col, color, axis) < ColorRuns.matchLength,
          ),
        )
        .toList();
    // Cada eixo bloqueia no máximo duas cores, então com cinco sempre sobra
    // alguma. Cortar o enum para quatro põe este assert em risco.
    assert(
      allowed.isNotEmpty,
      'nenhuma cor livre em (${row.value}, ${col.value})',
    );
    return dealer.pickColor(allowed);
  }
}
