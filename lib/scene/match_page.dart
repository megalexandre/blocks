import 'package:flame/components.dart';

import '../dressing/game_sounds.dart';

import 'board_component.dart';
import 'boost_component.dart';
import 'game_over_component.dart';
import 'game_scene.dart';
import 'gate_component.dart';
import 'hud_component.dart';
import 'scenario_component.dart';
import 'wall_component.dart';

/// A partida: o tabuleiro e tudo que o cerca.
///
/// Dona do **momento** da partida, que a camada de regra não conhece: esperando
/// com a porta fechada, ou jogando. A derrota não vira um terceiro momento —
/// quem sabe dela é `playfield.isOver`, e ter duas respostas para a mesma
/// pergunta é ter duas que um dia discordam.
class MatchPage extends PositionComponent with HasGameReference<GameScene> {
  late BoardComponent _board;
  late WallComponent _wall;

  /// A pilha já foi solta nesta partida.
  bool _started = false;

  /// Quanto falta da contagem regressiva, em segundos. Zero quando ela não
  /// está correndo.
  double _countdown = 0;

  /// O cenário pediu para entrar com a pilha segurada.
  ///
  /// Guardado antes de a porta segurá-la, porque as duas coisas usam o mesmo
  /// `risePaused`: sem isto, a contagem regressiva soltava a pilha de um
  /// cenário montado justamente para ser examinado parado.
  bool _heldByScenario = false;

  /// O valor de `isOver` no quadro anterior, para pegar a virada.
  ///
  /// Comparar estado em vez de ouvir o evento `ToppedOut` porque os eventos são
  /// consumidos dentro do `BoardComponent.update` e hoje só chegam ao som;
  /// encaminhá-los daqui exigiria mudar a assinatura do componente. Ouvir o
  /// evento é o caminho mais certo, e vale trocar quando alguém precisar de
  /// outro evento aqui.
  bool _wasOver = false;

  @override
  Future<void> onLoad() async {
    _board = BoardComponent(playfield: game.playfield, elements: game.elements);
    _wall = WallComponent(onOpen: _startMatch);
    // A ordem da lista não manda; quem manda é o `priority` de cada um. De trás
    // para frente: paisagem (−10), tabuleiro (0), porta (4), moldura (5),
    // faixas e placar (10), fim de jogo (20).
    await addAll([
      ScenarioComponent(),
      _board,
      _wall,
      GateComponent(),
      ...boostBands(),
      HudComponent(),
      GameOverComponent(),
    ]);
    // A pilha fica segurada enquanto a porta cobre. `risePaused` já existe e já
    // é documentado como "segurada de fora" — a camada de regra não precisa
    // saber que existe uma porta.
    _heldByScenario = game.playfield.risePaused;
    game.playfield.risePaused = true;
  }

  /// Abre a porta e começa a contagem regressiva.
  ///
  /// A ordem é o ponto: a contagem toca **antes** de a partida começar, que é
  /// para o que ela serve — tocada depois do início, ela não conta nada. A
  /// porta desce junto com ela, então o jogador passa os segundos da contagem
  /// olhando o tabuleiro parado, decidindo a primeira jogada.
  ///
  /// A pilha é solta quando a contagem acaba, e não quando a porta termina de
  /// sair: a porta leva 0,6 s e a contagem quase quatro.
  void _startMatch() {
    if (_started) {
      return;
    }
    _started = true;
    // Não é evento do jogo: a camada de regra não sabe que existe porta nem
    // contagem.
    GameSounds.instance.play(GameSound.matchStart);
    _countdown = GameSound.matchStart.seconds;
    _wall.revealBoard();
  }

  /// Joga fora a partida perdida e monta outra.
  ///
  /// O tabuleiro é recriado porque ele e o pintor recebem o jogo no construtor.
  /// O placar e o painel de fim de jogo não: eles perguntam à cena a cada
  /// quadro, e por isso atravessam o recomeço sem saber que houve um.
  ///
  /// A porta quebra essa simetria: ela tem **posição**, que é estado
  /// atravessando a partida. Sem recolocá-la, jogar de novo abriria com o
  /// tabuleiro à mostra e a pilha parada.
  Future<void> restart() async {
    game.renewPlayfield();
    _board.removeFromParent();
    _board = BoardComponent(playfield: game.playfield, elements: game.elements);
    await add(_board);
    game.playfield.risePaused = true;
    _started = false;
    _wasOver = false;
    _countdown = 0;
    _wall.resetCovering();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_countdown > 0) {
      _countdown -= dt;
      if (_countdown <= 0) {
        _countdown = 0;
        game.playfield.risePaused = _heldByScenario;
      }
    }
    if (game.playfield.isOver && !_wasOver) {
      _wall.hideBoard();
    }
    _wasOver = game.playfield.isOver;
  }
}
