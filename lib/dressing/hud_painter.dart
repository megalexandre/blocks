import 'package:flutter/painting.dart';

import 'palette.dart';

/// O placar, na faixa acima do tabuleiro.
///
/// Só desenha: recebe os números prontos e não pergunta nada ao jogo. Quem
/// lê o jogo é o componente da cena, uma vez por quadro.
class HudPainter {
  /// A partir de quantos níveis a chain aparece.
  ///
  /// Uma combinação simples é chain 1, e anunciar isso seria anunciar toda
  /// jogada. Chain só é notícia a partir de 2, quando uma queda de fato
  /// encadeou outra combinação. A regra vem do HUD antigo e sobreviveu a ele.
  static const int minChainToShow = 2;

  static const _scoreStyle = TextStyle(
    color: Palette.textPrimary,
    fontSize: 44,
    fontWeight: FontWeight.w800,
  );
  static const _labelStyle = TextStyle(
    color: Palette.textSecondary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );
  static const _chainStyle = TextStyle(
    color: Palette.chain,
    fontSize: 30,
    fontWeight: FontWeight.w800,
  );

  final _score = TextPainter(textDirection: TextDirection.ltr);
  final _label = TextPainter(textDirection: TextDirection.ltr);
  final _chain = TextPainter(textDirection: TextDirection.ltr);

  /// Desenha dentro de [band] — a faixa livre acima do tabuleiro, em
  /// coordenadas locais de quem chama.
  void render(
    Canvas canvas,
    Rect band, {
    required int score,
    required int chainLevel,
  }) {
    _label
      ..text = const TextSpan(text: 'PONTOS', style: _labelStyle)
      ..layout();
    _score
      ..text = TextSpan(text: _format(score), style: _scoreStyle)
      ..layout();

    final centerX = band.center.dx;
    final blockHeight = _label.height + 4 + _score.height;
    final top = band.center.dy - blockHeight / 2;

    _label.paint(canvas, Offset(centerX - _label.width / 2, top));
    _score.paint(
      canvas,
      Offset(centerX - _score.width / 2, top + _label.height + 4),
    );

    if (chainLevel < minChainToShow) {
      return;
    }
    _chain
      ..text = TextSpan(text: 'CHAIN ×$chainLevel', style: _chainStyle)
      ..layout();
    _chain.paint(
      canvas,
      Offset(band.right - _chain.width - 24, band.center.dy - _chain.height / 2),
    );
  }

  /// Separa os milhares com ponto: 12400 vira 12.400.
  static String _format(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        out.write('.');
      }
      out.write(digits[i]);
    }
    return out.toString();
  }
}
