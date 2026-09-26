import 'dart:ui';

import 'package:flame/flame.dart';

import 'bitmap_font.dart';

/// Desenha texto com uma [BitmapFont]: um `drawImageRect` por glifo, recortado
/// da fita.
///
/// A métrica mora na fonte; aqui só entra o que precisa de `Canvas`.
class BitmapText {
  BitmapText(this.font);

  final BitmapFont font;

  late final Image _sheet;

  final _paint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  Future<void> load() async {
    _sheet = await Flame.images.load(font.asset.fileName);
    // A folha é saída de build commitada no repositório: quem acrescentar um
    // glifo à fonte e esquecer de rodar `tool/build_ui_sheets.sh` veria o
    // texto sair deslocado a partir do glifo novo, sem erro nenhum. Aqui isso
    // estoura na abertura.
    assert(
      _sheet.width == font.glyphCount * font.glyphWidth &&
          _sheet.height == font.glyphHeight,
      '${font.asset.fileName} está com ${_sheet.width}×${_sheet.height}, mas a '
      'fonte descreve ${font.glyphCount} glifos de '
      '${font.glyphWidth}×${font.glyphHeight}; rode tool/build_ui_sheets.sh',
    );
  }

  /// Desenha [text] com o canto superior esquerdo em [at].
  ///
  /// [tint] só vale para fonte de uma cor só: a fita pequena é `#33323D`
  /// chapado e some contra o fundo escuro, então precisa ser clareada. A
  /// grande já é colorida, e tingi-la apagaria o desenho.
  ///
  /// Caractere que a fonte não tem **avança como espaço** em vez de estourar
  /// ou de sumir: sumir sem avançar encolhe o texto e desalinha tudo que foi
  /// centralizado, que é mais difícil de notar que um buraco.
  void render(
    Canvas canvas,
    String text,
    Offset at, {
    required int scale,
    Color? tint,
  }) {
    assert(
      tint == null || font.monochrome,
      'a fonte ${font.asset.fileName} é colorida e não aceita tingimento',
    );
    assert(
      font.missingIn(text).isEmpty,
      'a fonte ${font.asset.fileName} não tem '
      '${font.missingIn(text).join(", ")} — em "$text"',
    );

    _paint.colorFilter =
        tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn);

    final height = (font.glyphHeight * scale).toDouble();
    var x = at.dx;
    for (var i = 0; i < text.length; i++) {
      final index = text[i] == ' ' ? -1 : font.indexOf(text[i]);
      if (index >= 0) {
        canvas.drawImageRect(
          _sheet,
          Rect.fromLTWH(
            (index * font.glyphWidth).toDouble(),
            0,
            font.glyphWidth.toDouble(),
            font.glyphHeight.toDouble(),
          ),
          Rect.fromLTWH(x, at.dy, (font.glyphWidth * scale).toDouble(), height),
          _paint,
        );
      }
      x += ((text[i] == ' ' ? font.spaceWidth : font.glyphWidth) + font.letterSpacing) *
          scale;
    }
  }

  /// Centrado em [area], com a posição arredondada para unidade inteira do
  /// canvas — meia unidade faz o pixel art sair com fileiras de larguras
  /// diferentes.
  void renderCentered(
    Canvas canvas,
    String text,
    Rect area, {
    required int scale,
    Color? tint,
  }) {
    final size = font.measure(text, scale: scale);
    render(
      canvas,
      text,
      Offset(
        (area.center.dx - size.width / 2).roundToDouble(),
        (area.center.dy - size.height / 2).roundToDouble(),
      ),
      scale: scale,
      tint: tint,
    );
  }

  /// Alinhado pela direita em [area], para número que cresce sem empurrar o
  /// rótulo.
  void renderRight(
    Canvas canvas,
    String text,
    Rect area, {
    required int scale,
    Color? tint,
  }) {
    final size = font.measure(text, scale: scale);
    render(
      canvas,
      text,
      Offset(
        (area.right - size.width).roundToDouble(),
        (area.center.dy - size.height / 2).roundToDouble(),
      ),
      scale: scale,
      tint: tint,
    );
  }
}
