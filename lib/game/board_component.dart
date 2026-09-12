import 'dart:math' as math;
import 'dart:ui';

// O Flame também exporta um Block, sem relação com o nosso.
import 'package:flame/components.dart' hide Block;
import 'package:flame/events.dart';

import '../ui/palette.dart';
import 'block.dart';
import 'block_grid.dart';
import 'match_resolver.dart';
import 'stack_raiser.dart';
import 'swap_controller.dart';

/// O tabuleiro na tela: tempo, geometria, toque e pintura. O estado dos blocos
/// é do [BlockGrid], as regras de troca são do [SwapController] e as
/// combinações são do [MatchResolver].
class BoardComponent extends PositionComponent with DragCallbacks {
  BoardComponent({required this.stackRaiser});

  static const int columns = 6;
  static const int visibleRows = 12;

  /// Linhas de folga entre o topo do tabuleiro e a linha de perigo.
  static const int dangerRows = 2;

  /// Faixa reservada no topo para o HUD de placar/chain de uma etapa futura.
  static const double topReserve = 56;
  static const double sidePadding = 16;

  /// Um bloco sem apoio desce uma linha a cada passo.
  static const double fallStepSeconds = 0.035;

  final StackRaiser stackRaiser;

  /// A linha extra é a que está entrando por baixo, fora da área visível.
  final grid = BlockGrid(columns: columns, rowCount: visibleRows + 1);

  late final swapController = SwapController(grid: grid);
  late final matchResolver = MatchResolver(grid: grid);

  /// Quantas vezes o bloco combinado pisca por segundo.
  static const double flashHz = 6;

  double _riseOffset = 0;
  double _cellSize = 24;
  double _fallTimer = 0;

  final _panelPaint = Paint()..color = Palette.playfield;
  final _blockPaint = Paint();
  final _dangerPaint = Paint()
    ..color = Palette.dangerLine
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final _cursorPaint = Paint()
    ..color = Palette.cursor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final availableWidth = size.x - sidePadding * 2;
    final availableHeight = size.y - topReserve - sidePadding;
    _cellSize = math.max(
      4,
      math.min(availableWidth / columns, availableHeight / visibleRows),
    );
    this.size = Vector2(columns * _cellSize, visibleRows * _cellSize);
    position = Vector2((size.x - this.size.x) / 2, topReserve);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _riseOffset += stackRaiser.rowsPerSecond * dt;
    while (_riseOffset >= 1) {
      _riseOffset -= 1;
      grid.shiftUp();
    }

    _fallTimer += dt;
    while (_fallTimer >= fallStepSeconds) {
      _fallTimer -= fallStepSeconds;
      grid.applyGravityStep();
    }

    matchResolver.update(dt);
    swapController.update(dt);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(event.canvasPosition);
    if (cell != null) {
      swapController.beginDrag(cell.col, cell.rowId);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // localPosition vira NaN quando o dedo sai do componente; canvas sempre vale.
    swapController.dragTo(_columnAt(event.canvasEndPosition.x));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    swapController.endDrag();
  }

  ({int col, int rowId})? _cellAt(Vector2 canvasPoint) {
    final localX = canvasPoint.x - position.x;
    final localY = canvasPoint.y - position.y;
    if (localX < 0 || localY < 0 || localX >= size.x || localY >= size.y) {
      return null;
    }
    final index = (localY / _cellSize + _riseOffset).floor().clamp(
      0,
      grid.rowCount - 1,
    );
    return (col: _columnAt(canvasPoint.x), rowId: grid.rowIdAt(index));
  }

  int _columnAt(double canvasX) =>
      ((canvasX - position.x) / _cellSize).floor().clamp(0, columns - 1);

  /// Topo da linha que está no índice visual [index].
  double _topOf(int index) => (index - _riseOffset) * _cellSize;

  @override
  void render(Canvas canvas) {
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(_cellSize * 0.2),
    );
    canvas.drawRRect(panel, _panelPaint);

    canvas.save();
    canvas.clipRRect(panel);
    _renderBlocks(canvas);
    _renderSwapAnimation(canvas);
    _renderCursor(canvas);
    canvas.restore();

