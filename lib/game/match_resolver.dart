import 'block.dart';
import 'block_grid.dart';

typedef Cell = ({int index, int col});

/// Encontra combinações de 3+ e conduz cada bloco por piscar → estourar →
/// sair da grade. Não sabe nada de pixels: o tabuleiro lê o estado do bloco
/// para decidir como desenhar.
class MatchResolver {
  MatchResolver({required this.grid});

  final BlockGrid grid;

  /// Quanto tempo o grupo pisca antes de começar a estourar.
  static const double flashDuration = 0.5;

  /// Quanto dura o estouro de um bloco.
  static const double popDuration = 0.12;

  /// Atraso entre um bloco e o seguinte, para o grupo sair em cascata.
  static const double popStagger = 0.05;

  void update(double dt) {
    _advance(dt);
    _detect();
  }

  void _advance(double dt) {
    // A última linha é a que está entrando por baixo e fica inerte.
    for (var index = 0; index < grid.rowCount - 1; index++) {
      for (var col = 0; col < grid.columns; col++) {
        final block = grid.atIndex(index, col);
        if (block == null || block.isIdle) {
          continue;
        }
        block.stateTime += dt;
        switch (block.state) {
          case BlockState.matched:
            if (block.stateTime >= flashDuration) {
              block.enter(BlockState.popping);
            }
          case BlockState.popping:
            if (block.stateTime >= block.popDelay + popDuration) {
              grid.remove(index, col);
            }
          case BlockState.idle:
            break;
        }
      }
    }
  }

  void _detect() {
    final matched = <Cell>{};
    for (var index = 0; index < grid.rowCount - 1; index++) {
      _collectRun(matched, index, 0, 0, 1);
    }
    for (var col = 0; col < grid.columns; col++) {
      _collectRun(matched, 0, col, 1, 0);
    }
    if (matched.isEmpty) {
      return;
    }

    // Cascata da esquerda para a direita, de baixo para cima.
    final ordem = matched.toList()
      ..sort((a, b) {
        final porColuna = a.col.compareTo(b.col);
        return porColuna != 0 ? porColuna : b.index.compareTo(a.index);
      });
    for (var i = 0; i < ordem.length; i++) {
      final block = grid.atIndex(ordem[i].index, ordem[i].col)!;
      block.enter(BlockState.matched);
      block.popDelay = i * popStagger;
    }
  }

  /// Caminha a partir de (index, col) no sentido [stepIndex], [stepCol] e
  /// guarda em [matched] toda sequência de [BlockGrid.matchLength] ou mais da
  /// mesma cor.
  void _collectRun(Set<Cell> matched, int index, int col, int stepIndex, int stepCol) {
    final limite = stepCol != 0 ? grid.columns : grid.rowCount - 1;
    var inicio = 0;
    BlockColor? corAtual;

    for (var passo = 0; passo <= limite; passo++) {
      final i = index + stepIndex * passo;
      final c = col + stepCol * passo;
      final cor = passo < limite ? _matchableColor(i, c) : null;

      if (cor != corAtual) {
        if (corAtual != null && passo - inicio >= BlockGrid.matchLength) {
          for (var k = inicio; k < passo; k++) {
            matched.add((
              index: index + stepIndex * k,
              col: col + stepCol * k,
            ));
          }
        }
        corAtual = cor;
        inicio = passo;
      }
    }
  }

  /// Cor do bloco, se ele pode formar combinação agora. Bloco sem apoio está
  /// caindo e não conta — no original combinação só fecha com bloco assentado.
  BlockColor? _matchableColor(int index, int col) {
    final block = grid.atIndex(index, col);
    if (block == null || !block.isIdle) {
      return null;
    }
    return grid.atIndex(index + 1, col) == null ? null : block.color;
  }
}
