import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/match_timings.dart';
import 'package:blocos/game/rules/gravity_system.dart';
import 'package:blocos/game/rules/match_system.dart';
import 'package:blocos/game/model/row_index.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BlockGrid emptyGrid({required int columns, required int rows}) =>
    BlockGrid(BoardGeometry(columnCount: columns, visibleRowCount: rows - 1));

void main() {
  group('MatchSystem: combo e chain', () {
    test('combinação simples: combo 3, chain 1, e volta a 0 ao assentar', () {
      final grid = emptyGrid(columns: 3, rows: 5);
      // Linha de entrada: piso inerte que sustenta a jogável.
      for (var c = 0; c < 3; c++) {
        grid.put(row(4), col(c), Block(BlockColor.purple));
        grid.put(row(3), col(c), Block(BlockColor.red));
      }
      final system = MatchSystem(grid: grid);

      system.update(0, isSettling: () => false, emit: _ignore);
      expect(system.comboSize, 3);
      expect(system.chainLevel, 1);

      _stepUntilIdle(grid, system);
      expect(system.comboSize, 0);
      expect(system.chainLevel, 0);
      for (var c = 0; c < 3; c++) {
        expect(grid.blockAt(row(3), col(c)), isNull);
      }
    });

    test('combinação de 4 em linha conta como combo 4', () {
      final grid = emptyGrid(columns: 4, rows: 5);
      for (var c = 0; c < 4; c++) {
        grid.put(row(4), col(c), Block(BlockColor.purple));
        grid.put(row(3), col(c), Block(BlockColor.red));
      }
      final system = MatchSystem(grid: grid);

      system.update(0, isSettling: () => false, emit: _ignore);
      expect(system.comboSize, 4);
      expect(system.chainLevel, 1);
    });

    test('bloco que cai de uma combinação fecha outra: chain sobe para 2', () {
      final grid = emptyGrid(columns: 4, rows: 5);
      // Piso inerte.
      for (var c = 0; c < 4; c++) {
        grid.put(row(4), col(c), Block(BlockColor.purple));
      }
      // Piso jogável: três vermelhos fecham combinação já no 1º frame.
      // Um azul fica parado na quarta coluna, e mais dois azuis esperam
      // apoiados em cima dos vermelhos — presos até o vermelho embaixo
      // deles estourar e sumir, só então caem e completam o trio.
      grid.put(row(3), col(0), Block(BlockColor.red));
      grid.put(row(3), col(1), Block(BlockColor.red));
      grid.put(row(3), col(2), Block(BlockColor.red));
      grid.put(row(3), col(3), Block(BlockColor.blue));
      grid.put(row(2), col(1), Block(BlockColor.blue));
      grid.put(row(2), col(2), Block(BlockColor.blue));

      final system = MatchSystem(grid: grid);

      final cleared = <MatchCleared>[];
      void collect(GameEvent event) {
        if (event is MatchCleared) {
          cleared.add(event);
        }
      }

      final gravity = GravitySystem(grid: grid);
      var sawChainTwo = false;
      for (var i = 0; i < 400 && system.chainLevel < 2; i++) {
        gravity.update(0.02);
        system.update(0.02, isSettling: () => gravity.isSettling, emit: collect);
        if (system.chainLevel == 2) {
          sawChainTwo = true;
          expect(system.comboSize, 3);
        }
      }
      expect(sawChainTwo, isTrue, reason: 'chain nunca chegou a 2');
      expect(
        cleared.map((e) => (e.comboSize, e.chainLevel)),
        [(3, 1), (3, 2)],
        reason: 'cada combinação emite exatamente um MatchCleared',
      );

      _stepUntilIdle(grid, system);
      expect(system.chainLevel, 0);
      expect(system.comboSize, 0);
      // Coluna 0 nunca recebeu reposição: fica vazia depois do vermelho sair.
      expect(grid.blockAt(row(3), col(0)), isNull);
    });

    test('trinca fechada à mão durante a chain vale 1 e não vira elo', () {
      // O jogador continua jogando enquanto a pilha resolve — é o que o
      // tutorial do original ensina. Mas a trinca que ele fecha num canto
      // qualquer, com blocos que ninguém derrubou, é combinação nova: ela sai
      // valendo 1 e a chain em curso segue de onde estava.
      final grid = emptyGrid(columns: 8, rows: 7);
      for (var c = 0; c < 8; c++) {
        grid.put(row(6), col(c), Block(BlockColor.purple));
      }
      // Esquerda: a chain de verdade. Os vermelhos fecham no 1º quadro, os
      // azuis caem em cima do buraco e fecham o elo com o azul da coluna 3.
      grid.put(row(5), col(0), Block(BlockColor.red));
      grid.put(row(5), col(1), Block(BlockColor.red));
      grid.put(row(5), col(2), Block(BlockColor.red));
      grid.put(row(5), col(3), Block(BlockColor.blue));
      grid.put(row(4), col(1), Block(BlockColor.blue));
      grid.put(row(4), col(2), Block(BlockColor.blue));
      // Direita: dois verdes, um amarelo e um verde. Nada cai aqui — a trinca
      // nasce da troca que o teste faz no meio da resolução.
      grid.put(row(5), col(4), Block(BlockColor.green));
      grid.put(row(5), col(5), Block(BlockColor.green));
      grid.put(row(5), col(6), Block(BlockColor.yellow));
      grid.put(row(5), col(7), Block(BlockColor.green));

      final system = MatchSystem(grid: grid);
      final gravity = GravitySystem(grid: grid);
      final cleared = <MatchCleared>[];
      void collect(GameEvent event) {
        if (event is MatchCleared) {
          cleared.add(event);
        }
      }

      // 1º quadro: só os vermelhos.
      system.update(0.02, isSettling: () => gravity.isSettling, emit: collect);
      expect(system.chainLevel, 1);
      // Agora, com a chain aberta, o jogador fecha a trinca verde à mão.
      grid.swap(grid.rowAt(row(5)), col(6), col(7));

      for (var i = 0; i < 400 && cleared.length < 3; i++) {
        gravity.update(0.02);
        system.update(0.02, isSettling: () => gravity.isSettling, emit: collect);
      }

      expect(
        cleared.map((e) => (e.comboSize, e.chainLevel)),
        [(3, 1), (3, 1), (3, 2)],
        reason: 'a trinca do meio é combinação nova; o elo seguinte é 2, não 3',
      );
    });
  });

  group('cascata do estouro', () {
    test('o popDelay sai da esquerda para a direita, de baixo para cima', () {
      // Esta ordem não tem efeito nenhum no combo nem na chain: ela só
      // escalona o atraso de cada bloco, então errá-la passa calado por
      // todos os outros testes e só aparece a olho nu, no jogo rodando.
      final grid = emptyGrid(columns: 3, rows: 6);
      for (var c = 0; c < 3; c++) {
        grid.put(row(5), col(c), Block(BlockColor.purple));
      }
      // Um L: trio horizontal no piso, mais dois verdes empilhados na
      // coluna 0 fechando o trio vertical com o canto.
      for (var c = 0; c < 3; c++) {
        grid.put(row(4), col(c), Block(BlockColor.green));
      }
      grid.put(row(3), col(0), Block(BlockColor.green));
      grid.put(row(2), col(0), Block(BlockColor.green));

      const timings = MatchTimings.standard;
      MatchSystem(grid: grid, timings: timings)
          .update(0, isSettling: () => false, emit: _ignore);

      // Esperado: coluna 0 de baixo para cima (linhas 4, 3, 2), depois as
      // colunas 1 e 2 do piso.
      final expected = <(int, int)>[(4, 0), (3, 0), (2, 0), (4, 1), (4, 2)];
      for (var i = 0; i < expected.length; i++) {
        final block = grid.blockAt(row(expected[i].$1), col(expected[i].$2));
        expect(
          block?.state,
          BlockState.matched,
          reason: 'a célula ${expected[i]} tinha que estar combinada',
        );
        expect(
          block!.popDelay,
          closeTo(i * timings.stagger, 1e-9),
          reason:
              'a célula ${expected[i]} tinha que ser a ${i + 1}ª a estourar',
        );
      }
    });
  });
}

void _stepUntilIdle(BlockGrid grid, MatchSystem system, {int maxSteps = 400}) {
  final gravity = GravitySystem(grid: grid);
  for (var i = 0; i < maxSteps; i++) {
    gravity.update(0.02);
    system.update(0.02, isSettling: () => gravity.isSettling, emit: _ignore);
    if (system.chainLevel == 0 &&
        system.comboSize == 0 &&
        !gravity.isSettling) {
      return;
    }
  }
  fail('grade não assentou depois de $maxSteps passos');
}

void _ignore(GameEvent event) {}
