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

  /// Verdadeiro enquanto existe bloco piscando ou estourando.
  bool get isResolving => _resolving;

  bool _resolving = false;

  /// Quantos blocos saíram juntos na última combinação encontrada. Volta a 0
  /// quando a pilha assenta ociosa, sem nada piscando, estourando ou caindo.
  int get comboSize => _comboSize;

  /// Nível da chain atual: 1 na primeira combinação depois da pilha ficar
  /// ociosa, e sobe uma a cada combinação nova que aparece antes da pilha
  /// assentar de novo — o caso em que blocos caindo de uma combinação anterior
  /// fecham outra. Volta a 0 quando a pilha assenta ociosa.
  int get chainLevel => _chainLevel;

  int _comboSize = 0;
  int _chainLevel = 0;

  /// Verdadeiro desde a primeira combinação da chain até a pilha assentar
  /// ociosa de novo. Precisa ser um flag que persiste entre frames — no frame
  /// em que o último bloco de uma queda pousa e fecha a combinação seguinte,
  /// ele já não está mais caindo nem nada está piscando, então checar só o
  /// estado do frame atual perderia a chain nesse instante exato.
  bool _chainActive = false;

  /// Avisado a cada combinação nova, com o tamanho do grupo e o nível da
  /// chain. Quem soma pontos ouve aqui em vez de espiar [comboSize] a cada
  /// frame — os dois campos ficam parados por vários frames enquanto a
  /// combinação pisca e estoura, e um placar que somasse por frame contaria a
  /// mesma combinação várias vezes.
  void Function(int comboSize, int chainLevel)? onMatch;

  void update(double dt) {
    _advance(dt);
    final matchedNow = _detect();
    if (matchedNow > 0) {
      _comboSize = matchedNow;
      _chainLevel = _chainActive ? _chainLevel + 1 : 1;
      _chainActive = true;
      onMatch?.call(_comboSize, _chainLevel);
    }
    _resolving = _anyResolving();
    if (!_resolving && !grid.hasFallingBlocks) {
      _chainActive = false;
      _comboSize = 0;
      _chainLevel = 0;
    }
  }

  bool _anyResolving() {
    for (var index = 0; index < grid.incomingIndex; index++) {
      for (var col = 0; col < grid.columns; col++) {
        final block = grid.atIndex(index, col);
        if (block != null && !block.isIdle) {
          return true;
        }
      }
    }
    return false;
  }

  void _advance(double dt) {
    for (var index = 0; index < grid.incomingIndex; index++) {
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

  /// Marca em [BlockState.matched] toda combinação nova encontrada agora, e
  /// devolve quantos blocos entraram nela (0 se não achou nenhuma).
  int _detect() {
    final matched = <Cell>{};
    for (var index = 0; index < grid.incomingIndex; index++) {
      _collectRun(matched, index, 0, 0, 1);
    }
    for (var col = 0; col < grid.columns; col++) {
      _collectRun(matched, 0, col, 1, 0);
    }
    if (matched.isEmpty) {
      return 0;
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
    return ordem.length;
  }

  /// Caminha a partir de (index, col) no sentido [stepIndex], [stepCol] e
  /// guarda em [matched] toda sequência de [BlockGrid.matchLength] ou mais da
  /// mesma cor.
  void _collectRun(Set<Cell> matched, int index, int col, int stepIndex, int stepCol) {
    final limite = stepCol != 0 ? grid.columns : grid.incomingIndex;
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
