import '../model/block.dart';
import '../model/block_grid.dart';
import '../model/cell.dart';
import '../color_runs.dart';
import '../game_event.dart';
import '../match_timings.dart';

/// Encontra combinações de 3+ e conduz cada bloco por piscar → estourar →
/// sair da grade. Não sabe nada de pixels: o tabuleiro lê o estado do bloco
/// para decidir como desenhar.
class MatchSystem {
  MatchSystem({required this.grid, this.timings = MatchTimings.standard});

  final BlockGrid grid;

  /// Piscar, estourar e o atraso da cascata. Value object porque quem
  /// desenha precisa dos mesmos números, e importava esta classe inteira só
  /// para ler uma constante dela.
  final MatchTimings timings;

  /// Só bloco parado e apoiado combina — o leitor de [ColorRuns] que carrega
  /// essa regra. Contar a sequência em si não é assunto daqui: é o mesmo
  /// conceito que o veto do carteador usa, e ele tem um dono só.
  late final ColorRuns _runs = ColorRuns.matchable(grid);

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

  /// Um quadro de combinação. [isSettling] responde "a pilha ainda está se
  /// acomodando", e vem de fora porque quem sabe disso é a gravidade.
  ///
  /// Injetado na chamada, e não guardado como colaborador: este sistema
  /// precisa da gravidade só para essa pergunta, e quem conduz o quadro já
  /// tem os dois na mão. Guardar um dentro do outro amarraria dois sistemas
  /// para responder um bit.
  ///
  /// **Função, e não `bool`.** A resposta só vale depois de [_advance] tirar
  /// da grade os blocos que terminaram de estourar: é exatamente no quadro em
  /// que o último bloco de uma combinação some que o bloco de cima fica sem
  /// apoio. Recebendo um `bool` calculado antes disso, a pilha parecia
  /// parada, nada estava resolvendo, e a chain era zerada justo no instante
  /// que [_chainActive] existe para atravessar — a combinação seguinte
  /// entrava como chain 1 em vez de 2.
  /// Quem soma pontos ouve o evento em vez de espiar [comboSize] a cada
  /// quadro: os dois campos ficam parados por vários quadros enquanto a
  /// combinação pisca e estoura, e um placar que somasse por quadro contaria
  /// a mesma combinação dezenas de vezes.
  void update(
    double dt, {
    required bool Function() isSettling,
    required EmitEvent emit,
  }) {
    _advance(dt);
    final matchedNow = _detect();
    if (matchedNow > 0) {
      _comboSize = matchedNow;
      _chainLevel = _chainActive ? _chainLevel + 1 : 1;
      _chainActive = true;
      emit(MatchCleared(comboSize: _comboSize, chainLevel: _chainLevel));
    }
    _resolving = _anyResolving();
    if (!_resolving && !isSettling()) {
      if (_chainActive) {
        emit(ChainEnded(length: _chainLevel));
      }
      _chainActive = false;
      _comboSize = 0;
      _chainLevel = 0;
    }
  }

  bool _anyResolving() {
    for (final row in grid.geometry.playableRows) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block != null && !block.isIdle) {
          return true;
        }
      }
    }
    return false;
  }

  void _advance(double dt) {
    for (final row in grid.geometry.playableRows) {
      for (final col in grid.geometry.columns) {
        final block = grid.blockAt(row, col);
        if (block == null || block.isIdle) {
          continue;
        }
        block.stateTime += dt;
        switch (block.state) {
          case BlockState.matched:
            if (block.stateTime >= timings.flash) {
              block.enter(BlockState.popping);
            }
          case BlockState.popping:
            if (block.stateTime >= block.clearAt) {
              grid.clear(row, col);
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
    final matched = _runs.matchedCells();
    if (matched.isEmpty) {
      return 0;
    }

    final order = matched.toList()..sort(cascadeOrder);
    // O grupo inteiro sai quando o último terminar de encolher: a cascata é
    // só visual, e a pilha de cima espera o buraco ficar pronto por completo.
    final clearAt = (order.length - 1) * timings.stagger + timings.pop;
    for (var i = 0; i < order.length; i++) {
      grid.blockAt(order[i].row, order[i].col)!
        ..enter(BlockState.matched)
        ..popDelay = i * timings.stagger
        ..clearAt = clearAt;
    }
    return order.length;
  }
}
