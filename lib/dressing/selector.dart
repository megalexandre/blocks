import 'dart:ui';

import 'package:flame/flame.dart';

import 'game_assets.dart';

class Selector {
  final _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  late final Image _image;

  Future<void> load() async {
    _image = await Flame.images.load(GameAsset.selector.fileName);
  }

  /// Desenha centrado em [cells] — as células selecionadas — no tamanho
  /// natural da arte, 1:1, sem redimensionar.
  ///
  /// A arte é maior que as células de propósito (268×140 para 256×128, ou
  /// seja 6px de sobra por lado): é isso que faz o seletor aparecer um
  /// pouco por fora do bloco em vez de por dentro. Vale a convenção do
  /// projeto: 1 pixel de arte = 1 unidade do canvas de referência.
  void render(Canvas canvas, Rect cells) {
    final dst = Rect.fromCenter(
      center: cells.center,
      width: _image.width.toDouble(),
      height: _image.height.toDouble(),
    );
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      dst,
      _paint,
    );
  }
}
