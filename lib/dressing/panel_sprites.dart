import 'dart:ui';

import 'package:flame/flame.dart';

import 'game_assets.dart';
import 'nine_slice.dart';
import 'ui_scale.dart';

/// As famílias de painel da folha, na ordem em que `tool/build_ui_sheets.sh`
/// as empilha.
enum PanelFamily { greenBoard, yellowBoard, orangePaper, yellowPaper }

/// Fatia `ui/panels.png` e desenha um painel de qualquer tamanho.
///
/// Mesmo formato do `BlockSprites`: uma folha, um mapa de índice, e quem usa
/// não precisa saber onde cada pedaço mora. A diferença é que aqui o pedaço
/// não é um bloco pronto, é um dos nove do quadro — a geometria de quantos
/// cabem e onde é do [NineSlice].
class PanelSprites {
  /// Lado do tile na folha. Cada família ocupa um bloco de 3×3 desses.
  static const int tileSize = 32;

  static const Map<PanelFamily, int> _block = {
    PanelFamily.greenBoard: 0,
    PanelFamily.yellowBoard: 1,
    PanelFamily.orangePaper: 2,
    PanelFamily.yellowPaper: 3,
  };

  /// Pixel art **parado**: `none` preserva a aresta dura, e antialias só
  /// borraria o contorno de 1px que o pacote inteiro usa. É o oposto do que o
  /// `BlockSprites` faz, e pelo motivo oposto — ver [UiScale].
  final _paint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;

  late final Image _sheet;

  /// Memória do último quadro desenhado. A moldura e a porta pedem os mesmos
  /// cem e poucos pedaços a cada quadro, e a conta não muda enquanto o
  /// retângulo não muda — a porta, deslizando, muda de posição e não de
  /// tamanho, então o `translate` de quem chama resolve sem recalcular.
  ({NineSlice slice, Rect area, bool fill, List<NineSlicePiece> pieces})? _memo;

  Future<void> load() async {
    _sheet = await Flame.images.load(GameAsset.panels.fileName);
    assert(
      _sheet.width == tileSize * 3 &&
          _sheet.height == tileSize * 3 * PanelFamily.values.length,
      'ui/panels.png está com ${_sheet.width}×${_sheet.height}; rode '
      'tool/build_ui_sheets.sh',
    );
  }

  /// Desenha [family] preenchendo [area].
  ///
  /// Com [fillCenter] falso sai só o quadro, e o miolo fica vazio — é o modo
  /// moldura.
  void render(
    Canvas canvas,
    PanelFamily family,
    Rect area, {
    int scale = UiScale.panel,
    bool fillCenter = true,
  }) {
    final slice = NineSlice(tile: tileSize, scale: scale);
    final memo = _memo;
    final pieces = memo != null &&
            memo.slice.tile == slice.tile &&
            memo.slice.scale == slice.scale &&
            memo.area == area &&
            memo.fill == fillCenter
        ? memo.pieces
        : slice.piecesFor(area, fillCenter: fillCenter);
    _memo = (slice: slice, area: area, fill: fillCenter, pieces: pieces);

    final origemY = (_block[family]! * tileSize * 3).toDouble();
    for (final piece in pieces) {
      canvas.drawImageRect(
        _sheet,
        piece.src.translate(0, origemY),
        piece.dst,
        _paint,
      );
    }
  }
}
