import 'bitmap_font.dart';
import 'bitmap_text.dart';
import 'block_sprites.dart';
import 'icon_sprites.dart';
import 'panel_sprites.dart';
import 'scenario_background.dart';
import 'selector.dart';

/// Quantos carregamentos já terminaram, de um total.
typedef LoadProgress = void Function(int done, int total);

class FactoryElements {
  FactoryElements._({
    required this.blocks,
    required this.selector,
    required this.scenario,
    required this.panels,
    required this.headline,
    required this.label,
    required this.icons,
  });

  /// Carrega tudo e devolve os elementos prontos.
  ///
  /// Um passo de cada vez, e não `Future.wait`, porque o que interessa aqui é
  /// **contar**: a tela de carregamento desenha essa fração, e em paralelo os
  /// passos terminariam fora de ordem e a barra andaria aos pulos.
  ///
  /// [onProgress] é opcional porque quem só quer o pacote pronto — o teste, e
  /// o modo de desenvolvimento — não tem barra nenhuma para alimentar.
  static Future<FactoryElements> load({LoadProgress? onProgress}) async {
    final blocks = BlockSprites();
    final selector = Selector();
    final scenario = ScenarioBackground();
    final panels = PanelSprites();
    final headline = BitmapText(BitmapFont.grande);
    final label = BitmapText(BitmapFont.pequena);
    final icons = IconSprites();

    final passos = <Future<void> Function()>[
      blocks.load,
      selector.load,
      scenario.load,
      panels.load,
      headline.load,
      label.load,
      icons.load,
    ];
    for (var i = 0; i < passos.length; i++) {
      await passos[i]();
      onProgress?.call(i + 1, passos.length);
    }

    return FactoryElements._(
      blocks: blocks,
      selector: selector,
      scenario: scenario,
      panels: panels,
      headline: headline,
      label: label,
      icons: icons,
    );
  }

  final BlockSprites blocks;

  final Selector selector;

  /// A paisagem atrás dos blocos.
  final ScenarioBackground scenario;

  /// Os painéis de madeira, tijolo e papel.
  final PanelSprites panels;

  /// A fonte de manchete: título, placar.
  final BitmapText headline;

  /// A fonte de rótulo. É de uma cor só, então quase sempre sai tingida.
  final BitmapText label;

  final IconSprites icons;
}
