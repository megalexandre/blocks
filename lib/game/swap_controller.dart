import 'block.dart';

/// Estado e regras da troca de blocos por arraste.
///
/// Não sabe nada de pixels: o tabuleiro converte o toque em (coluna, linha) e
/// chama estes métodos.
class SwapController {
  SwapController({required this.rows, required this.columns});

  /// A mesma lista de linhas do tabuleiro — a troca acontece nela.
  final List<List<BlockColor?>> rows;
  final int columns;

  /// Coluna esquerda do cursor; ele cobre duas colunas. Linha negativa
  /// enquanto o jogador ainda não tocou no tabuleiro.
  int get cursorCol => _cursorCol;
  int get cursorRow => _cursorRow;

  int _cursorCol = 0;
  int _cursorRow = -1;

  /// Linha e coluna do bloco pego, enquanto o gesto ainda pode trocar.
  int? _dragRow;
  int? _dragCol;

  /// Verdadeiro enquanto o gesto atual ainda pode gerar uma troca. Vira falso
  /// assim que a troca acontece, mesmo com o dedo ainda na tela.
  bool get isArmed => _dragRow != null;

  void beginDrag(int col, int row) {
    _dragRow = row;
    _dragCol = col;
    _cursorRow = row;
    _cursorCol = _clampCursor(col);
  }

  /// Troca o bloco pego com o vizinho no sentido de [targetCol] — uma casa, e
  /// só uma: um gesto vale uma troca. Ir mais longe com o dedo não acumula
  /// trocas; para trocar de novo é preciso soltar e tocar outra vez.
  void dragTo(int targetCol) {
    final row = _dragRow;
    final from = _dragCol;
    if (row == null || from == null) {
      return;
    }
    final target = targetCol.clamp(0, columns - 1);
    if (target == from) {
      return;
    }
    final next = target > from ? from + 1 : from - 1;
    _swap(row, from, next);
    _cursorCol = _clampCursor(from < next ? from : next);
    endDrag();
  }

  void endDrag() {
    _dragRow = null;
    _dragCol = null;
  }

  /// Uma linha saiu pelo topo: todo índice guardado andou uma linha junto.
  void onRowConsumed() {
    _cursorRow--;
    final row = _dragRow;
    if (row != null) {
      _dragRow = row - 1;
      if (row - 1 < 0) {
        endDrag();
      }
    }
  }

  void _swap(int row, int colA, int colB) {
    final held = rows[row][colA];
    rows[row][colA] = rows[row][colB];
    rows[row][colB] = held;
  }

  int _clampCursor(int col) => col.clamp(0, columns - 2);
}
