import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart' show Anchor;
import 'package:flame/game.dart';

import '../dressing/factory_elements.dart';
import '../game/playfield.dart';
import '../config/layout.dart';
import 'board_component.dart';
import 'boost_component.dart';
import 'game_over_component.dart';
import 'gate_component.dart';
import 'hud_component.dart';
import 'scenario_component.dart';
import 'wall_component.dart';

class GameScene extends FlameGame {
  /// Recebe uma **receita** de partida, não uma partida pronta.
  ///
  /// É o que permite recomeçar: perder e jogar de novo é montar outro
  /// [Playfield] do mesmo jeito que o primeiro, e só quem criou a cena sabe
  /// qual jeito é esse — a partida normal, ou um cenário do modo de
  /// desenvolvimento. Guardar o jogo pronto deixaria a cena sem como refazê-lo.
  GameScene({Playfield Function()? createPlayfield})
    : _createPlayfield = createPlayfield ?? Playfield.standard,
      super(camera: _buildCamera());

  final Playfield Function() _createPlayfield;

  /// O jogo desta partida. Troca inteiro a cada [restart].
  late Playfield playfield = _createPlayfield();

  late final FactoryElements elements;
  late BoardComponent board;
  late final WallComponent wall;

  /// A pilha já foi solta nesta partida.
  ///
  /// Dois estados bastam — esperando e jogando. A derrota **não** vira um
  /// terceiro: quem sabe dela é `playfield.isOver`, e duplicar isso aqui seria
  /// criar duas respostas para a mesma pergunta, que um dia discordariam.
  bool _started = false;

  /// O valor de `playfield.isOver` no quadro anterior, para pegar a virada.
  ///
  /// Comparar estado em vez de ouvir o evento `ToppedOut` porque os eventos
  /// são consumidos dentro do `BoardComponent.update` e hoje só chegam ao som;
  /// encaminhá-los daqui exigiria mudar a assinatura do componente. Ouvir o
  /// evento é o caminho mais certo, e vale trocar quando a cena virar rota.
  bool _wasOver = false;

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
    elements = await FactoryElements.load();
    board = BoardComponent(playfield: playfield, elements: elements);
    // A ordem da lista não manda; quem manda é o `priority` de cada um. De
    // trás para frente: paisagem (−10), tabuleiro (0), moldura (5), faixas e
    // placar (10), fim de jogo (20).
    wall = WallComponent();
    await world.addAll([
      ScenarioComponent(),
      board,
      wall,
      GateComponent(),
      ...boostBands(),
      HudComponent(),
      GameOverComponent(),
    ]);
    // A pilha fica segurada enquanto a porta cobre. `risePaused` já existe e
    // já é documentado como "segurada de fora" — a camada de regra não precisa
    // saber que existe uma porta.
    playfield.risePaused = true;
  }

  /// Abre a porta e solta a pilha.
  ///
  /// A pilha só começa a subir quando a porta **terminou** de sair, e não
  /// quando ela começou: com o tabuleiro ainda tapado, a primeira linha subia
  /// sem ninguém ver.
  void startMatch() {
    if (_started) {
      return;
    }
    _started = true;
    wall.revealBoard(onDone: () => playfield.risePaused = false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (playfield.isOver && !_wasOver) {
      wall.hideBoard();
    }
    _wasOver = playfield.isOver;
  }

  /// Joga fora a partida perdida e monta outra.
  ///
  /// O tabuleiro é recriado junto porque ele e o pintor recebem o jogo no
  /// construtor. O placar e o painel de fim de jogo não: eles perguntam à
  /// cena a cada quadro, e por isso atravessam o recomeço sem saber que
  /// houve um.
  /// A porta quebra a simetria do recomeço: ela tem **posição**, que é estado
  /// atravessando a partida. Sem recolocá-la, jogar de novo abriria com o
  /// tabuleiro à mostra e a pilha parada.
  Future<void> restart() async {
    playfield = _createPlayfield();
    board.removeFromParent();
    board = BoardComponent(playfield: playfield, elements: elements);
    await world.add(board);
    playfield.risePaused = true;
    _started = false;
    _wasOver = false;
    wall.resetCovering();
  }
}
