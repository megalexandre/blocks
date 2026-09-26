import 'dart:ui';

import 'package:flame/flame.dart';

import 'game_assets.dart';

/// Os ícones do pacote, fatiados por índice da fita.
///
/// Só os que o jogo usa ganham nome. Os outros 20 continuam na folha, sem
/// apelido: batizar ícone que ninguém desenha é inventar vocabulário.
enum GameIcon {
  setaEsquerda(0),
  setaDireita(1),
  setaBaixo(2),
  setaCima(3),
  fechar(4),
  confirmar(5);

  const GameIcon(this.slot);

  /// Posição na fita. Explícita, e não o `index` do enum: assim acrescentar um
  /// ícone no meio da lista não empurra os outros de lugar em silêncio.
  final int slot;
}

class IconSprites {
  static const int width = 8;
  static const int height = 6;
  static const int count = 25;

  final _paint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  late final Image _sheet;

  Future<void> load() async {
    _sheet = await Flame.images.load(GameAsset.icons.fileName);
    assert(
      _sheet.width == count * width && _sheet.height == height,
      'ui/icons.png está com ${_sheet.width}×${_sheet.height}; rode '
      'tool/build_ui_sheets.sh',
    );
  }

  /// Desenha [icon] centrado em [area], em escala inteira.
  ///
  /// A fita é escura, do mesmo `#33323D` do contorno do pacote, então sobre
  /// fundo escuro ela precisa de [tint] — igual à fonte pequena.
  void render(
    Canvas canvas,
    GameIcon icon,
    Rect area, {
    required int scale,
    Color? tint,
  }) {
    _paint.colorFilter =
        tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn);
    final w = (width * scale).toDouble();
    final h = (height * scale).toDouble();
    canvas.drawImageRect(
      _sheet,
      Rect.fromLTWH(
        (icon.slot * width).toDouble(),
        0,
        width.toDouble(),
        height.toDouble(),
      ),
      Rect.fromLTWH(
        (area.center.dx - w / 2).roundToDouble(),
        (area.center.dy - h / 2).roundToDouble(),
        w,
        h,
      ),
      _paint,
    );
  }
}
