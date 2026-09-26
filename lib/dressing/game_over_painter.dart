import 'dart:math' as math;
import 'dart:ui';

import 'bitmap_text.dart';
import 'factory_elements.dart';
import 'palette.dart';
import 'panel_sprites.dart';
import 'ui_scale.dart';

/// O painel de fim de partida, desenhado sobre o tabuleiro.
///
/// Aparece por cima da porta, que fecha junto: o cartão é a última coisa da
/// tela, e por isso o `GameOverComponent` é o de maior prioridade da cena.
class GameOverPainter {
  GameOverPainter(FactoryElements elements)
      : _panels = elements.panels,
        _headline = elements.headline,
        _label = elements.label;

  final PanelSprites _panels;
  final BitmapText _headline;
  final BitmapText _label;

  /// Papel, e não tábua: o cartão é um aviso colado por cima da cena, não mais
  /// um pedaço de cenário. A madeira o faria desaparecer dentro da moldura.
  static const PanelFamily cardFamily = PanelFamily.yellowPaper;

  /// Medidas do cartão e do botão, em unidades do canvas de referência.
  static const double cardWidth = 620;
  static const double cardHeight = 600;
  static const double buttonWidth = 460;

  /// Folga entre o rótulo e as bordas do botão.
  static const double _labelPadding = 96;

  /// Alto o bastante para o quadro do botão caber: em escala 2 os dois cantos
  /// somam 128, e os 108 de antes não sustentavam o próprio contorno.
  static const double buttonHeight = 140;

  /// Onde o cartão cai dentro de [board].
  static Rect cardRect(Rect board) => Rect.fromCenter(
        center: board.center,
        width: cardWidth,
        height: cardHeight,
      );

  /// Onde o botão cai dentro de [board].
  ///
  /// Função pura e pública de propósito: é a **mesma** conta que decide onde o
  /// botão é desenhado e onde o toque é aceito. Duas contas parecidas em
  /// lugares diferentes é como um botão passa a responder fora do lugar em que
  /// aparece.
  static Rect buttonRect(Rect board) => Rect.fromCenter(
        center: Offset(board.center.dx, board.center.dy + 120),
        width: buttonWidth,
        height: buttonHeight,
      );

  void render(Canvas canvas, Rect board, {required int score}) {
    final card = cardRect(board);
    _panels.render(canvas, cardFamily, card);

    // As três linhas empilham a partir do topo do cartão, e a última termina
    // antes de onde o botão começa. Antes cada uma tinha um deslocamento
    // escolhido solto, e o placar caía por baixo do botão.
    var y = card.top + 70;
    _headline.renderCentered(
      canvas,
      'FIM',
      Rect.fromLTWH(card.left, y, card.width, 120),
      scale: UiScale.title,
    );
    y += 140;
    _label.renderCentered(
      canvas,
      'PONTOS',
      Rect.fromLTWH(card.left, y, card.width, 40),
      scale: UiScale.label,
      tint: Palette.insetShadow,
    );
    y += 50;
    _headline.renderCentered(
      canvas,
      '$score',
      Rect.fromLTWH(card.left, y, card.width, 80),
      scale: UiScale.headline,
    );
    assert(
      y + 80 <= buttonRect(board).top,
      'o placar terminou em ${y + 80} e o botão começa em '
      '${buttonRect(board).top}: as duas coisas vão se sobrepor',
    );

    final button = buttonRect(board);
    _panels.render(
      canvas,
      PanelFamily.greenBoard,
      button,
      scale: UiScale.button,
    );
    // `UiScale.button` é escala de **painel**, não de fonte — o rótulo pede a
    // de manchete, limitada ao que cabe entre as bordas do botão. `fitScale`
    // devolve inteiro, então o pixel continua quadrado.
    const label = 'DE NOVO';
    _headline.renderCentered(
      canvas,
      label,
      button,
      scale: math.min(
        UiScale.headline,
        _headline.font.fitScale(label, button.width - _labelPadding),
      ),
    );
  }
}
