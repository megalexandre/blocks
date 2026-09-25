import 'dart:math' as math;

import '../game_event.dart';
import '../model/block.dart';
import '../model/block_grid.dart';

/// A queda inteira: o ritmo, o acumulador, o passo e o rastro.
///
/// Dono dos dois lados do movimento, exatamente como o `StackRaiser` — o
/// projeto já tinha essa decisão escrita para a subida, mas a queda fazia o
/// contrário: a taxa vivia numa constante da grade e o acumulador num campo
/// de um componente do Flame. Duas classes de camadas diferentes decidindo um
/// movimento só, sem nada garantindo que concordassem.
class GravitySystem {
  GravitySystem({
    required this.grid,
    this.stepSeconds = defaultStepSeconds,
    this.hoverSeconds = defaultHoverSeconds,
  });

  /// Um bloco sem apoio desce uma linha a cada tanto.
  static const double defaultStepSeconds = 0.025;

  /// Quanto tempo o bloco fica suspenso no ar antes de começar a descer.
  ///
  /// Os 12 quadros a 60 fps do original no nível 1 — a tabela de lá vai de 12
  /// até 3 quadros conforme a dificuldade sobe, junto com o pisca e o
  /// estouro. Se este projeto ganhar níveis, os quatro números escalam
  /// juntos, e não este sozinho.
  static const double defaultHoverSeconds = 0.2;

  final BlockGrid grid;
  final double stepSeconds;
  final double hoverSeconds;

  /// A suspensão em passos de queda, que é a unidade em que ela é gasta.
  /// Convertida uma vez: os segundos existem para quem ajusta, os passos
  /// para quem conta.
  late final int _hoverSteps = (hoverSeconds / stepSeconds).round();

  double _timer = 0;

  /// Quem desceu no último passo.
  ///
  /// É o que permite saber quando um bloco **pousa**: ele estava aqui e, no
  /// passo seguinte, não conseguiu descer. Por identidade, e não por
  /// igualdade: o que interessa é aquele bloco, não um bloco da mesma cor.
  var _moving = Set<Block>.identity();

  /// Um quadro de queda: quantos passos couberem no [dt], e depois o rastro
  /// derrete por esse mesmo [dt].
  ///
  /// A ordem importa e é a que sempre foi: **todos os passos primeiro, o
  /// derretimento uma vez no fim**. Invertendo, um bloco ganharia +1 de
  /// rastro e perderia o `dt` inteiro dentro do mesmo quadro, e o movimento
  /// mudaria de cara.
  ///
  /// [emit] é opcional porque os pousos são uma saída a mais, não parte da
  /// mecânica: quem só quer ver a queda acontecer não precisa ouvi-la.
  void update(double dt, {EmitEvent emit = _discard}) {
    _timer += dt;
    var landed = 0;
    while (_timer >= stepSeconds) {
      _timer -= stepSeconds;
      landed += _applyStep();
    }
    _easeTrails(dt);
    if (landed > 0) {
      emit(BlocksLanded(count: landed));
    }
  }

  static void _discard(GameEvent event) {}

