import 'bitmap_font.dart';
import 'bitmap_text.dart';
import 'block_sprites.dart';
import 'icon_sprites.dart';
import 'panel_sprites.dart';
import 'scenario_background.dart';
import 'selector.dart';

/// Quantos carregamentos já terminaram, de um total.
typedef LoadProgress = void Function(int done, int total);

/// Tudo que se desenha, carregado em **duas etapas**.
///
/// A divisão existe por causa da tela de carregamento: ela precisa das folhas
/// de interface para se desenhar, e não pode esperar as do jogo — que são
/// justamente o que ela está esperando. Então a interface entra antes, a tela
/// aparece, e o resto carrega por trás dela.
class FactoryElements {
  /// Os painéis de madeira, tijolo e papel.
  final PanelSprites panels = PanelSprites();

  /// A fonte de manchete: título, placar.
  final BitmapText headline = BitmapText(BitmapFont.grande);

  /// A fonte de rótulo. É de uma cor só, então quase sempre sai tingida.
  final BitmapText label = BitmapText(BitmapFont.pequena);

  final IconSprites icons = IconSprites();

  final BlockSprites blocks = BlockSprites();

  final Selector selector = Selector();

  /// A paisagem atrás dos blocos.
  final ScenarioBackground scenario = ScenarioBackground();

  bool _gameReady = false;

  /// As folhas do jogo já estão na memória.
  bool get isGameReady => _gameReady;

  /// Primeira etapa: só o que a tela de carregamento desenha. São poucos
  /// quilobytes — um ou dois quadros.
  Future<void> loadInterface() async {
    await panels.load();
    await headline.load();
    await label.load();
    await icons.load();
  }

  /// Segunda etapa: as folhas do jogo.
  ///
  /// Um passo de cada vez, e não `Future.wait`, porque o que interessa aqui é
  /// **contar**: a tela de carregamento desenha essa fração, e em paralelo os
  /// passos terminariam fora de ordem e a barra andaria aos pulos.
  Future<void> loadGame({LoadProgress? onProgress}) async {
    final passos = <Future<void> Function()>[
      blocks.load,
      selector.load,
      scenario.load,
    ];
    for (var i = 0; i < passos.length; i++) {
      await passos[i]();
      onProgress?.call(i + 1, passos.length);
    }
    _gameReady = true;
  }
}
