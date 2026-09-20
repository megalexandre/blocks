import 'dart:ui';

import 'package:flame/flame.dart';

import '../config/layout.dart';
import 'game_assets.dart';

/// A paisagem que fica atrás dos blocos, no lugar da cor chapada que o
/// tabuleiro tinha antes.
///
/// A arte vem desenhada no canvas de referência inteiro (1080×1920), mas só
/// tem conteúdo dentro do vão do tabuleiro — o resto é transparente. Em vez
/// de desenhar a imagem toda e torcer para o alinhamento bater, este
/// carregador recorta exatamente esse vão e o estica sobre o tabuleiro: assim
/// a arte acompanha o board mesmo se as constantes do [GameLayout] mudarem,
/// em vez de depender de os dois estarem por acaso no mesmo lugar.
class ScenarioBackground {
  final _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  late final Image _image;

  Future<void> load() async {
    _image = await Flame.images.load(GameAsset.scenario.fileName);
  }

  /// O pedaço da arte que corresponde ao vão do tabuleiro.
  static final Rect _boardVoid = Rect.fromLTWH(
    GameLayout.boardVoidLeft,
    GameLayout.boardVoidTop,
    GameLayout.boardVoidWidth,
    GameLayout.boardVoidHeight,
  );

  /// Preenche [board] — o retângulo do tabuleiro, em coordenadas locais de
  /// quem desenha.
  void render(Canvas canvas, Rect board) =>
      canvas.drawImageRect(_image, _boardVoid, board, _paint);
}
