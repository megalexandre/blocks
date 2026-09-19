import 'dart:math' as math;

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

  /// Um quadro de queda: quantos passos couberem no [dt], e depois o rastro
  /// derrete por esse mesmo [dt].
  ///
  /// A ordem importa e é a que sempre foi: **todos os passos primeiro, o
  /// derretimento uma vez no fim**. Invertendo, um bloco ganharia +1 de
  /// rastro e perderia o `dt` inteiro dentro do mesmo quadro, e o movimento
  /// mudaria de cara.
  void update(double dt) {
    _timer += dt;
    while (_timer >= stepSeconds) {
      _timer -= stepSeconds;
      _applyStep();
    }
    _easeTrails(dt);
  }

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

  /// Desce em uma linha todo bloco que não tem apoio. Bloco piscando ou
  /// estourando não cai: ele já está em resolução.
  void _applyStep() {
    for (final row in grid.geometry.rowsBottomUp) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block == null || !block.isIdle) {
          continue;
        }
        if (grid.blockAt(row.below, col) != null) {
          continue;
        }
        grid.move(from: (row: row, col: col), to: (row: row.below, col: col));
        block.fallOffset += 1;
      }
    }
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
