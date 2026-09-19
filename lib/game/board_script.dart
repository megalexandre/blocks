import 'model/block.dart';
import 'model/block_grid.dart';

/// Um tabuleiro escrito como desenho: uma linha de texto por linha da grade,
/// um caractere por célula.
///
/// ```
/// ......
/// .BB...
/// RRRB..
/// ```
///
/// `.` é célula vazia e as letras são a inicial da cor em inglês, como o
/// [BlockColor] as nomeia. O desenho é **ancorado no piso**: a última linha
/// do texto é a linha do piso, e o que faltar em cima fica vazio. É assim
/// para um cenário curto poder ser escrito em três linhas em vez de treze,
/// já que quase todo cenário interessante mora perto do chão.
///
/// Não é código de depuração: é como um tabuleiro se escreve. Serve ao
/// catálogo de cenários, serve a um teste que queira montar uma situação
/// exata, e serviria a qualquer coisa futura que precise de tabuleiro fixo.
class BoardScript {
  const BoardScript(this.text);

  final String text;

  /// A letra de cada cor. Primeira letra do nome em inglês — as cinco são
  /// distintas, então não há ambiguidade a resolver.
  static const Map<String, BlockColor> _byLetter = {
    'R': BlockColor.red,
    'B': BlockColor.blue,
    'G': BlockColor.green,
    'Y': BlockColor.yellow,
    'P': BlockColor.purple,
  };

  static const String empty = '.';

  /// As linhas do desenho, sem as vazias das pontas e sem recuo — assim um
  /// script escrito com `'''` indentado dentro de uma classe funciona sem
  /// exigir que quem escreve cole tudo na margem.
  List<String> get lines => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  /// Põe o desenho na grade, **substituindo** o que havia nas linhas
  /// jogáveis.
  ///
  /// A linha de entrada não é tocada: ela é o piso inerte que sustenta a
  /// pilha, e quem a reparte é o `StackFiller`. Um cenário que a apagasse
  /// deixaria o tabuleiro inteiro cair no primeiro quadro.
  void paintOn(BlockGrid grid) {
    final geometry = grid.geometry;
    final drawing = lines;

    if (drawing.length > geometry.visibleRowCount) {
      throw ArgumentError(
        'o desenho tem ${drawing.length} linhas e o tabuleiro só mostra '
        '${geometry.visibleRowCount}',
      );
    }
    for (final line in drawing) {
      if (line.length != geometry.columnCount) {
        throw ArgumentError(
          'a linha "$line" tem ${line.length} células e o tabuleiro tem '
          '${geometry.columnCount} colunas',
        );
      }
    }

    for (final row in geometry.playableRows) {
      for (final col in geometry.columns) {
        grid.clear(row, col);
      }
    }

    // Ancorado no piso: a última linha do desenho cai na linha do piso.
    for (var i = 0; i < drawing.length; i++) {
      final row = geometry.floorRow.shifted(-(drawing.length - 1 - i));
      for (final col in geometry.columns) {
        final letter = drawing[i][col.value].toUpperCase();
        if (letter == empty) {
          continue;
        }
        final color = _byLetter[letter];
        if (color == null) {
          throw ArgumentError(
            'caractere "$letter" não é uma cor; use '
            '${_byLetter.keys.join(", ")} ou "$empty" para vazio',
          );
        }
        grid.put(row, col, Block(color));
      }
    }
  }

  /// O caminho de volta: lê a grade e devolve o desenho dela.
  ///
  /// Existe para o formato não nascer de mão única — é o que permite testar
  /// ida e volta, e é a peça que um editor de fases usaria para exportar o
  /// que foi desenhado na tela. Descreve só as linhas jogáveis, pelo mesmo
  /// motivo que [paintOn] não escreve na linha de entrada.
  static String describe(BlockGrid grid) {
    final buffer = StringBuffer();
    for (final row in grid.geometry.playableRows) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        buffer.write(block == null ? empty : letterOf(block.color));
      }
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  static String letterOf(BlockColor color) =>
      _byLetter.entries.firstWhere((entry) => entry.value == color).key;
}
