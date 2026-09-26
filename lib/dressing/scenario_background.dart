import 'dart:ui';

import 'package:flame/flame.dart';

import '../config/layout.dart';
import 'game_assets.dart';

/// A paisagem que fica atrás dos blocos.
///
/// A arte vem desenhada no canvas de referência inteiro (1080×1920), mas só
/// tem conteúdo **dentro do vão do tabuleiro** — o resto é transparente.
class ScenarioBackground {
  final _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  late final Image _image;

  Future<void> load() async {
    _image = await Flame.images.load(GameAsset.scenario.fileName);
  }

  /// O pedaço da arte que tem conteúdo.
  static final Rect _boardVoid = Rect.fromLTWH(
    GameLayout.boardVoidLeft,
    GameLayout.boardVoidTop,
    GameLayout.boardVoidWidth,
    GameLayout.boardVoidHeight,
  );

  /// O recorte que enche [area] sem distorcer.
  ///
  /// A paisagem passa **por baixo da moldura**, e a moldura é maior que o vão.
  /// Recortar direto o retângulo da moldura traria a margem transparente da
  /// arte junto e deixaria uma faixa vazia sob o batente — então o recorte é
  /// feito dentro do vão, na proporção do destino, e é ele que é ampliado.
  ///
  /// Ancorado embaixo: o que sobra de fora é céu, e é o chão que dá senso de
  /// chão.
  static Rect sourceFor(Rect area) {
    final aspect = area.width / area.height;
    var width = _boardVoid.width;
    var height = width / aspect;
    if (height > _boardVoid.height) {
      height = _boardVoid.height;
      width = height * aspect;
    }
    return Rect.fromLTWH(
      _boardVoid.center.dx - width / 2,
      _boardVoid.bottom - height,
      width,
      height,
    );
  }

  /// Preenche [area], em coordenadas de quem desenha.
  void render(Canvas canvas, Rect area) =>
      canvas.drawImageRect(_image, sourceFor(area), area, _paint);
}
