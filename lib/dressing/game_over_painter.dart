import 'package:flutter/painting.dart';

import 'palette.dart';

/// O painel de fim de partida, desenhado sobre o tabuleiro.
///
/// O véu escuro já existia como o único sinal de que a partida acabou; aqui
/// ele ganha o que faltava — quanto o jogador fez, e como jogar de novo.
class GameOverPainter {
  static const _titleStyle = TextStyle(
    color: Color(0xFFF6F2EC),
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: 6,
  );
  static const _scoreStyle = TextStyle(
    color: Color(0xFFF6F2EC),
    fontSize: 40,
    fontWeight: FontWeight.w700,
  );
  static const _buttonStyle = TextStyle(
    color: Palette.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
  );

  /// Medidas do botão, em unidades do canvas de referência.
  static const double buttonWidth = 460;
  static const double buttonHeight = 108;

  /// Onde o botão cai dentro de [board].
  ///
  /// Função pura e pública de propósito: é a **mesma** conta que decide onde
  /// o botão é desenhado e onde o toque é aceito. Duas contas parecidas em
  /// lugares diferentes é como um botão passa a responder fora do lugar em
  /// que aparece.
  static Rect buttonRect(Rect board) => Rect.fromCenter(
    center: Offset(board.center.dx, board.center.dy + 120),
    width: buttonWidth,
    height: buttonHeight,
  );

  final _title = TextPainter(textDirection: TextDirection.ltr);
  final _score = TextPainter(textDirection: TextDirection.ltr);
  final _button = TextPainter(textDirection: TextDirection.ltr);

  final _buttonFill = Paint()..color = Palette.cardBackground;
  final _buttonBorder = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Palette.cardBorder;

  void render(Canvas canvas, Rect board, {required int score}) {
    _title
      ..text = const TextSpan(text: 'FIM', style: _titleStyle)
      ..layout();
    _score
      ..text = TextSpan(text: '$score pontos', style: _scoreStyle)
      ..layout();

    final centerX = board.center.dx;
    _title.paint(
      canvas,
      Offset(centerX - _title.width / 2, board.center.dy - 190),
    );
    _score.paint(
      canvas,
      Offset(centerX - _score.width / 2, board.center.dy - 90),
    );

    final button = buttonRect(board);
    final rounded = RRect.fromRectAndRadius(button, const Radius.circular(18));
    canvas.drawRRect(rounded, _buttonFill);
    canvas.drawRRect(rounded, _buttonBorder);

    _button
      ..text = const TextSpan(text: 'JOGAR DE NOVO', style: _buttonStyle)
      ..layout();
    _button.paint(
      canvas,
      Offset(
        button.center.dx - _button.width / 2,
        button.center.dy - _button.height / 2,
      ),
    );
  }
}
