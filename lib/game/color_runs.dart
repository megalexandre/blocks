import 'model/block.dart';
import 'model/block_grid.dart';
import 'model/cell.dart';
import 'model/column.dart';
import 'model/row_index.dart';
import 'model/scan_axis.dart';

/// Sequências de mesma cor na grade — o **único** lugar do projeto que sabe
/// contar "quantos iguais em fila".
///
/// Existiam três cópias disso: o veto do carteador, o detector de combinação
/// e um auxiliar de teste. As três eram a mesma pergunta, e o que mudava era
/// só **quais blocos contam**. Por isso a única coisa que varia aqui é o
/// leitor de cor: o carteador lê a cor crua, porque está montando o tabuleiro
/// e não jogando; o detector só aceita bloco parado e apoiado.
///
/// O leitor é uma função estática, e não um closure guardado por instância:
/// duas instâncias vivem o jogo inteiro, e assim nenhuma delas carrega uma
/// alocação por construção.
class ColorRuns {
  /// Leitor cru: qualquer bloco conta. Para o veto do carteador, que precisa
  /// enxergar a pilha como ela está sendo montada.
  ColorRuns.raw(this._grid) : _colorAt = _rawColor;

  /// Leitor de jogo: só bloco parado e com apoio embaixo combina — no
  /// original combinação não fecha com bloco no ar.
  ColorRuns.matchable(this._grid) : _colorAt = _matchableColor;

  /// Quantos iguais em sequência formam uma combinação.
  ///
  /// Mora aqui, junto do conceito que os dois clientes compartilham, em vez
  /// de dentro de um deles: era uma constante da grade, lida pelo carteador
  /// *e* pelo detector, e a grade não tem nada a ver com essa regra.
  static const int matchLength = 3;

  final BlockGrid _grid;
  final BlockColor? Function(BlockGrid, RowIndex, Column) _colorAt;

  BlockColor? colorAt(RowIndex row, Column col) => _colorAt(_grid, row, col);

  /// Tamanho da sequência de [color] que passaria por (row, col) no eixo
  /// [axis]: os dois lados mais o próprio.
  ///
  /// **Não lê a célula do meio**, e é por isso que serve tanto para medir um
  /// bloco que já está lá quanto para perguntar "e se eu puser esta cor
  /// aqui?". Somar os dois lados de uma vez também é o que faz o veto pegar
  /// o bloco colocado *entre* dois iguais — checar um lado de cada vez
  /// deixaria esse caso passar.
  int through(RowIndex row, Column col, BlockColor color, ScanAxis axis) =>
      _sideRun(row, col, color, axis, -1) +
      1 +
      _sideRun(row, col, color, axis, 1);

  /// Toda célula que agora está numa sequência de [matchLength] ou mais.
  ///
  /// Uma pergunta por célula, em vez do laço de codificação por corrida que
  /// existia antes: são poucas dezenas de células e dois eixos, e o resultado
  /// é idêntico sem nenhuma variável de acumulação para errar.
  Set<Cell> matchedCells() {
    final matched = <Cell>{};
    for (final row in _grid.geometry.playableRows) {
      for (final col in _grid.geometry.columns) {
        final color = colorAt(row, col);
        if (color == null) {
          continue;
        }
        for (final axis in ScanAxis.values) {
          if (through(row, col, color, axis) >= matchLength) {
            matched.add((row: row, col: col));
            break;
          }
        }
      }
    }
    return matched;
  }

  /// Quantos blocos de [color] existem em sequência a partir de (row, col),
  /// sem contar ele próprio, andando no sentido [direction].
  ///
  /// O laço para sozinho na borda porque a grade devolve nulo fora dos
  /// limites — não há comparação de contorno a cada passo.
  int _sideRun(
    RowIndex row,
    Column col,
    BlockColor color,
    ScanAxis axis,
    int direction,
  ) {
    var total = 0;
    var steps = direction;
    while (colorAt(axis.rowFrom(row, steps), axis.colFrom(col, steps)) ==
        color) {
      total++;
      steps += direction;
    }
    return total;
  }

  static BlockColor? _rawColor(BlockGrid grid, RowIndex row, Column col) =>
      grid.blockAt(row, col)?.color;

  static BlockColor? _matchableColor(
    BlockGrid grid,
    RowIndex row,
    Column col,
  ) {
    final block = grid.blockAt(row, col);
    if (block == null || !block.isIdle) {
      return null;
    }
    return grid.blockAt(row.below, col) == null ? null : block.color;
  }
}
