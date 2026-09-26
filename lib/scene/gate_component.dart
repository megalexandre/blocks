import 'dart:ui';

import 'package:flame/components.dart';

import '../config/layout.dart';
import '../dressing/panel_sprites.dart';
import '../dressing/ui_scale.dart';
import 'game_scene.dart';

/// A moldura em volta do vão: o quadro de nove pedaços, com o miolo vazio.
///
/// Herdeira do gate que existia antes, com uma diferença de fundo: aquele era
/// uma arte de tela cheia, com o vão já desenhado dentro dela. Este é um
/// quadro montado sobre o retângulo do tabuleiro, então mudar
/// [GameLayout.boardVoidWidth] move a moldura junto em vez de desalinhá-la da
/// arte.
class GateComponent extends PositionComponent with HasGameReference<GameScene> {
  GateComponent() : super(priority: 5);

  /// Qual família veste a moldura. Diferente da porta de propósito: com a
  /// mesma nas duas, a porta fechada some dentro do batente e o conjunto vira
  /// uma tábua só.
  static const PanelFamily family = PanelFamily.greenBoard;

  /// O retângulo da moldura: o vão inflado pela borda.
  ///
  /// Estático e função pura das constantes, pelo mesmo motivo do
  /// `BoardComponent.layoutFor()` — quem precisa encostar na moldura calcula a
  /// mesma área sem depender da ordem de montagem.
  ///
  /// Com borda de 128 (o tile de 32 em escala 4, que é também a célula do
  /// tabuleiro) a conta fecha sem tile cortado: as arestas de cima e de baixo
  /// dão 6 tiles, as laterais dão 12, e a borda de baixo encosta exatamente no
  /// fim do canvas.
  static Rect frameRect() => Rect.fromLTWH(
        GameLayout.boardVoidLeft - UiScale.frameBorder,
        GameLayout.boardVoidTop - UiScale.frameBorder,
        GameLayout.boardVoidWidth + UiScale.frameBorder * 2,
        GameLayout.boardVoidHeight + UiScale.frameBorder * 2,
      );

  /// Onde a paisagem é desenhada: o vão sangrado **metade** da borda para
  /// dentro da moldura.
  ///
  /// Sangra para não haver emenda entre o verde e a madeira. Só metade, e não
  /// a borda inteira, porque a face externa das arestas do painel tem 5
  /// colunas transparentes — 20 unidades em escala 4 —, e a paisagem levada
  /// até lá reaparecia **por fora** da moldura, numa faixa verde encostada no
  /// letterbox.
  static Rect scenarioRect() => frameRect().deflate(UiScale.frameBorder / 2);

  /// Onde a porta cobre: o vão, invadindo o batente só o suficiente para a
  /// borda dela ficar escondida sob a madeira.
  static Rect doorRect() => Rect.fromLTWH(
        GameLayout.boardVoidLeft - UiScale.doorOverlap,
        GameLayout.boardVoidTop - UiScale.doorOverlap,
        GameLayout.boardVoidWidth + UiScale.doorOverlap * 2,
        GameLayout.boardVoidHeight + UiScale.doorOverlap * 2,
      );

  @override
  void render(Canvas canvas) {
    game.elements.panels.render(
      canvas,
      family,
      frameRect(),
      fillCenter: false,
    );
  }
}
