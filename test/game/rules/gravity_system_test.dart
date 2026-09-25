import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/rules/gravity_system.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BlockGrid emptyGrid({required int columns, required int rows}) =>
    BlockGrid(BoardGeometry(columnCount: columns, visibleRowCount: rows - 1));

void main() {
  group('GravitySystem: o passo da queda', () {
    test('cada passo de queda soma 1 ao fallOffset do bloco', () {
      final grid = emptyGrid(columns: 1, rows: 4);
      // Piso inerte (linha 3) sustenta a jogável; o bloco em 0 tem dois
      // espaços vazios abaixo antes de pousar em cima do piso.
      grid.put(row(3), col(0), Block(BlockColor.purple));
      grid.put(row(0), col(0), Block(BlockColor.red));
      final block = grid.blockAt(row(0), col(0))!;
      // dt = 0 avança o passo zero vezes; os passos vêm de `step()`, que
      // adianta exatamente um sem deixar o rastro derreter no caminho.
      //
      // Sem suspensão: o que está sendo medido aqui é o passo da queda, e a
      // pausa que vem antes dela tem teste próprio logo abaixo.
      final gravity = GravitySystem(grid: grid, hoverSeconds: 0);
      void step() => gravity.update(GravitySystem.defaultStepSeconds);

      expect(block.fallOffset, 0);

      step();
      expect(grid.blockAt(row(1), col(0)), same(block));
      expect(
        block.fallOffset,
        closeTo(0, 1e-9),
        reason: 'um passo soma 1 de rastro e derrete 1 no mesmo quadro',
      );

      step();
      expect(grid.blockAt(row(2), col(0)), same(block));

      // Piso alcançado: mais um passo não move nem soma nada.
      step();
      expect(grid.blockAt(row(2), col(0)), same(block));
    });

    test('bloco já apoiado não ganha fallOffset', () {
      final grid = emptyGrid(columns: 1, rows: 3);
      grid.put(row(2), col(0), Block(BlockColor.purple));
      grid.put(row(1), col(0), Block(BlockColor.red));
      final block = grid.blockAt(row(1), col(0))!;

      GravitySystem(grid: grid).update(GravitySystem.defaultStepSeconds);
      expect(grid.blockAt(row(1), col(0)), same(block));
      expect(block.fallOffset, 0);
    });
  });

  group('GravitySystem: a suspensão antes da queda', () {
    test('o bloco espera a suspensão inteira antes de descer a primeira linha',
        () {
      final grid = emptyGrid(columns: 1, rows: 4);
      grid.put(row(3), col(0), Block(BlockColor.purple));
      grid.put(row(0), col(0), Block(BlockColor.red));
      final block = grid.blockAt(row(0), col(0))!;

      const step = GravitySystem.defaultStepSeconds;
      const hover = GravitySystem.defaultHoverSeconds;
      final gravity = GravitySystem(grid: grid);
      final steps = (hover / step).round();

      for (var i = 0; i < steps; i++) {
        gravity.update(step);
        expect(
          grid.blockAt(row(0), col(0)),
          same(block),
          reason: 'no passo $i ele ainda tinha que estar suspenso',
        );
      }
      expect(block.isIdle, isTrue, reason: 'suspenso é parado, não é estouro');
      expect(
        block.isSettled,
        isFalse,
        reason: 'mas não assentado: é o que impede a troca de agarrá-lo',
      );

      gravity.update(step);
      expect(
        grid.blockAt(row(1), col(0)),
        same(block),
        reason: 'vencida a suspensão, ele desce no passo seguinte',
      );
    });

    test('a coluna cai inteira, com uma suspensão só e não uma por bloco', () {
      // Se cada bloco estreasse a própria suspensão ao descobrir o vão, a
      // coluna desceria em degraus — um bloco por 0,2 s.
      final grid = emptyGrid(columns: 1, rows: 6);
      grid.put(row(5), col(0), Block(BlockColor.purple));
      final top = Block(BlockColor.red);
      final middle = Block(BlockColor.green);
      final bottom = Block(BlockColor.blue);
      grid.put(row(0), col(0), top);
      grid.put(row(1), col(0), middle);
      grid.put(row(2), col(0), bottom);

      const step = GravitySystem.defaultStepSeconds;
      final gravity = GravitySystem(grid: grid);
      // A suspensão, mais as duas linhas que a coluna tem para descer.
      final steps = (GravitySystem.defaultHoverSeconds / step).round() + 2;
      for (var i = 0; i < steps; i++) {
        gravity.update(step);
      }

      expect(grid.blockAt(row(4), col(0)), same(bottom));
      expect(grid.blockAt(row(3), col(0)), same(middle));
      expect(
        grid.blockAt(row(2), col(0)),
        same(top),
        reason: 'os três desceram juntos: uma suspensão para a coluna toda',
      );
    });

    test('apoio que chega durante a suspensão cancela a queda', () {
      // O "slide this one over" do original: o bloco fica no ar tempo
      // suficiente para o jogador enfiar outro embaixo dele.
      final grid = emptyGrid(columns: 2, rows: 4);
      grid.put(row(3), col(0), Block(BlockColor.purple));
      grid.put(row(3), col(1), Block(BlockColor.purple));
      final hanging = Block(BlockColor.red);
      grid.put(row(1), col(0), hanging);
      final slider = Block(BlockColor.green);
      grid.put(row(2), col(1), slider);

      const step = GravitySystem.defaultStepSeconds;
      final gravity = GravitySystem(grid: grid);
      gravity.update(step);
      expect(hanging.hoverSteps, greaterThan(0), reason: 'está suspenso');
      expect(
        slider.isSettled,
        isTrue,
        reason: 'quem vai deslizar está apoiado e pode ser agarrado',
      );

      // O jogador desliza o apoio para baixo do bloco suspenso.
      grid.swap(grid.rowAt(row(2)), col(1), col(0));

      for (var i = 0; i < 40; i++) {
        gravity.update(step);
      }

      expect(
        grid.blockAt(row(1), col(0)),
        same(hanging),
        reason: 'ele não caiu: ganhou apoio antes de a suspensão vencer',
      );
      expect(hanging.hoverSteps, 0);
      expect(hanging.isSettled, isTrue, reason: 'e voltou a ser trocável');
    });
  });

  group('GravitySystem: o pouso', () {
    /// Uma grade de seis colunas com o desenho pintado e a linha de entrada
    /// cheia, para servir de piso.
    BlockGrid gridFrom(String drawing, {int visibleRows = 6}) {
      final grid = BlockGrid(
        BoardGeometry(columnCount: 6, visibleRowCount: visibleRows),
      );
      for (final c in grid.geometry.columns) {
        grid.put(grid.geometry.incomingRow, c, Block(BlockColor.purple));
      }
      BoardScript(drawing).paintOn(grid);
      return grid;
    }

    /// Roda a gravidade em quadros de 60 fps e junta os pousos anunciados.
    List<BlocksLanded> runLandings(GravitySystem gravity, {int frames = 60}) {
      final landed = <BlocksLanded>[];
      for (var i = 0; i < frames; i++) {
        gravity.update(1 / 60, emit: (e) {
          if (e is BlocksLanded) {
            landed.add(e);
          }
        });
      }
      return landed;
    }

    test('um bloco solto anuncia exatamente um pouso ao chegar ao chão', () {
      final grid = gridFrom('''
        R.....
        ......
        ......
        .GBYPG
      ''');

      final landed = runLandings(GravitySystem(grid: grid));

      expect(landed, hasLength(1), reason: 'cair três linhas é um pouso só');
      expect(landed.single.count, 1);
      expect(
        grid.blockAt(grid.geometry.floorRow, col(0))?.color,
        BlockColor.red,
        reason: 'e ele tem que estar mesmo no chão',
      );
    });

    test('uma fila inteira pousando junto vira um evento, com a contagem', () {
      // Seis sons iguais disparados no mesmo instante soam embolados, não
      // mais altos: quem toca o som quer um impacto só.
      final grid = gridFrom('''
        RGBYPR
        ......
        GBYPGB
      ''');

      final landed = runLandings(GravitySystem(grid: grid));

      expect(landed, hasLength(1));
      expect(landed.single.count, 6);
    });

    test('nada é anunciado enquanto o bloco ainda está no ar', () {
      // Onze linhas de queda: com 0,025 s por linha, a chegada leva bem mais
      // que os quatro quadros olhados aqui.
      final grid = gridFrom('''
        R.....
        ......
        ......
        ......
        ......
        ......
        ......
        ......
        ......
        ......
        ......
        .GBYPG
      ''', visibleRows: 12);

      expect(runLandings(GravitySystem(grid: grid), frames: 4), isEmpty);
    });

    test('bloco que nunca caiu não anuncia pouso', () {
      // Um tabuleiro parado desde o começo não tem impacto nenhum a tocar.
      final grid = gridFrom('''
        RGBYPR
        GBYPGB
      ''');

      expect(runLandings(GravitySystem(grid: grid)), isEmpty);
    });

    test('pousar sobre um bloco que ainda está caindo não é pousar', () {
      // O de cima só chega de verdade quando o de baixo chegar.
      final grid = gridFrom('''
        R.....
        B.....
        ......
        ......
        .GBYPG
      ''');

      final landed = runLandings(GravitySystem(grid: grid));

      expect(landed, hasLength(1), reason: 'a coluna chega inteira de uma vez');
      expect(landed.single.count, 2);
    });
  });
}
