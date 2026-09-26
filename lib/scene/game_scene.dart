import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import '../config/layout.dart';
import '../dressing/factory_elements.dart';
import '../game/playfield.dart';
import 'loading_page.dart';
import 'match_page.dart';
import 'menu_page.dart';
import 'routes.dart';

class GameScene extends FlameGame {
  /// Recebe uma **receita** de partida, não uma partida pronta.
  ///
  /// É o que permite recomeçar: perder e jogar de novo é montar outro
  /// [Playfield] do mesmo jeito que o primeiro, e só quem criou a cena sabe
  /// qual jeito é esse — a partida normal, ou um cenário do modo de
  /// desenvolvimento. Guardar o jogo pronto deixaria a cena sem como refazê-lo.
  GameScene({
    Playfield Function()? createPlayfield,
    this.afterLoading = Routes.menu,
  })  : _createPlayfield = createPlayfield ?? Playfield.standard,
        super(camera: _buildCamera());

  final Playfield Function() _createPlayfield;

  /// Para onde o carregamento vai quando termina. O modo de desenvolvimento
  /// pula o menu e cai direto no cenário escolhido lá.
  final String afterLoading;

  /// O jogo desta partida. Troca inteiro a cada [renewPlayfield].
  late Playfield playfield = _createPlayfield();

  final FactoryElements elements = FactoryElements();

  late final RouterComponent router;

  static CameraComponent _buildCamera() {
    final camera = CameraComponent.withFixedResolution(
      width: GameLayout.width,
      height: GameLayout.height,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    return camera;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // Só a interface aqui: este é o intervalo que o `loadingBuilder` do Flutter
    // cobre, e o que se vê nele é fundo chapado. Quanto menos entra aqui, menos
    // tempo a tela fica sem nada.
    await elements.loadInterface();

    // `Route` comum, e **não** `WorldRoute`: esta entra dentro do `world`,
    // então as páginas herdam a transformação da câmera e continuam no espaço
    // fixo 1080×1920. Um roteador filho do `FlameGame` desenharia no canvas
    // cru, e as telas perderiam a resolução fixa, que é a fundação de tudo
    // aqui.
    router = RouterComponent(
      initialRoute: Routes.loading,
      routes: {
        Routes.loading: Route(LoadingPage.new),
        Routes.menu: Route(MenuPage.new),
        Routes.match: Route(MatchPage.new),
      },
    );
    await world.add(router);
  }

  /// Monta uma partida nova. Quem chama é a página, ao recomeçar.
  void renewPlayfield() => playfield = _createPlayfield();

  /// Recomeça a partida em curso.
  ///
  /// Fica aqui, e não na página, porque quem pede é o `GameOverComponent`, que
  /// só conhece a cena — os componentes leem o jogo por `game.playfield` e não
  /// sabem em que página estão montados.
  Future<void> restart() async {
    await router.currentRoute.firstChild<MatchPage>()?.restart();
  }
}
