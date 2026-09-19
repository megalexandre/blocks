import 'dart:math' as math;

import 'block.dart';
import 'block_grid.dart';

/// Direção de varredura na grade: quanto andar em linha e em coluna por passo.
typedef GridStep = ({int index, int col});

const GridStep _horizontal = (index: 0, col: 1);
const GridStep _vertical = (index: 1, col: 0);

/// O carteador: decide **o que** entra em cada célula — a altura de cada
/// coluna na pilha de abertura e a cor de cada bloco.
///
/// Só responde, nunca escreve: quem põe o bloco na célula continua sendo o
/// [BlockGrid], então a grade segue dona exclusiva do próprio estado. Em
/// troca, o carteador é dono exclusivo do acaso — todo `Random` do jogo está
/// aqui, e é por isso que um teste que precise de tabuleiro previsível usa
/// [BlockGrid.empty] e monta as células na mão, sem passar por aqui.
class BlockDealer {
  BlockDealer(this._grid);

  /// Lido para enxergar os vizinhos já postos antes de escolher uma cor.
  final BlockGrid _grid;

  /// Altura da pilha inicial, em linhas, sorteada por coluna.
  static const int minStartHeight = 3;
  static const int maxStartHeight = 6;

  final _random = math.Random();

  /// Quantas linhas cada coluna recebe na pilha de abertura. Sorteadas por
  /// coluna para o tabuleiro não começar com o topo reto.
  List<int> startHeights() =>
      List.generate(_grid.columns, (_) => _randomStartHeight());

  /// Sorteia uma cor que não feche uma combinação de saída. Sem isso o
  /// tabuleiro estouraria sozinho no primeiro frame, e cada linha nova
  /// entraria já estourando.
  ///
  /// Depende de a grade ser preenchida em ordem — os vizinhos que já estão
  /// postos são os que vetam cor. Preencher fora de ordem não quebra nada,
  /// só deixa passar combinação que este veto teria evitado.
  BlockColor colorFor(int index, int col) {
    final candidates = BlockColor.values
        .where((color) => !_wouldMatch(index, col, color))
        .toList();
    // Horizontal e vertical bloqueiam no máximo duas cores cada, então com
    // cinco cores sempre sobra alguma. Cortar o enum para quatro põe este
    // assert em risco.
    assert(candidates.isNotEmpty, 'nenhuma cor livre em ($index, $col)');
    return candidates[_random.nextInt(candidates.length)];
  }

  int _randomStartHeight() =>
      minStartHeight + _random.nextInt(maxStartHeight - minStartHeight + 1);

  bool _wouldMatch(int index, int col, BlockColor color) =>
      _runThrough(index, col, color, _horizontal) >= BlockGrid.matchLength ||
      _runThrough(index, col, color, _vertical) >= BlockGrid.matchLength;

  /// Tamanho da sequência de [color] que passaria por (index, col) na direção
  /// [step]. Soma os dois lados mais o próprio bloco que está sendo colocado —
  /// por isso independe da ordem em que a grade é preenchida. Checar um lado
  /// de cada vez deixaria passar o bloco colocado entre dois iguais.
  int _runThrough(int index, int col, BlockColor color, GridStep step) {
    final before = _sameRun(index, col, color, (
      index: -step.index,
      col: -step.col,
    ));
    final after = _sameRun(index, col, color, step);
    return before + 1 + after;
  }

  /// Quantos blocos da cor [color] existem em sequência a partir de
  /// (index, col), sem contar ele próprio, andando de [step] em [step].
  int _sameRun(int index, int col, BlockColor color, GridStep step) {
    var total = 0;
    var i = index + step.index;
    var c = col + step.col;
    while (i >= 0 && i < _grid.rowCount && c >= 0 && c < _grid.columns) {
      if (_grid.atIndex(i, c)?.color != color) {
        break;
      }
      total++;
      i += step.index;
      c += step.col;
    }
    return total;
  }
}
