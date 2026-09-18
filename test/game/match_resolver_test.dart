import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/dressing/block.dart';
import 'package:blocos/game/block_grid.dart';
import 'package:blocos/game/match_resolver.dart';

void main() {
  group('MatchResolver combo e chain', () {
    test('combinação simples: combo 3, chain 1, e volta a 0 ao assentar', () {
      final grid = BlockGrid.empty(columns: 3, rowCount: 5);
      // Linha de entrada: piso inerte que sustenta a jogável.
      for (var col = 0; col < 3; col++) {
        grid.place(4, col, BlockColor.purple);
        grid.place(3, col, BlockColor.red);
      }
      final resolver = MatchResolver(grid: grid);

      resolver.update(0);
      expect(resolver.comboSize, 3);
      expect(resolver.chainLevel, 1);

      _stepUntilIdle(grid, resolver);
      expect(resolver.comboSize, 0);
      expect(resolver.chainLevel, 0);
      for (var col = 0; col < 3; col++) {
        expect(grid.atIndex(3, col), isNull);
      }
    });

    test('combinação de 4 em linha conta como combo 4', () {
      final grid = BlockGrid.empty(columns: 4, rowCount: 5);
      for (var col = 0; col < 4; col++) {
        grid.place(4, col, BlockColor.purple);
        grid.place(3, col, BlockColor.red);
      }
      final resolver = MatchResolver(grid: grid);

      resolver.update(0);
      expect(resolver.comboSize, 4);
      expect(resolver.chainLevel, 1);
    });

    test('bloco que cai de uma combinação fecha outra: chain sobe para 2', () {
      final grid = BlockGrid.empty(columns: 4, rowCount: 5);
      // Piso inerte.
      for (var col = 0; col < 4; col++) {
        grid.place(4, col, BlockColor.purple);
      }
      // Piso jogável: três vermelhos fecham combinação já no 1º frame.
      // Um azul fica parado na quarta coluna, e mais dois azuis esperam
      // apoiados em cima dos vermelhos — presos até o vermelho embaixo
      // deles estourar e sumir, só então caem e completam o trio.
      grid.place(3, 0, BlockColor.red);
      grid.place(3, 1, BlockColor.red);
      grid.place(3, 2, BlockColor.red);
      grid.place(3, 3, BlockColor.blue);
      grid.place(2, 1, BlockColor.blue);
      grid.place(2, 2, BlockColor.blue);

      final resolver = MatchResolver(grid: grid);

      final onMatchCalls = <(int, int)>[];
      resolver.onMatch = (comboSize, chainLevel) =>
          onMatchCalls.add((comboSize, chainLevel));

      var sawChainTwo = false;
      for (var i = 0; i < 400 && resolver.chainLevel < 2; i++) {
        grid.applyGravityStep();
        resolver.update(0.02);
        if (resolver.chainLevel == 2) {
          sawChainTwo = true;
          expect(resolver.comboSize, 3);
        }
      }
      expect(sawChainTwo, isTrue, reason: 'chain nunca chegou a 2');
      expect(onMatchCalls, [(3, 1), (3, 2)]);

      _stepUntilIdle(grid, resolver);
      expect(resolver.chainLevel, 0);
      expect(resolver.comboSize, 0);
      // Coluna 0 nunca recebeu reposição: fica vazia depois do vermelho sair.
      expect(grid.atIndex(3, 0), isNull);
    });
  });
}

void _stepUntilIdle(
  BlockGrid grid,
  MatchResolver resolver, {
  int maxSteps = 400,
}) {
  for (var i = 0; i < maxSteps; i++) {
    grid.applyGravityStep();
    resolver.update(0.02);
    if (resolver.chainLevel == 0 &&
        resolver.comboSize == 0 &&
        !grid.hasFallingBlocks) {
      return;
    }
  }
  fail('grade não assentou depois de $maxSteps passos');
}
