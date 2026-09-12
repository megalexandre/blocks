import 'block_grid.dart';

/// A troca que acabou de acontecer, enquanto ainda está sendo animada.
///
/// A grade já está no estado final: as colunas aqui são onde cada bloco
/// **está agora**. Quem desenha interpola de volta até de onde ele veio.
class SwapAnimation {
  SwapAnimation({
    required this.rowId,
    required this.grabbedCol,
    required this.displacedCol,
  });

  static const double duration = 0.15;

  /// Linha da troca. É um id estável, então a animação sobrevive à subida.
  final int rowId;

  /// Coluna onde o bloco escolhido está agora — ele vem para a frente.
  final int grabbedCol;

  /// Coluna onde o bloco empurrado está agora — ele vai para trás.
  final int displacedCol;

  double _elapsed = 0;

  /// 0 quando os blocos ainda estão nas posições antigas, 1 no fim.
  double get progress => (_elapsed / duration).clamp(0.0, 1.0);

  bool get isDone => _elapsed >= duration;

  void advance(double dt) => _elapsed += dt;
}

/// Estado e regras da troca de blocos por arraste.
///
/// Não sabe nada de pixels: o tabuleiro converte o toque em (coluna, rowId) e
/// chama estes métodos, e traduz o [progress] da animação em posição na tela.
class SwapController {
  SwapController({required this.grid});

  final BlockGrid grid;

  /// Coluna esquerda do cursor; ele cobre duas colunas. Linha nula enquanto o
  /// jogador ainda não tocou no tabuleiro.
  int get cursorCol => _cursorCol;
  int? get cursorRowId => _cursorRowId;

  int _cursorCol = 0;
  int? _cursorRowId;

  /// Linha e coluna do bloco pego, enquanto o gesto ainda pode trocar.
  int? _dragRowId;
  int? _dragCol;

  /// Verdadeiro enquanto o gesto atual ainda pode gerar uma troca. Vira falso
  /// assim que a troca acontece, mesmo com o dedo ainda na tela.
  bool get isArmed => _dragRowId != null;

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

  void beginDrag(int col, int rowId) {
    _dragRowId = rowId;
    _dragCol = col;
    _cursorRowId = rowId;
    _cursorCol = _clampCursor(col);
  }

  /// Troca o bloco pego com o vizinho no sentido de [targetCol] — uma casa, e
  /// só uma: um gesto vale uma troca. Ir mais longe com o dedo não acumula
  /// trocas; para trocar de novo é preciso soltar e tocar outra vez.
  void dragTo(int targetCol) {
    final rowId = _dragRowId;
    final from = _dragCol;
    if (rowId == null || from == null) {
      return;
    }
    // A linha pode ter saído pelo topo no meio do gesto.
    if (!grid.hasRow(rowId)) {
      endDrag();
      return;
    }
    final target = targetCol.clamp(0, grid.columns - 1);
    if (target == from) {
      return;
    }
    final next = target > from ? from + 1 : from - 1;
    // Bloco piscando ou estourando não se troca: ele já está em resolução.
    if (!_swappable(rowId, from) || !_swappable(rowId, next)) {
      return;
    }
    grid.swap(rowId, from, next);
    _animation = SwapAnimation(
      rowId: rowId,
      grabbedCol: next,
      displacedCol: from,
    );
    _cursorCol = _clampCursor(from < next ? from : next);
    endDrag();
  }

  void endDrag() {
    _dragRowId = null;
    _dragCol = null;
  }

  /// Célula vazia pode receber bloco; bloco só sai se estiver parado.
  bool _swappable(int rowId, int col) => grid.at(rowId, col)?.isIdle ?? true;

  int _clampCursor(int col) => col.clamp(0, grid.columns - 2);
}
