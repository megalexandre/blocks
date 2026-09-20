import 'block_sprites.dart';
import 'scenario_background.dart';
import 'selector.dart';

class FactoryElements {
  FactoryElements._({
    required this.blocks,
    required this.selector,
    required this.scenario,
  });

  /// Carrega tudo e devolve os elementos prontos.
  static Future<FactoryElements> load() async {
    final blocks = BlockSprites();
    final selector = Selector();
    final scenario = ScenarioBackground();
    await blocks.load();
    await selector.load();
    await scenario.load();
    return FactoryElements._(
      blocks: blocks,
      selector: selector,
      scenario: scenario,
    );
  }

  final BlockSprites blocks;

  final Selector selector;

  /// A paisagem atrás dos blocos.
  final ScenarioBackground scenario;
}
