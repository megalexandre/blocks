import 'package:flutter/painting.dart';

import 'palette.dart';

/// A faixa lateral que empurra a pilha para cima.
///
/// Duas setas e a palavra escrita de cima para baixo, numa coluna alta e
/// estreita: é uma área fácil de acertar sem olhar, que é o que se pede de um
/// botão usado no meio da partida.
class BoostPainter {
  static const _letterStyle = TextStyle(
    color: Palette.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
  );

  static const _label = 'SUBIR';

  final _letters = [
    for (var i = 0; i < _label.length; i++)
      TextPainter(textDirection: TextDirection.ltr),
  ];

  final _fill = Paint()..color = Palette.cardBackground;
  final _fillPressed = Paint()..color = Palette.playfieldBorder;
  final _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Palette.cardBorder;
  final _chevron = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Palette.textPrimary;

  void render(Canvas canvas, Rect area, {required bool pressed}) {
    final rounded = RRect.fromRectAndRadius(area, const Radius.circular(24));
    canvas.drawRRect(rounded, pressed ? _fillPressed : _fill);
    canvas.drawRRect(rounded, _border);

    // Duas setas no alto e duas embaixo: de onde quer que o polegar esteja na
    // coluna, há uma indicação de direção por perto.
    for (final y in [area.top + 70.0, area.top + 130.0, area.bottom - 130.0,
      area.bottom - 70.0]) {
      _drawChevron(canvas, area.center.dx, y, area.width * 0.22);
    }

    final height = _letters.length * 34.0;
    var y = area.center.dy - height / 2;
    for (var i = 0; i < _letters.length; i++) {
      _letters[i]
        ..text = TextSpan(text: _label[i], style: _letterStyle)
        ..layout();
      _letters[i].paint(
        canvas,
        Offset(area.center.dx - _letters[i].width / 2, y),
      );
      y += 34;
    }
  }

  void _drawChevron(Canvas canvas, double centerX, double y, double reach) {
    canvas.drawPath(
      Path()
        ..moveTo(centerX - reach, y + reach * 0.6)
        ..lineTo(centerX, y - reach * 0.2)
        ..lineTo(centerX + reach, y + reach * 0.6),
      _chevron,
    );
  }
}
