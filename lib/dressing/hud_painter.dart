import 'dart:ui';

import 'bitmap_text.dart';
import 'chain_badge_painter.dart';
import 'factory_elements.dart';
import 'palette.dart';
import 'ui_scale.dart';

/// O placar, na faixa acima da moldura.
///
/// Só desenha: recebe os números prontos e não pergunta nada ao jogo. Quem lê
/// o jogo é o componente da cena, uma vez por quadro.
class HudPainter {
  HudPainter(FactoryElements elements)
      : _headline = elements.headline,
        _label = elements.label;

  final BitmapText _headline;
  final BitmapText _label;

  /// Margem lateral, para o número não encostar na borda da tela.
  static const double _margin = 70;

  /// Desenha dentro de [band] — a faixa livre acima da moldura, em
  /// coordenadas locais de quem chama.
  ///
  /// **Sem separador de milhar, e "CHAIN X2" com a letra X.** A fonte de
  /// manchete do pacote tem só A–Z e 0–9: não existe ponto nem sinal de
  /// vezes nela. A alternativa era escrever o placar na fonte pequena, que
  /// tem os dois — mas o placar é a manchete da tela, e manchete é o que essa
  /// fonte existe para ser.
  void render(
    Canvas canvas,
    Rect band, {
    required int score,
    required int chainLevel,
  }) {
    final labelHeight =
        (_label.font.glyphHeight * UiScale.label).toDouble();
    final scoreHeight =
        (_headline.font.glyphHeight * UiScale.headline).toDouble();
    final blockHeight = labelHeight + 8 + scoreHeight;
    final top = band.center.dy - blockHeight / 2;

    final esquerda = Rect.fromLTWH(
      band.left + _margin,
      top,
      band.width / 2 - _margin,
      labelHeight,
    );
    _label.render(
      canvas,
      'PONTOS',
      esquerda.topLeft,
      scale: UiScale.label,
      tint: Palette.textSecondary,
    );
    _headline.render(
      canvas,
      '$score',
      Offset(esquerda.left, top + labelHeight + 8),
      scale: UiScale.headline,
    );

    // O mesmo corte do selo que salta no tabuleiro, lido de lá: é o mesmo
    // número anunciado em dois lugares, e duas cópias da regra são duas que um
    // dia discordam.
    if (chainLevel < ChainBadgePainter.minLevel) {
      return;
    }
    final direita = Rect.fromLTWH(
      band.center.dx,
      top,
      band.width / 2 - _margin,
      labelHeight,
    );
    _label.renderRight(
      canvas,
      'CHAIN',
      direita,
      scale: UiScale.label,
      tint: Palette.chain,
    );
    _headline.renderRight(
      canvas,
      'X$chainLevel',
      Rect.fromLTWH(
        direita.left,
        top + labelHeight + 8,
        direita.width,
        scoreHeight,
      ),
      scale: UiScale.headline,
    );
  }
}
