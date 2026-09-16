import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../ui/block_look.dart';
import '../ui/palette.dart';
import 'block.dart';
import 'board_component.dart';
import 'layout.dart';
import 'score.dart';

/// Placar e indicador de chain, numa única faixa centralizada na área que o
/// [BoardComponent] reserva acima de si ([BoardComponent.topReserve]) — a
/// opção "faixa única" escolhida no canvas de direção visual.
class HudComponent extends PositionComponent {
  HudComponent({required this.board, required this.score});

  final BoardComponent board;
  final Score score;

  static const double _cardHeight = 38;
  static const double _cardPaddingH = 18;
  static const double _segmentGap = 10;
  static const double _dividerWidth = 2;

  // Combinação simples (chain 1) não é "chain" de verdade — só aparece a
  // partir de 2, quando uma queda de fato encadeou outra combinação.
  static const _minChainToShow = 2;

  static const _scoreStyle = TextStyle(
    color: Palette.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  final _cardPaint = Paint()..color = Palette.cardBackground;
  final _cardBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Palette.cardBorder;
  final _dividerPaint = Paint()..color = Palette.cardBorder;

  final _scorePainter = TextPainter(textDirection: TextDirection.ltr);
  final _chainPainter = TextPainter(textDirection: TextDirection.ltr);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(GameLayout.width, BoardComponent.topReserve);
  }

  @override
  void render(Canvas canvas) {
    _scorePainter
      ..text = TextSpan(text: _formatScore(score.total), style: _scoreStyle)
      ..layout();

    final chainLevel = board.matchResolver.chainLevel;
    final showChain = chainLevel >= _minChainToShow;
    if (showChain) {
      _chainPainter
        ..text = TextSpan(
          text: 'CHAIN ×$chainLevel',
          style: TextStyle(
            color: BlockColor.yellow.look.dark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        )
        ..layout();
    }

    final cardWidth =
        _cardPaddingH * 2 +
        _scorePainter.width +
        (showChain
            ? _segmentGap * 2 + _dividerWidth + _chainPainter.width
            : 0);
    final cardRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: cardWidth,
      height: _cardHeight,
    );
    canvas.drawRect(cardRect, _cardPaint);
    canvas.drawRect(cardRect, _cardBorderPaint);

    var x = cardRect.left + _cardPaddingH;
    _scorePainter.paint(
      canvas,
      Offset(x, cardRect.top + (_cardHeight - _scorePainter.height) / 2),
    );
    x += _scorePainter.width;

    if (showChain) {
      x += _segmentGap;
      canvas.drawRect(
        Rect.fromLTWH(x, cardRect.top + 8, _dividerWidth, _cardHeight - 16),
        _dividerPaint,
      );
      x += _dividerWidth + _segmentGap;
      _chainPainter.paint(
        canvas,
        Offset(x, cardRect.top + (_cardHeight - _chainPainter.height) / 2),
      );
    }
  }

  /// "2140" -> "2.140", como no mock aprovado.
  String _formatScore(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
