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
  GravitySystem({required this.grid, this.stepSeconds = defaultStepSeconds});

  /// Um bloco sem apoio desce uma linha a cada tanto.
  static const double defaultStepSeconds = 0.025;

  final BlockGrid grid;
  final double stepSeconds;

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

  /// Ainda tem coisa se mexendo: bloco que vai cair, ou rastro derretendo.
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
    var landed = 0;
    for (final row in grid.geometry.rowsBottomUp) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block == null) {
          continue;
        }
        final canFall = block.isIdle && grid.blockAt(row.below, col) == null;
        if (!canFall) {
          if (_moving.contains(block)) {
            landed++;
          }
          continue;
        }
        grid.move(from: (row: row, col: col), to: (row: row.below, col: col));
        block.fallOffset += 1;
        movedNow.add(block);
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
