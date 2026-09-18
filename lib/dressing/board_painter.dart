import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'palette.dart';
import 'block.dart';
import '../game/block_grid.dart';
import '../game/match_resolver.dart';
import '../game/swap_controller.dart';
import 'block_sprites.dart';
import 'factory_elements.dart';
import 'selector.dart';

/// Desenha o tabuleiro: painel, blocos, animação da troca, cursor e linha de
/// perigo. Lê o estado do jogo ([grid], [swapController]) mas não o altera —
/// quem cuida de tempo, toque e geometria é o `BoardComponent`, que a cada
/// quadro entrega aqui a medida da célula e onde a pilha está.
class BoardPainter {
  BoardPainter({
    required this.grid,
    required this.swapController,
    required this.dangerRows,
    required FactoryElements elements,
  }) : _blocks = elements.blocks,
       _selector = elements.selector;

  final BlockGrid grid;
  final SwapController swapController;

  /// Linhas de folga entre o topo do tabuleiro e a linha de perigo.
  final int dangerRows;

  /// Quantas vezes o bloco combinado pisca por segundo.
  static const double flashHz = 6;

  /// Quanto apagar a linha que ainda está entrando por baixo, fora de jogo.
  /// Não é preto total: dá para planejar a próxima linha antes dela virar
  /// piso.
  static const double incomingShade = 0.55;

  final BlockSprites _blocks;
  final Selector _selector;

  final _panelPaint = Paint()..color = Palette.playfield;
  final _panelBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Palette.playfieldBorder;
  final _overlayPaint = Paint()..isAntiAlias = true;
  final _dangerPaint = Paint()
    ..color = Palette.dangerLine
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  // Medidas do quadro atual, entregues pelo board em cada render.
  late Vector2 _size;
  late double _cellSize;
  late double _riseOffset;
  late double _zoom;

  void render(
    Canvas canvas, {
    required Vector2 size,
    required double cellSize,
    required double riseOffset,
    required double zoom,
  }) {
    _size = size;
    _cellSize = cellSize;
    _riseOffset = riseOffset;
    _zoom = zoom;

    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(cellSize * 0.2),
    );
    canvas.drawRRect(panel, _panelPaint);

    canvas.save();
    canvas.clipRRect(panel);
    _renderBlocks(canvas);
    _renderSwapAnimation(canvas);
    _renderCursor(canvas);
    canvas.restore();

