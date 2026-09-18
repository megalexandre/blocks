import 'block_sprites.dart';
import 'selector.dart';

class FactoryElements {
  FactoryElements._({required this.blocks, required this.selector});

  /// Carrega tudo e devolve os elementos prontos.
  static Future<FactoryElements> load() async {
    final blocks = BlockSprites();
    final selector = Selector();
    await blocks.load();
    await selector.load();
    return FactoryElements._(blocks: blocks, selector: selector);
  }

  final BlockSprites blocks;

  final Selector selector;
}
