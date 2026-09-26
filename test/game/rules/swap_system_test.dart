import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/debug/scenario_catalog.dart';
import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';
import 'package:blocos/game/playfield.dart';
import 'package:blocos/game/rules/swap_system.dart';

/// Uma linha de seis cores distintas, para dar para seguir cada bloco.
const _cores = [
  BlockColor.red,
  BlockColor.green,
  BlockColor.blue,
  BlockColor.yellow,
  BlockColor.cyan,
  BlockColor.purple,
];

BlockGrid _grid() {
  final grid = BlockGrid(
    BoardGeometry(columnCount: 6, visibleRowCount: 2),
  );
  for (var c = 0; c < 6; c++) {
    grid.put(const RowIndex(1), Column(c), Block(_cores[c]));
  }
  return grid;
}

List<BlockColor?> _linha(BlockGrid grid) => [
      for (var c = 0; c < 6; c++)
        grid.blockAt(const RowIndex(1), Column(c))?.color,
    ];

/// Pega o bloco de [from] e arrasta até [to], como o dedo faria: o componente
/// chama `dragTo` a cada movimento, sempre com a coluna de destino.
void _arrasta(SwapSystem swaps, BlockGrid grid, int from, int to) {
  swaps.beginDrag(Column(from), grid.rowAt(const RowIndex(1)));
  for (var i = 0; i < 10; i++) {
    swaps.dragTo(Column(to));
  }
  swaps.endDrag();
}

void main() {
  group('SwapSystem: um gesto vale uma troca', () {
    test('arrastar até a outra ponta move uma casa só', () {
      final grid = _grid();
      _arrasta(SwapSystem(grid: grid), grid, 0, 5);

      expect(_linha(grid), [
        BlockColor.green,
        BlockColor.red,
        BlockColor.blue,
        BlockColor.yellow,
        BlockColor.cyan,
        BlockColor.purple,
      ]);
    });

    test('o gesto se desarma depois da troca', () {
      final grid = _grid();
      final swaps = SwapSystem(grid: grid)
        ..beginDrag(const Column(0), grid.rowAt(const RowIndex(1)));
      expect(swaps.isArmed, isTrue);
      swaps.dragTo(const Column(1));
      expect(swaps.isArmed, isFalse);
    });
  });

  group('SwapSystem: o arraste contínuo do modo de desenvolvimento', () {
    test('o bloco pego atravessa a linha e os outros recuam uma casa', () {
      final grid = _grid();
      _arrasta(SwapSystem(grid: grid)..continuousDrag = true, grid, 0, 5);

      // Rotação, e não troca: é essa a diferença que faz disto uma regra
      // separada em vez de um ajuste de conforto.
      expect(_linha(grid), [
        BlockColor.green,
        BlockColor.blue,
        BlockColor.yellow,
        BlockColor.cyan,
        BlockColor.purple,
        BlockColor.red,
      ]);
    });

    test('volta pelo mesmo caminho e desfaz a rotação', () {
      final grid = _grid();
      final swaps = SwapSystem(grid: grid)..continuousDrag = true;
      _arrasta(swaps, grid, 0, 5);
      _arrasta(swaps, grid, 5, 0);
      expect(_linha(grid), _cores);
    });

    test('para no bloco que não se troca, sem desarmar o gesto', () {
      final grid = _grid();
      // Um bloco no meio do rastro de queda não é trocável.
      grid.blockAt(const RowIndex(1), const Column(3))!.fallOffset = 0.5;

      _arrasta(SwapSystem(grid: grid)..continuousDrag = true, grid, 0, 5);

      // O vermelho andou até encostar no amarelo e parou ali.
      expect(_linha(grid), [
        BlockColor.green,
        BlockColor.blue,
        BlockColor.red,
        BlockColor.yellow,
        BlockColor.cyan,
        BlockColor.purple,
      ]);
    });
  });

  group('o jogo não vê nada disso', () {
    test('uma partida normal nasce com o arraste contínuo desligado', () {
      expect(Playfield.standard().continuousDrag, isFalse);
    });

    test('só o cenário que pede liga', () {
      final ligados = scenarioCatalog
          .where((s) => s.build().continuousDrag)
          .map((s) => s.name);
      expect(ligados, ['Arrastar a linha inteira']);
    });
  });
}
