import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/board_script.dart';
import 'package:blocos/game/model/block.dart';
import 'package:blocos/game/model/block_grid.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BlockGrid gridOf({int columns = 6, int visibleRows = 4}) =>
    BlockGrid(BoardGeometry(columnCount: columns, visibleRowCount: visibleRows));

void main() {
  group('paintOn', () {
    test('o desenho é ancorado no piso, e o que falta em cima fica vazio', () {
      // É a regra que deixa um cenário curto caber em duas linhas: quase todo
      // cenário interessante mora perto do chão.
      final grid = gridOf();
      const BoardScript('''
        .BB...
        RRRB..
      ''').paintOn(grid);

      final floor = grid.geometry.floorRow;
      expect(grid.blockAt(floor, col(0))?.color, BlockColor.red);
      expect(grid.blockAt(floor, col(2))?.color, BlockColor.red);
      expect(grid.blockAt(floor, col(3))?.color, BlockColor.blue);
      expect(grid.blockAt(floor, col(4)), isNull);

      expect(grid.blockAt(floor.above, col(1))?.color, BlockColor.blue);
      expect(grid.blockAt(floor.above, col(0)), isNull);

      expect(
        grid.blockAt(grid.geometry.topRow, col(0)),
        isNull,
        reason: 'as linhas que o desenho não alcança têm que ficar vazias',
      );
    });

    test('substitui o que havia: ponto apaga célula ocupada', () {
      final grid = gridOf();
      const BoardScript('RRRRRR').paintOn(grid);
      expect(grid.blockAt(grid.geometry.floorRow, col(0)), isNotNull);

      const BoardScript('..R...').paintOn(grid);

      final floor = grid.geometry.floorRow;
      expect(grid.blockAt(floor, col(0)), isNull);
      expect(grid.blockAt(floor, col(2))?.color, BlockColor.red);
    });

    test('não toca na linha de entrada, que é o piso da pilha', () {
      // Um cenário que apagasse a linha de entrada faria o tabuleiro inteiro
      // desabar no primeiro quadro.
      final grid = gridOf();
      final incoming = grid.geometry.incomingRow;
      for (final c in grid.geometry.columns) {
        grid.put(incoming, c, Block(BlockColor.purple));
      }

      const BoardScript('RRR...').paintOn(grid);

      for (final c in grid.geometry.columns) {
        expect(grid.blockAt(incoming, c)?.color, BlockColor.purple);
      }
    });

    test('recuo e linhas em branco não contam', () {
      // Para um script escrito com aspas triplas dentro de uma classe não
      // precisar ser colado na margem.
      final grid = gridOf();
      const BoardScript('''

            RRR...

      ''').paintOn(grid);

      expect(
        grid.blockAt(grid.geometry.floorRow, col(0))?.color,
        BlockColor.red,
      );
    });
  });

  group('erros de escrita falham alto', () {
    test('linha com largura errada diz qual linha e quantas células', () {
      expect(
        () => const BoardScript('RRR').paintOn(gridOf()),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'mensagem',
            allOf(contains('"RRR"'), contains('3'), contains('6')),
          ),
        ),
      );
    });

    test('desenho mais alto que o tabuleiro é recusado', () {
      final tall = List.filled(5, '......').join('\n');
      expect(
        () => BoardScript(tall).paintOn(gridOf(visibleRows: 4)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('letra que não é cor diz quais são as válidas', () {
      expect(
        () => const BoardScript('XXX...').paintOn(gridOf()),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'mensagem',
            allOf(contains('"X"'), contains('R')),
          ),
        ),
      );
    });
  });

  test('toda cor tem letra, nos dois sentidos', () {
    // `describe` procura a letra da cor e estoura se não achar. Uma cor nova
    // sem letra quebraria a leitura de volta na primeira vez que ela caísse
    // no tabuleiro — longe daqui, e sem dizer o porquê.
    for (final color in BlockColor.values) {
      final letter = BoardScript.letterOf(color);
      expect(letter, hasLength(1));

      final grid = gridOf(columns: 1, visibleRows: 1);
      BoardScript(letter).paintOn(grid);
      expect(grid.blockAt(grid.geometry.floorRow, col(0))?.color, color);
    }
  });

  group('describe', () {
    test('ler de volta devolve o mesmo desenho', () {
      // O formato precisa dos dois sentidos: é o que permite um editor
      // exportar o que foi desenhado na tela.
      final grid = gridOf(visibleRows: 3);
      const desenho = '......\n.BB.YY\nRRRBGP';
      const BoardScript(desenho).paintOn(grid);

      expect(BoardScript.describe(grid), desenho);
    });

    test('grade vazia vira um desenho só de pontos', () {
      final grid = gridOf(visibleRows: 2);
      expect(BoardScript.describe(grid), '......\n......');
    });
  });
}
