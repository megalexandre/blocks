import 'dart:ui';

import 'bitmap_font.dart';
import 'bitmap_text.dart';
import 'factory_elements.dart';
import 'palette.dart';
import 'ui_scale.dart';

/// O selo do multiplicador: "×2", "×3" — o número que salta rente ao grupo
/// que acabou de fechar a combinação.
///
/// Escrito na fonte **pequena**, e não na de manchete que o placar usa. Os
/// dois motivos vêm da fonte: a pequena tem o glifo `×` de verdade — a de
/// manchete só tem A–Z e 0–9, e é por isso que o HUD escreve "X2" com a letra
/// X —, e ela é de uma cor só, logo aceita ser tingida. É o tingimento que
/// permite o selo desbotar: a fonte colorida não aceita, e apagá-la exigiria
/// um `saveLayer` por selo a cada quadro.
///
/// Só desenha, como todo pintor daqui: quem conta o tempo de vida é o
/// `ChainBadgeComponent`, e o que chega aqui é um retângulo e o quanto já
/// desbotou.
class ChainBadgePainter {
  ChainBadgePainter(FactoryElements elements) : _label = elements.label;

  final BitmapText _label;

  /// A partir de que nível o selo aparece.
  ///
  /// Uma combinação simples é chain 1, e um "×1" saltando em cima de toda
  /// jogada é ruído — chain só é notícia a partir de 2, quando uma queda de
  /// fato encadeou outra combinação. O corte mora aqui e o `HudPainter` o lê
  /// daqui: os dois mostram o mesmo número em lugares diferentes, e duas
  /// cópias da mesma regra são duas que um dia discordam.
  static const int minLevel = 2;

  /// Folga entre o número e a borda do selo, em unidades do canvas.
  static const double padding = 16;

  /// Espessura da borda dourada.
  static const double borderWidth = 4;

  /// O quanto a placa deixa ver o tabuleiro por baixo. Não é opaca: o selo
  /// nasce **sobre** os blocos que ainda estão estourando, e tapá-los por
  /// inteiro esconderia justamente o que ele está anunciando.
  static const double plateOpacity = 0.86;

  /// O texto do selo. O `×` é o sinal de multiplicação, não a letra.
  static String textOf(int level) => '×$level';

  /// Quanto o selo ocupa, em unidades do canvas — "×10" é mais largo que
  /// "×2", então o tamanho é função do número.
  ///
  /// Estático porque quem cria o selo precisa da medida **antes** de existir
  /// um selo: é por ela que o tabuleiro decide onde ele cabe.
  static Size sizeFor(int level) {
    final text = BitmapFont.pequena.measure(
      textOf(level),
      scale: UiScale.chainBadge,
    );
    return Size(text.width + padding * 2, text.height + padding * 2);
  }

  final _plate = Paint()..isAntiAlias = false;
  final _border = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth;

  /// Desenha o selo preenchendo [area]. [fade] vai de 0, cheio, a 1, sumido.
  void render(
    Canvas canvas,
    Rect area, {
    required int level,
    double fade = 0,
  }) {
    final visible = (1 - fade).clamp(0.0, 1.0);
    final ink = Palette.chain.withAlpha((visible * 255).round());
    _plate.color = Palette.surface.withAlpha(
      (visible * plateOpacity * 255).round(),
    );
    _border.color = ink;
    canvas
      ..drawRect(area, _plate)
      // Meia espessura para dentro: a borda desenhada sobre a aresta sairia
      // metade fora do selo, e o tabuleiro mediu o espaço contando com ela
      // dentro.
      ..drawRect(area.deflate(borderWidth / 2), _border);
    _label.renderCentered(
      canvas,
      textOf(level),
      area,
      scale: UiScale.chainBadge,
      tint: ink,
    );
  }
}
