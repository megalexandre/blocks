import '../model/block_grid.dart';
import '../model/board_row.dart';
import '../model/column.dart';
import 'swap_animation.dart';

/// Estado e regras da troca de blocos por arraste.
///
/// Não sabe nada de pixels: o tabuleiro converte o toque em (coluna, linha) e
/// chama estes métodos, e traduz o [progress] da animação em posição na tela.
class SwapSystem {
  SwapSystem({required this.grid});

  final BlockGrid grid;

  /// Um gesto pode trocar mais de uma vez, carregando o bloco pego pela linha.
  ///
  /// **Desligado no jogo.** É controle de desenvolvimento, ligado só pelos
  /// cenários do `main_dev.dart` — do mesmo jeito que `risePaused` segura a
  /// pilha de fora. Serve para arrastar um bloco de ponta a ponta e olhar a
  /// linha se reorganizando, sem soltar e tocar seis vezes.
  ///
  /// Ligado, muda o jogo de verdade: arrastar passa a ser uma rotação da
  /// linha, e não uma troca. É por isso que não é padrão.
  bool continuousDrag = false;

  /// Coluna esquerda do cursor; ele cobre duas colunas. Linha nula enquanto o
  /// jogador ainda não tocou no tabuleiro.
  Column get cursorColumn => _cursorColumn;
  BoardRow? get cursorRow => _cursorRow;

  Column _cursorColumn = const Column(0);
  BoardRow? _cursorRow;

  /// Linha e coluna do bloco pego, enquanto o gesto ainda pode trocar.
  BoardRow? _dragRow;
  Column? _dragColumn;

  /// Verdadeiro enquanto o gesto atual ainda pode gerar uma troca. Vira falso
  /// assim que a troca acontece, mesmo com o dedo ainda na tela.
  bool get isArmed => _dragRow != null;

  /// A troca em andamento, ou nulo quando não há nada animando.
  SwapAnimation? get animation => _animation;

  SwapAnimation? _animation;

  void update(double dt) {
    final animation = _animation;
    if (animation == null) {
      return;
    }
    animation.advance(dt);
    if (animation.isDone) {
      _animation = null;
    }
  }

  void beginDrag(Column col, BoardRow row) {
    _dragRow = row;
    _dragColumn = col;
    _cursorRow = row;
    _cursorColumn = _clampCursor(col);
  }

  /// Troca o bloco pego com o vizinho no sentido de [targetColumn] — uma casa
  /// por chamada.
  ///
  /// Com [continuousDrag] desligado, que é o padrão do jogo, **um gesto vale
  /// uma troca**: ir mais longe com o dedo não acumula, e para trocar de novo
  /// é preciso soltar e tocar outra vez.
  ///
  /// Ligado, o gesto continua armado e o bloco pego segue com o dedo, uma casa
  /// a cada chamada. Uma casa por chamada, e não um salto até o alvo, porque o
  /// desenho da troca só sabe animar um par vizinho — e o dedo gera dezenas de
  /// chamadas por segundo, então atravessar a linha leva alguns quadros e sai
  /// contínuo de qualquer jeito.
  void dragTo(Column targetColumn) {
    final row = _dragRow;
    final from = _dragColumn;
    if (row == null || from == null) {
      return;
    }
    // A linha pode ter saído pelo topo no meio do gesto.
    if (!grid.contains(row)) {
      endDrag();
      return;
    }
    final target = grid.geometry.clampColumn(targetColumn.value);
    if (target == from) {
      return;
    }
    final next = from.towards(target);
    // Bloco em resolução ou ainda no ar não se troca.
    if (!grid.canSwap(row, from, next)) {
      return;
    }
    grid.swap(row, from, next);
    _animation = SwapAnimation(
      row: row,
      grabbedColumn: next,
      displacedColumn: from,
    );
    _cursorColumn = _clampCursor(from < next ? from : next);
    if (continuousDrag) {
      // O bloco pego é o mesmo; o que mudou foi onde ele está agora.
      _dragColumn = next;
    } else {
      endDrag();
    }
  }

  void endDrag() {
    _dragRow = null;
    _dragColumn = null;
  }

  /// O cursor cobre duas colunas, então a esquerda dele nunca pode ser a
  /// última do tabuleiro.
  Column _clampCursor(Column col) =>
      Column(col.value.clamp(0, grid.geometry.columnCount - 2));
}
