import '../game/board_script.dart';
import '../game/model/board_geometry.dart';
import '../game/playfield.dart';
import '../game/rules/random_dealer.dart';
import '../game/rules/stack_raiser.dart';

/// Uma situação de jogo montada de antemão, para entrar direto nela.
///
/// Existe porque a única forma de chegar a uma chain de nível 3, a um combo
/// grande ou à pilha encostando no topo era jogar até acontecer — o que torna
/// caro verificar a olho justamente as regras mais delicadas.
///
/// É código de desenvolvimento: nada fora de `main_dev.dart` importa esta
/// pasta, e ela não entra no aplicativo publicado.
class Scenario {
  const Scenario({
    required this.name,
    required this.purpose,
    this.board,
    this.seed = 1,
    this.riseRowsPerSecond,
    this.risePaused = false,
  });

  /// Como aparece no menu.
  final String name;

  /// Para que serve — o que se deve olhar ao entrar nele.
  final String purpose;

  /// O tabuleiro montado. Nulo significa a pilha de abertura normal, ou seja,
  /// uma partida de verdade.
  final BoardScript? board;

  /// A semente do carteador. Fixa por padrão: dois cenários iguais têm que
  /// dar o mesmo tabuleiro, ou não servem para comparar.
  final int seed;

  /// Velocidade da subida. Nulo mantém a do jogo.
  final double? riseRowsPerSecond;

  /// Entrar com a pilha já segurada, para tabuleiros que se quer examinar
  /// parados.
  final bool risePaused;

  /// Monta o jogo deste cenário, do zero.
  ///
  /// Chamado de novo a cada recarga, e é por isso que ele constrói tudo em
  /// vez de guardar um [Playfield] pronto: um cenário é uma receita, não uma
  /// partida em andamento.
  Playfield build() {
    final playfield = Playfield(
      geometry: BoardGeometry.standard,
      dealer: RandomDealer.seeded(seed),
      raiser: StackRaiser(
        baseRowsPerSecond:
            riseRowsPerSecond ?? StackRaiser.defaultBaseRowsPerSecond,
      ),
    );
    // Depois de construído: o construtor reparte a pilha de abertura, e o
    // desenho do cenário substitui o que ele pôs nas linhas jogáveis. A linha
    // de entrada, que o desenho não toca, continua sendo o piso repartido.
    board?.paintOn(playfield.grid);
    playfield.risePaused = risePaused;
    return playfield;
  }
}