    canvas.drawRRect(panel, _panelBorderPaint);
    _renderDangerLine(canvas);
  }

  /// Topo da linha no índice visual [index], arredondado para pixel inteiro.
  ///
  /// A pilha sobe ~0,1 pixel de tela por frame. Em posição fracionária os
  /// traços finos não cabem num pixel exato: a amostragem ora concentra o
  /// traço em 1 pixel, ora espalha em 2, e a espessura pulsa. Arredondando,
  /// a cena anda junta de 1 em 1 pixel e cada quadro sai idêntico ao
  /// anterior — passo pequeno e lento demais para aparecer.
  double _topOf(int index) {
    final top = (index - _riseOffset) * _cellSize;
    return _zoom > 0 ? (top * _zoom).roundToDouble() / _zoom : top;
  }

  void _renderBlocks(Canvas canvas) {
    final animation = swapController.animation;
    final animatedIndex = animation != null && grid.hasRow(animation.rowId)
        ? grid.indexOf(animation.rowId)
        : null;

    for (var index = 0; index < grid.rowCount; index++) {
      for (var col = 0; col < grid.columns; col++) {
        // Os dois blocos da troca são desenhados depois, por cima de tudo.
        if (index == animatedIndex &&
            (col == animation!.grabbedCol || col == animation.displacedCol)) {
          continue;
        }
        final block = grid.atIndex(index, col);
        if (block == null) {
          continue;
        }
        final left = col * _cellSize;
        final top = _topOf(index) - block.fallOffset * _cellSize;
        final incoming = index == grid.incomingIndex;

        switch (block.state) {
          case BlockState.idle:
            _drawBlock(
              canvas,
              block.color,
              left,
              top,
              overlayColor: incoming ? Palette.playfield : null,
              overlayAlpha: incoming ? incomingShade : 0,
            );
          case BlockState.matched:
            final piscada =
                (math.sin(block.stateTime * flashHz * 2 * math.pi) + 1) / 2;
            _drawBlock(
              canvas,
              block.color,
              left,
              top,
              overlayColor: Palette.flash,
              overlayAlpha: piscada,
            );
          case BlockState.popping:
            final saindo = block.stateTime < block.popDelay
                ? 0.0
                : ((block.stateTime - block.popDelay) /
                          MatchResolver.popDuration)
                      .clamp(0.0, 1.0);
            _drawBlock(
              canvas,
              block.color,
              left,
              top,
              scale: 1 - saindo,
              fadeOut: saindo,
            );
        }
      }
    }
  }

  /// Os dois blocos giram em torno do ponto entre eles, como uma porta
  /// giratória: o escolhido vem pela frente e cresce porque está mais perto;
  /// o empurrado vai pelo fundo, encolhendo e desbotando.
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
      // Recuo contido de propósito: encolhendo e desbotando muito, o bloco
      // do fundo desaparece atrás do da frente e o cruzamento vira buraco.
      _drawBlock(
        canvas,
        displaced.color,
        _orbit(animation.grabbedCol, animation.displacedCol, sweep),
        top,
        scale: 1 - 0.14 * depth,
        overlayColor: Palette.playfield,
        overlayAlpha: 0.18 * depth,
      );
    }

    final grabbed = grid.at(animation.rowId, animation.grabbedCol);
    if (grabbed != null) {
      _drawBlock(
        canvas,
        grabbed.color,
        _orbit(animation.displacedCol, animation.grabbedCol, sweep),
        top,
        scale: 1 + 0.3 * depth,
      );
    }
  }

  double _orbit(int from, int to, double sweep) =>
      (from + (to - from) * sweep) * _cellSize;

  /// Desenha um bloco preenchendo a célula. [overlayColor] tinge por cima
  /// (piscada da combinação, linha entrando apagada, lado que perde na
  /// troca); [fadeOut] esmaece o sprite inteiro, usado no estouro junto com
  /// o encolher de [scale].
  void _drawBlock(
    Canvas canvas,
    BlockColor color,
    double left,
    double top, {
    double scale = 1,
    Color? overlayColor,
    double overlayAlpha = 0,
    double fadeOut = 0,
  }) {
    if (scale <= 0) {
      return;
    }
    final side = _cellSize * scale;
    final rect = Rect.fromLTWH(
      left + (_cellSize - side) / 2,
      top + (_cellSize - side) / 2,
      side,
      side,
    );
    _blocks.render(canvas, color, rect, opacity: 1 - fadeOut);
    if (overlayAlpha > 0 && overlayColor != null) {
      _overlayPaint.color = overlayColor.withAlpha(
        (overlayAlpha.clamp(0, 1) * 255).round(),
      );
      canvas.drawRect(rect, _overlayPaint);
    }
  }

  void _renderCursor(Canvas canvas) {
    final rowId = swapController.cursorRowId;
    if (rowId == null || !grid.hasRow(rowId)) {
      return;
    }
    _selector.render(
      canvas,
      Rect.fromLTWH(
        swapController.cursorCol * _cellSize,
        _topOf(grid.indexOf(rowId)),
        _cellSize * 2,
        _cellSize,
      ),
    );
  }

  void _renderDangerLine(Canvas canvas) {
    const dash = 10.0;
    const gap = 6.0;
    final y = dangerRows * _cellSize;
    var x = 0.0;
    while (x < _size.x) {
      final end = math.min(x + dash, _size.x);
      canvas.drawLine(Offset(x, y), Offset(end, y), _dangerPaint);
      x = end + gap;
    }
  }
}
