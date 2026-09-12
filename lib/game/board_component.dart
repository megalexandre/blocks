import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../ui/palette.dart';
import 'block.dart';
import 'stack_raiser.dart';
import 'swap_controller.dart';

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
  final _random = math.Random();

  /// Linhas do topo (0) para baixo. A última é a que está entrando por baixo,
  /// ainda fora da área visível.
  final List<List<BlockColor?>> _rows = [];

  late final swap = SwapController(rows: _rows, columns: columns);

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
  Future<void> onLoad() async {
    _fillInitialStack();
  }

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
      _rows.removeAt(0);
      _rows.add(_randomRow());
      swap.onRowConsumed();
    }

    _fallTimer += dt;
    while (_fallTimer >= fallStepSeconds) {
      _fallTimer -= fallStepSeconds;
      _applyGravityStep();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(event.canvasPosition);
    if (cell != null) {
      swap.beginDrag(cell.col, cell.row);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // localPosition vira NaN quando o dedo sai do componente; canvas sempre vale.
    swap.dragTo(_columnAt(event.canvasEndPosition.x));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    swap.endDrag();
  }

  /// Desce em uma linha todo bloco que não tem apoio. A última linha é o piso.
  void _applyGravityStep() {
    for (var row = _rows.length - 2; row >= 0; row--) {
      for (var col = 0; col < columns; col++) {
        if (_rows[row][col] != null && _rows[row + 1][col] == null) {
          _rows[row + 1][col] = _rows[row][col];
          _rows[row][col] = null;
        }
      }
    }
  }

  ({int col, int row})? _cellAt(Vector2 canvasPoint) {
    final localX = canvasPoint.x - position.x;
    final localY = canvasPoint.y - position.y;
    if (localX < 0 || localY < 0 || localX >= size.x || localY >= size.y) {
      return null;
    }
    final row = (localY / _cellSize + _riseOffset).floor().clamp(
      0,
      _rows.length - 1,
    );
    return (col: _columnAt(canvasPoint.x), row: row);
  }

  int _columnAt(double canvasX) =>
      ((canvasX - position.x) / _cellSize).floor().clamp(0, columns - 1);

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
    _renderCursor(canvas);
    canvas.restore();

    _renderDangerLine(canvas);
  }

  void _renderCursor(Canvas canvas) {
    if (swap.cursorRow < 0 || swap.cursorRow >= _rows.length) {
      return;
    }
    final rect = Rect.fromLTWH(
      swap.cursorCol * _cellSize,
      (swap.cursorRow - _riseOffset) * _cellSize,
      _cellSize * 2,
      _cellSize,
    ).deflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(_cellSize * 0.22)),
      _cursorPaint,
    );
  }

  void _renderBlocks(Canvas canvas) {
    final gap = _cellSize * 0.1;
    final radius = Radius.circular(_cellSize * 0.18);

    for (var row = 0; row < _rows.length; row++) {
      final top = (row - _riseOffset) * _cellSize + gap / 2;
      for (var col = 0; col < columns; col++) {
        final block = _rows[row][col];
        if (block == null) {
          continue;
        }
        final rect = Rect.fromLTWH(
          col * _cellSize + gap / 2,
          top,
          _cellSize - gap,
          _cellSize - gap,
        );
        _blockPaint.color = block.color;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), _blockPaint);
      }
    }
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

  void _fillInitialStack() {
    _rows
      ..clear()
      ..addAll(
        List.generate(
          visibleRows + 1,
          (_) => List<BlockColor?>.filled(columns, null),
        ),
      );

    for (var col = 0; col < columns; col++) {
      final height = 3 + _random.nextInt(4);
      for (var i = 0; i < height; i++) {
        _rows[visibleRows - 1 - i][col] = _randomBlock();
      }
    }

    _rows[visibleRows] = _randomRow();
  }

  List<BlockColor?> _randomRow() =>
      List<BlockColor?>.generate(columns, (_) => _randomBlock());

  BlockColor _randomBlock() =>
      BlockColor.values[_random.nextInt(BlockColor.values.length)];
}
