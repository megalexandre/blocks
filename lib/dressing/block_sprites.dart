import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../game/model/block.dart';
import 'game_assets.dart';

/// Fatia `blocks.png` e desenha o bloco de cada cor. Quem usa não precisa
/// saber que existe uma folha, nem onde cada bloco está dentro dela.
class BlockSprites {
  /// Lado de cada tile na folha. A célula do tabuleiro tem o mesmo tamanho,
  /// então o bloco sai 1:1, sem redimensionar a arte.
  static const double tileSize = 128;

  /// Coluna de cada cor, na ordem em que a arte foi desenhada: coração,
  /// círculo, gota, losango, estrela, triângulo.
  ///
  /// A gota já estava desenhada e sem uso quando o jogo tinha cinco cores
  /// para seis peças na folha. A forma importa tanto quanto o tom: ciano e
  /// azul são vizinhos no espectro, e é a silhueta — gota contra triângulo —
  /// que separa os dois de relance num tabuleiro cheio.
  static const Map<BlockColor, int> _column = {
    BlockColor.red: 0,
    BlockColor.green: 1,
    BlockColor.cyan: 2,
    BlockColor.purple: 3,
    BlockColor.yellow: 4,
    BlockColor.blue: 5,
  };

  // Tile de 128px desenhado em ~50px de tela (redução de ~2,6×). Com
  // `none` a amostragem é nearest-neighbor: descarta a maioria dos texels
  // de origem, e *quais* ela descarta muda conforme a pilha sobe em fração
  // de pixel — detalhe de 1px (contorno, brilho) pisca. `medium` usa
  // mipmap, que pré-média a origem e para de depender da fase sub-pixel.
  final _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  final Map<BlockColor, Sprite> _sprites = {};

  Future<void> load() async {
    // Uma cor sem tile só apareceria como estouro no meio de uma partida, na
    // primeira vez que ela fosse sorteada. Aqui falha na abertura, dizendo
    // qual.
    assert(() {
      final semTile = BlockColor.values.where(
        (color) => !_column.containsKey(color),
      );
      return semTile.isEmpty;
    }(), 'há cor sem tile na folha de sprites');
    final image = await Flame.images.load(GameAsset.blocks.fileName);
    for (final entry in _column.entries) {
      _sprites[entry.key] = Sprite(
        image,
        srcPosition: Vector2(entry.value * tileSize, 0),
        srcSize: Vector2.all(tileSize),
      );
    }
  }

  /// Desenha o bloco de [color] preenchendo [rect]. [opacity] esmaece o
  /// sprite inteiro — usado no estouro, enquanto ele encolhe.
  void render(
    Canvas canvas,
    BlockColor color,
    Rect rect, {
    double opacity = 1,
  }) {
    final sprite = _sprites[color]!;
    // Só o alpha do paint importa pro drawImageRect (o RGB é ignorado sem
    // colorFilter) — branco é só convenção de leitura.
    _paint.color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(sprite.image, sprite.src, rect, _paint);
  }
}