    _renderDangerLine(canvas);
  }

  void _renderBlocks(Canvas canvas) {
    final animation = swapController.animation;
    final animatedIndex = animation != null && grid.hasRow(animation.rowId)
        ? grid.indexOf(animation.rowId)
        : null;

    for (var index = 0; index < grid.rowCount; index++) {
      for (var col = 0; col < columns; col++) {
        // Os dois blocos da troca são desenhados depois, por cima de tudo.
        if (index == animatedIndex &&
            (col == animation!.grabbedCol || col == animation.displacedCol)) {
          continue;
        }
        final block = grid.atIndex(index, col);
        if (block != null) {
          final look = _lookOf(block);
          _drawBlock(
            canvas,
            look.color,
            col * _cellSize,
            _topOf(index),
            scale: look.scale,
          );
        }
      }
    }
  }

  /// Os dois blocos giram em torno do ponto entre eles, como uma porta
  /// giratória: o escolhido vem pela frente, e cresce porque está mais perto;
  /// o empurrado vai pelo fundo, encolhendo e desbotando. Eles se cruzam
  /// trocando de lado.
  ///
  /// No cruzamento os dois ficam no centro do vão e as bordas aparecem por um
  /// instante. Isso é geométrico: quem troca de lado tem que se cruzar. O que
  /// disfarça é o bloco da frente estar aumentado, cobrindo mais.
  void _renderSwapAnimation(Canvas canvas) {
    final animation = swapController.animation;
    if (animation == null || !grid.hasRow(animation.rowId)) {
      return;
    }
    final top = _topOf(grid.indexOf(animation.rowId));

    // Órbita: o x é a projeção do giro e o depth é o quanto saiu do plano.
    final sweep = (1 - math.cos(math.pi * animation.progress)) / 2;
    final depth = math.sin(math.pi * animation.progress);

    // O do fundo primeiro, para o da frente passar por cima dele.
    final displaced = grid.at(animation.rowId, animation.displacedCol);
    if (displaced != null) {
      _drawBlock(
        canvas,
        // Recuo contido de propósito: encolhendo e desbotando muito, o bloco
        // do fundo desaparece atrás do da frente e o cruzamento vira buraco.
        Color.lerp(displaced.color.color, Palette.playfield, 0.18 * depth)!,
        _orbit(animation.grabbedCol, animation.displacedCol, sweep),
        top,
        scale: 1 - 0.14 * depth,
      );
    }

    final grabbed = grid.at(animation.rowId, animation.grabbedCol);
    if (grabbed != null) {
      _drawBlock(
        canvas,
        grabbed.color.color,
        _orbit(animation.displacedCol, animation.grabbedCol, sweep),
        top,
        scale: 1 + 0.3 * depth,
      );
    }
  }

  /// Como o bloco aparece, conforme o estado: parado mostra a própria cor,
  /// combinado pisca no branco, e estourando encolhe até sair.
  ({Color color, double scale}) _lookOf(Block block) {
    switch (block.state) {
      case BlockState.idle:
        return (color: block.color.color, scale: 1.0);
      case BlockState.matched:
        final piscada =
            (math.sin(block.stateTime * flashHz * 2 * math.pi) + 1) / 2;
        return (
          color: Color.lerp(block.color.color, Palette.flash, piscada)!,
          scale: 1.0,
        );
      case BlockState.popping:
        if (block.stateTime < block.popDelay) {
          return (color: Palette.flash, scale: 1.0);
        }
        final saindo =
            ((block.stateTime - block.popDelay) / MatchResolver.popDuration)
                .clamp(0.0, 1.0);
        return (color: Palette.flash, scale: 1 - saindo);
    }
  }

  double _orbit(int from, int to, double sweep) =>
      (from + (to - from) * sweep) * _cellSize;

  /// Desenha um bloco centralizado na célula. Quem chama decide a cor e a
  /// escala — na animação de troca a escala é perspectiva, no estouro é o
  /// bloco encolhendo.
  void _drawBlock(
    Canvas canvas,
    Color color,
    double left,
    double top, {
    double scale = 1,
  }) {
    if (scale <= 0) {
      return;
    }
    final side = _cellSize * 0.9 * scale;
    final rect = Rect.fromLTWH(
      left + (_cellSize - side) / 2,
      top + (_cellSize - side) / 2,
      side,
      side,
    );
    _blockPaint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(_cellSize * 0.18)),
      _blockPaint,
    );
  }

  void _renderCursor(Canvas canvas) {
    final rowId = swapController.cursorRowId;
    if (rowId == null || !grid.hasRow(rowId)) {
      return;
    }
    final rect = Rect.fromLTWH(
      swapController.cursorCol * _cellSize,
      _topOf(grid.indexOf(rowId)),
      _cellSize * 2,
      _cellSize,
    ).deflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(_cellSize * 0.22)),
      _cursorPaint,
    );
  }

  void _renderDangerLine(Canvas canvas) {
    const dash = 10.0;
    const gap = 6.0;
    final y = dangerRows * _cellSize;
    var x = 0.0;
    while (x < size.x) {
      final end = math.min(x + dash, size.x);
      canvas.drawLine(Offset(x, y), Offset(end, y), _dangerPaint);
      x = end + gap;
    }
  }
}
