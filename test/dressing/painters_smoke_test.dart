import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/config/layout.dart';
import 'package:blocos/dressing/bitmap_font.dart';
import 'package:blocos/dressing/chain_badge_painter.dart';
import 'package:blocos/dressing/factory_elements.dart';
import 'package:blocos/dressing/game_over_painter.dart';
import 'package:blocos/dressing/hud_painter.dart';
import 'package:blocos/dressing/panel_sprites.dart';
import 'package:blocos/dressing/ui_scale.dart';
import 'package:blocos/game/model/board_geometry.dart';
import 'package:blocos/scene/gate_component.dart';

/// Desenha de verdade, num canvas descartável.
///
/// Os pintores do pacote carregam `assert` que só disparam desenhando: painel
/// menor que os próprios cantos, caractere que a fonte não tem, placar caindo
/// por baixo do botão. Nenhum outro teste chega até eles, e no app eles só
/// aparecem quando aquela tela abre — o de fim de jogo, por exemplo, exige
/// perder uma partida inteira.
void _draw(void Function(ui.Canvas canvas) paint) {
  final recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  recorder.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FactoryElements elements;

  setUpAll(() async {
    elements = FactoryElements();
    await elements.loadInterface();
  });

  test('o painel de fim de jogo desenha, e o placar não invade o botão', () {
    for (final score in [0, 7, 12480, 9999999]) {
      _draw((canvas) {
        GameOverPainter(elements).render(
          canvas,
          GateComponent.frameRect(),
          score: score,
        );
      });
    }
  });

  test('o placar desenha em toda faixa de pontuação e de chain', () {
    final band = ui.Rect.fromLTWH(
      0,
      0,
      GameLayout.width,
      GateComponent.frameRect().top,
    );
    for (final score in [0, 999, 1000000]) {
      for (final chain in [0, 1, 2, 9]) {
        _draw((canvas) {
          HudPainter(elements)
              .render(canvas, band, score: score, chainLevel: chain);
        });
      }
    }
  });

  test('o selo do multiplicador desenha em todo nível e em todo desbote', () {
    // O `×` do selo é o sinal de multiplicação, e ele existe só na fonte
    // pequena: escrito na de manchete, o `assert` do `BitmapText` derruba o
    // jogo — mas só na primeira chain de 2, que é jogo rodando.
    for (final level in [2, 3, 9, 12]) {
      for (final fade in [0.0, 0.5, 1.0]) {
        _draw((canvas) {
          ChainBadgePainter(elements).render(
            canvas,
            ui.Offset.zero & ChainBadgePainter.sizeFor(level),
            level: level,
            fade: fade,
          );
        });
      }
    }
  });

  test('o selo cabe numa célula, e o número cabe dentro dele', () {
    // Cresceu a escala do número e o selo passa a tapar a jogada que ele
    // anuncia. A conta fecha em 120×80 numa célula de 128.
    final cell = GameLayout.boardVoidWidth / BoardGeometry.standard.columnCount;
    final badge = ChainBadgePainter.sizeFor(ChainBadgePainter.minLevel);
    expect(badge.width, lessThanOrEqualTo(cell));
    expect(badge.height, lessThanOrEqualTo(cell));

    final number = BitmapFont.pequena.measure(
      ChainBadgePainter.textOf(ChainBadgePainter.minLevel),
      scale: UiScale.chainBadge,
    );
    expect(
      badge.height - number.height,
      greaterThan(ChainBadgePainter.borderWidth * 2),
      reason: 'o número tem que sobrar folga para dentro da borda dourada',
    );
  });

  test('a moldura desenha no retângulo que ela mesma calcula', () {
    _draw((canvas) {
      elements.panels.render(
        canvas,
        PanelFamily.greenBoard,
        GateComponent.frameRect(),
        fillCenter: false,
      );
      elements.panels.render(
        canvas,
        PanelFamily.yellowBoard,
        GateComponent.doorRect(),
      );
    });
  });

  test('todo painel do jogo é maior que os próprios cantos', () {
    // O `assert` do NineSlice pegou o botão do menu na primeira vez que ele
    // subiu. Aqui a conta é conferida sem precisar abrir a tela.
    final quadros = <String, (ui.Rect, int)>{
      'moldura': (GateComponent.frameRect(), UiScale.panel),
      'porta': (GateComponent.doorRect(), UiScale.panel),
      'cartão de fim de jogo': (
        GameOverPainter.cardRect(GateComponent.frameRect()),
        UiScale.panel,
      ),
      'botão de fim de jogo': (
        GameOverPainter.buttonRect(GateComponent.frameRect()),
        UiScale.button,
      ),
    };
    quadros.forEach((nome, medida) {
      final (area, scale) = medida;
      final minimo = 32.0 * scale * 2;
      expect(area.width, greaterThanOrEqualTo(minimo), reason: nome);
      expect(area.height, greaterThanOrEqualTo(minimo), reason: nome);
    });
  });
}
