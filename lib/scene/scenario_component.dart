import 'dart:ui';

import 'package:flame/components.dart';

import 'game_scene.dart';
import 'gate_component.dart';

/// A paisagem, no retângulo da moldura — e não no do tabuleiro.
///
/// Ela passa **por baixo** do batente: assim não existe emenda entre o verde e
/// a madeira, e a moldura apoia sobre a paisagem como um caixilho sobre a
/// janela.
///
/// Componente próprio, e não mais uma linha do `BoardPainter`, porque lá ela
/// era desenhada depois do `clipRRect` do tabuleiro e não tinha como passar
/// dos 768×1536 por construção. O recorte existia para a paisagem herdar os
/// cantos arredondados do painel; com a moldura por cima, esses cantos não
/// aparecem mais.
class ScenarioComponent extends PositionComponent
    with HasGameReference<GameScene> {
  /// Negativa porque o `BoardComponent` não declara prioridade nenhuma e fica
  /// no padrão, que é zero — e a paisagem tem que ficar atrás dele. Subir a do
  /// tabuleiro em vez de baixar esta obrigaria a mexer em quatro componentes
  /// que hoje só sabem ser 10 e 20.
  ScenarioComponent() : super(priority: -10);

  @override
  void render(Canvas canvas) {
    game.elements.scenario.render(canvas, GateComponent.scenarioRect());
  }
}
