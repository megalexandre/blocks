import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../ui/palette.dart';
import 'block.dart';
import 'block_grid.dart';
import 'stack_raiser.dart';
import 'swap_controller.dart';

/// O tabuleiro na tela: tempo, geometria, toque e pintura. O estado dos blocos
/// é do [BlockGrid]; as regras de troca são do [SwapController].
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
          _drawBlock(canvas, block, col * _cellSize, _topOf(index));
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
        displaced,
        _orbit(animation.grabbedCol, animation.displacedCol, sweep),
        top,
        // Recuo contido de propósito: encolhendo e desbotando muito, o bloco
        // do fundo desaparece atrás do da frente e o cruzamento vira buraco.
        scale: 1 - 0.14 * depth,
        recede: 0.18 * depth,
      );
    }

    final grabbed = grid.at(animation.rowId, animation.grabbedCol);
    if (grabbed != null) {
      _drawBlock(
        canvas,
        grabbed,
        _orbit(animation.displacedCol, animation.grabbedCol, sweep),
        top,
        scale: 1 + 0.3 * depth,
      );
    }
  }

  double _orbit(int from, int to, double sweep) =>
      (from + (to - from) * sweep) * _cellSize;

  /// Desenha o bloco centralizado na célula, com [scale] servindo de
  /// perspectiva: maior quando está mais perto do jogador.
  void _drawBlock(
    Canvas canvas,
    BlockColor block,
    double left,
    double top, {
    double scale = 1,
    double recede = 0,
  }) {
    final side = _cellSize * 0.9 * scale;
    final rect = Rect.fromLTWH(
      left + (_cellSize - side) / 2,
      top + (_cellSize - side) / 2,
      side,
      side,
    );
    _blockPaint.color = recede > 0
        ? Color.lerp(block.color, Palette.playfield, recede)!
        : block.color;
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