  /// Ainda tem coisa se mexendo: bloco que vai cair, bloco suspenso, ou
  /// rastro derretendo.
  ///
  /// O suspenso entra sem cláusula nova: ele está parado com a célula de
  /// baixo vazia, que é exatamente o que "vai cair" já perguntava. E é isso
  /// que mantém a janela da chain aberta durante a suspensão — sem essa
  /// resposta, a pausa que o jogador ganha para armar o elo seguinte fecharia
  /// a chain em vez de segurá-la.
  ///
  /// **Um predicado só.** Havia quatro definições de "caindo" espalhadas, e
  /// nenhuma concordava com as outras: o passo da gravidade exigia bloco
  /// parado para descer, mas quem perguntava "tem bloco caindo?" não exigia
  /// nada — um bloco estourando sobre um buraco contava como caindo e
  /// congelava a pilha sem nunca cair. Na outra ponta, um bloco que já mudou
  /// de célula mas ainda tem rastro não contava, e a pilha voltava a subir
  /// com os blocos visivelmente deslizando. Agora a mesma pergunta responde
  /// às duas coisas, e ela custa o que custava: uma varredura por quadro.
  bool get isSettling {
    for (final row in grid.geometry.rowsBottomUp) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block == null) {
          continue;
        }
        if (block.fallOffset > 0) {
          return true;
        }
        if (block.isIdle && grid.blockAt(row.below, col) == null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Desce em uma linha todo bloco que não tem apoio, e devolve quantos
  /// pousaram. Bloco piscando ou estourando não cai: ele já está em resolução.
  ///
  /// Quem acaba de perder o apoio não desce neste passo: fica **suspenso** e
  /// gasta um passo da própria suspensão. A coluna inteira, porém, cai de uma
  /// vez — quem está acima de um bloco que já se moveu neste passo herda a
  /// queda em vez de estrear uma suspensão sua. Sem isso a coluna desceria em
  /// degraus, uma suspensão por bloco, e a pilha derreteria em escada.
  ///
  /// Pousar é **ter descido no passo anterior e não descer neste**, seja qual
  /// for o motivo. Não basta olhar só para "achou apoio": um bloco que cai e
  /// fecha uma combinação já está piscando no passo seguinte, e com um filtro
  /// de bloco parado ele nunca contaria como pousado — justamente o impacto
  /// que abre uma chain.
  ///
  /// Contado um passo depois da chegada, e não no passo em que o bloco entra
  /// na célula final. Isso é o que casa com a tela: ele chega com um rastro
  /// de uma linha inteira, e esse rastro leva exatamente um passo para
  /// derreter — o toque no chão que o jogador vê é agora.
  int _applyStep() {
    final movedNow = Set<Block>.identity();
    // Colunas onde alguma coisa já desceu neste passo. A varredura vem do
    // piso para o topo, então quem encontra a marca está por cima de quem a
    // deixou — e cai junto.
    final falling = List<bool>.filled(grid.geometry.columnCount, false);
    var landed = 0;
    for (final row in grid.geometry.rowsBottomUp) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block == null) {
          continue;
        }
        final loose = block.isIdle && grid.blockAt(row.below, col) == null;
        if (!loose) {
          if (_moving.contains(block)) {
            landed++;
          }
          // Tem apoio: a suspensão morre aqui. É o que faz o bloco deslizado
          // por baixo segurar de verdade quem estava no ar, em vez de o
          // suspenso cair por cima dele um instante depois.
          block.hoverSteps = 0;
          continue;
        }
        if (!falling[col.value] && !_moving.contains(block)) {
          // Arma no passo em que o vão aparece, e só gasta a partir do
          // seguinte: assim a espera dura os passos pedidos inteiros, em vez
          // de perder um deles para a própria armação.
          if (block.hoverSteps == 0) {
            block.hoverSteps = _hoverSteps;
          } else {
            block.hoverSteps--;
          }
          if (block.hoverSteps > 0) {
            continue;
          }
        }
        grid.move(from: (row: row, col: col), to: (row: row.below, col: col));
        // Quem herdou a queda da coluna pode ter sobrado com suspensão no
        // contador. Zerar aqui mantém o campo honesto: caindo não é suspenso.
        block.hoverSteps = 0;
        block.fallOffset += 1;
        movedNow.add(block);
        falling[col.value] = true;
      }
    }
    // Trocado inteiro a cada passo: um bloco que saiu da grade no meio da
    // queda simplesmente não aparece mais aqui, em vez de ficar preso.
    _moving = movedNow;
    return landed;
  }

  /// Derrete o rastro de quem acabou de cair uma linha. A taxa é o próprio
  /// [stepSeconds]: um bloco caindo várias linhas seguidas ganha +1 de rastro
  /// a cada passo e perde esse mesmo tanto antes do próximo, então o
  /// movimento sai contínuo em vez de picotado — com dois números distintos o
  /// rastro ia se acumular ou sumir rápido demais.
  ///
  /// Fica aqui junto de quem soma: o rastro tem um dono só, em vez de ser
  /// somado num lugar e derretido em outro.
  void _easeTrails(double dt) {
    final decay = dt / stepSeconds;
    for (final row in grid.geometry.allRows) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block != null && block.fallOffset > 0) {
          block.fallOffset = math.max(0, block.fallOffset - decay);
        }
      }
    }
  }
}
