import 'dart:ui';

import 'bitmap_text.dart';
import 'factory_elements.dart';
import 'icon_sprites.dart';
import 'palette.dart';
import 'ui_scale.dart';

/// O controle que empurra a pilha para cima, **cavado na lateral da moldura**.
///
/// Não é um cartão apoiado sobre a moldura: é um vão aberto nela. O chanfro
/// escuro em cima e à esquerda e claro embaixo e à direita é o que faz ler
/// como afundado — invertido, leria como botão saltado.
///
/// Desenhar dentro do batente também resolve uma disputa: a borda lateral da
/// moldura e a faixa de toque ocupam o mesmo retângulo da tela. Quem recua é o
/// desenho; **a área de toque continua sendo a faixa inteira**, que é o que se
/// acerta sem olhar no meio da partida.
class BoostPainter {
  BoostPainter(FactoryElements elements)
      : _icons = elements.icons,
        _label = elements.label;

  final IconSprites _icons;
  final BitmapText _label;

  static const String _word = 'SUBIR';

  /// Espessura do chanfro, em unidades do canvas.
  static const double _bevel = 8;

  final _fill = Paint()..color = Palette.insetFill;
  final _fillPressed = Paint()..color = Palette.playfieldBorder;
  final _shadow = Paint()..color = Palette.insetShadow;
  final _light = Paint()..color = Palette.insetLight;

  void render(Canvas canvas, Rect area, {required bool pressed}) {
    canvas.drawRect(area, pressed ? _fillPressed : _fill);

    // Pressionado, o rebaixo afunda mais: o chanfro troca de lado, e é a
    // mesma leitura que um botão de verdade dá ao ser empurrado.
    final alto = pressed ? _light : _shadow;
    final baixo = pressed ? _shadow : _light;
    canvas
      ..drawRect(Rect.fromLTWH(area.left, area.top, area.width, _bevel), alto)
      ..drawRect(Rect.fromLTWH(area.left, area.top, _bevel, area.height), alto)
      ..drawRect(
        Rect.fromLTWH(area.right - _bevel, area.top, _bevel, area.height),
        baixo,
      )
      ..drawRect(
        Rect.fromLTWH(area.left, area.bottom - _bevel, area.width, _bevel),
        baixo,
      );

    final glyph = _label.font.glyphHeight * UiScale.boostLabel;
    final step = glyph + 6.0;
    final wordHeight = _word.length * step - 6;
    final iconHeight = IconSprites.height * UiScale.icon.toDouble();
    final blockHeight = iconHeight + 20 + wordHeight;
    var y = area.center.dy - blockHeight / 2;

    _icons.render(
      canvas,
      GameIcon.setaCima,
      Rect.fromLTWH(area.left, y, area.width, iconHeight),
      scale: UiScale.icon,
      tint: Palette.textPrimary,
    );
    y += iconHeight + 20;

    // Letra por letra, de cima para baixo: a coluna é estreita demais para a
    // palavra deitada, e girar o canvas borraria o pixel art.
    for (final letter in _word.split('')) {
      _label.renderCentered(
        canvas,
        letter,
        Rect.fromLTWH(area.left, y, area.width, glyph.toDouble()),
        scale: UiScale.boostLabel,
        tint: Palette.textPrimary,
      );
      y += step;
    }
  }
}
