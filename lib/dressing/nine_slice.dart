import 'dart:math' as math;
import 'dart:ui';

/// Um pedaço do quadro: de onde ele sai na folha e onde ele entra na tela.
///
/// [src] é relativo ao canto do bloco 3×3 da família, em pixels de arte. Quem
/// desenha soma a posição da família dentro da folha — assim esta classe não
/// precisa saber que existe uma folha com várias famílias empilhadas.
class NineSlicePiece {
  const NineSlicePiece({required this.src, required this.dst});

  final Rect src;
  final Rect dst;
}

/// O quadro de nove pedaços: cantos no tamanho natural, arestas repetidas no
/// eixo em que a arte corre, miolo repetido nos dois.
///
/// **Repete, não estica.** O miolo do `Yellow Board` é tijolo e o do
/// `Green Board` é tábua com pregos; esticar 768 unidades a partir de 32 pixels
/// vira borrão. Repetindo em escala inteira, todo pixel de arte continua
/// quadrado. É a diferença entre isto e o `NineTileBox` do Flame, que estica —
/// e o motivo de este existir.
///
/// Não conhece `Image` nem `Canvas`: é geometria, e é testada como tal, do
/// mesmo jeito que `BoardViewport`.
class NineSlice {
  const NineSlice({required this.tile, required this.scale});

  /// Lado do tile na folha, em pixels de arte. 32 nos painéis.
  final int tile;

  /// Quantas vezes cada pixel de arte é ampliado. Inteiro por regra: é o que
  /// mantém o pixel quadrado, e o que permite um `drawAtlas` por painel —
  /// `RSTransform` só aceita escala uniforme.
  final int scale;

  /// Lado do canto, já ampliado. É a menor borda que o quadro tem.
  double get border => (tile * scale).toDouble();

  /// O menor retângulo que ainda mostra os nove pedaços sem um invadir o
  /// outro: dois cantos em cada eixo.
  Size get minimumSize => Size(border * 2, border * 2);

  /// Os pedaços que cobrem [area].
  ///
  /// Com [fillCenter] falso o miolo fica vazio — é o modo moldura, que é o
  /// quadro em volta de um buraco.
  ///
  /// Quando a sobra de uma fileira é menor que um tile, o pedaço sai com a
  /// **origem recortada** e não esticada: `src` encolhe na mesma proporção que
  /// `dst`, então a escala continua uniforme em todo pedaço.
  List<NineSlicePiece> piecesFor(Rect area, {bool fillCenter = true}) {
    assert(
      area.width >= minimumSize.width && area.height >= minimumSize.height,
      'painel de ${area.width}×${area.height} não cabe dois cantos de $border',
    );

    final b = border;
    final t = tile.toDouble();
    final innerWidth = math.max(0.0, area.width - b * 2);
    final innerHeight = math.max(0.0, area.height - b * 2);
    final pieces = <NineSlicePiece>[];

    Rect source(int row, int col, {double? width, double? height}) =>
        Rect.fromLTWH(col * t, row * t, width ?? t, height ?? t);

    pieces
      ..add(NineSlicePiece(
        src: source(0, 0),
        dst: Rect.fromLTWH(area.left, area.top, b, b),
      ))
      ..add(NineSlicePiece(
        src: source(0, 2),
        dst: Rect.fromLTWH(area.right - b, area.top, b, b),
      ))
      ..add(NineSlicePiece(
        src: source(2, 0),
        dst: Rect.fromLTWH(area.left, area.bottom - b, b, b),
      ))
      ..add(NineSlicePiece(
        src: source(2, 2),
        dst: Rect.fromLTWH(area.right - b, area.bottom - b, b, b),
      ));

    for (var x = 0.0; x < innerWidth; x += b) {
      final width = math.min(b, innerWidth - x);
      final sliceWidth = width / scale;
      pieces
        ..add(NineSlicePiece(
          src: source(0, 1, width: sliceWidth),
          dst: Rect.fromLTWH(area.left + b + x, area.top, width, b),
        ))
        ..add(NineSlicePiece(
          src: source(2, 1, width: sliceWidth),
          dst: Rect.fromLTWH(area.left + b + x, area.bottom - b, width, b),
        ));
    }

    for (var y = 0.0; y < innerHeight; y += b) {
      final height = math.min(b, innerHeight - y);
      final sliceHeight = height / scale;
      pieces
        ..add(NineSlicePiece(
          src: source(1, 0, height: sliceHeight),
          dst: Rect.fromLTWH(area.left, area.top + b + y, b, height),
        ))
        ..add(NineSlicePiece(
          src: source(1, 2, height: sliceHeight),
          dst: Rect.fromLTWH(area.right - b, area.top + b + y, b, height),
        ));
    }

    if (!fillCenter) {
      return pieces;
    }

    for (var y = 0.0; y < innerHeight; y += b) {
      final height = math.min(b, innerHeight - y);
      for (var x = 0.0; x < innerWidth; x += b) {
        final width = math.min(b, innerWidth - x);
        pieces.add(NineSlicePiece(
          src: source(1, 1, width: width / scale, height: height / scale),
          dst: Rect.fromLTWH(
            area.left + b + x,
            area.top + b + y,
            width,
            height,
          ),
        ));
      }
    }
    return pieces;
  }
}
