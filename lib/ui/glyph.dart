import 'dart:math' as math;
import 'dart:ui';

/// A forma estampada no bloco. No Tetris Attack original cada cor tem o seu
/// símbolo, e é ele que segura o jogo quando a cor não basta: na tela pequena,
/// no meio da pilha subindo, ou para quem não distingue vermelho de verde.
enum Glyph {
  heart,
  star,
  diamond,
  circle,
  triangle;

  /// O símbolo desenhado dentro de [box], um quadrado centrado no bloco.
  Path pathIn(Rect box) {
    final center = box.center;
    final radius = box.width / 2 * _weight;
    return switch (this) {
      Glyph.circle => Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius)),
      Glyph.diamond => _polygon(center, radius, 4),
      Glyph.triangle => _polygon(center, radius, 3),
      Glyph.star => _star(center, radius),
      Glyph.heart => _heart(center, radius),
    };
  }

  /// Mesmo raio não é mesmo peso na tela: um círculo cheio ocupa muito mais
  /// tinta que uma estrela. Cada forma leva o seu ajuste para que todas
  /// pareçam do mesmo tamanho.
  double get _weight => switch (this) {
    Glyph.circle => 0.88,
    Glyph.diamond => 1.0,
    Glyph.triangle => 1.06,
    Glyph.star => 1.1,
    Glyph.heart => 1.0,
  };
}

/// Os símbolos rasterizados uma vez, como máscara branca.
///
/// Redesenhar o path a cada frame faz as formas de aresta longa em diagonal
/// (triângulo, losango) cintilarem enquanto a pilha sobe: a cada linha de pixel
/// cruzada, a cobertura do anti-aliasing se redistribui ao longo da aresta
/// inteira. Medido no tabuleiro, a "tinta" do triângulo variava ~21% por frame
/// contra ~2% do círculo. Uma máscara pronta é reamostrada por interpolação,
/// que varia suavemente com o deslocamento.
class GlyphMasks {
  GlyphMasks._(this._images);

  /// Lado da máscara em pixels. Generoso: ela é reduzida na tela, nunca ampliada.
  static const int resolution = 128;

  /// Folga em volta da forma, porque algumas passam do quadrado nominal.
  static const double padding = 0.2;

  final Map<Glyph, Image> _images;

  Image operator [](Glyph glyph) => _images[glyph]!;

  /// Retângulo onde desenhar a máscara para a forma cair exatamente onde
  /// [Glyph.pathIn] a colocaria em [box].
  static Rect destinationFor(Rect box) => Rect.fromCenter(
    center: box.center,
    width: box.width * (1 + padding),
    height: box.height * (1 + padding),
  );

  static Future<GlyphMasks> rasterize() async {
    final images = <Glyph, Image>{};
    const side = resolution / (1 + padding);
    final inner = Rect.fromCenter(
      center: const Offset(resolution / 2, resolution / 2),
      width: side,
      height: side,
    );
    final branco = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true;

    for (final glyph in Glyph.values) {
      final recorder = PictureRecorder();
      Canvas(recorder).drawPath(glyph.pathIn(inner), branco);
      images[glyph] = await recorder.endRecording().toImage(
        resolution,
        resolution,
      );
    }
    return GlyphMasks._(images);
  }
}

/// Polígono regular inscrito no círculo, com um vértice apontando para cima.
Path _polygon(Offset center, double radius, int sides) {
  final path = Path();
  for (var i = 0; i < sides; i++) {
    final angle = -math.pi / 2 + i * 2 * math.pi / sides;
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

/// Cinco pontas: vértices alternando entre o raio cheio e o vão interno.
Path _star(Offset center, double radius) {
  const innerRatio = 0.45;
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? radius : radius * innerRatio;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

/// Da ponta de baixo, uma curva sobe por cada lado e se encontra no vinco.
Path _heart(Offset center, double radius) {
  final tipY = center.dy + radius * 0.95;
  final notchY = center.dy - radius * 0.3;
  return Path()
    ..moveTo(center.dx, tipY)
    ..cubicTo(
      center.dx - radius * 1.6,
      center.dy - radius * 0.25,
      center.dx - radius * 0.8,
      center.dy - radius * 1.45,
      center.dx,
      notchY,
    )
    ..cubicTo(
      center.dx + radius * 0.8,
      center.dy - radius * 1.45,
      center.dx + radius * 1.6,
      center.dy - radius * 0.25,
      center.dx,
      tipY,
    )
    ..close();
}
