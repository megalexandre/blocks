import '../model/block.dart';
import '../model/block_grid.dart';
import '../model/cell.dart';
import '../model/column.dart';
import '../model/row_index.dart';
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
  /// ociosa, e sobe uma a cada combinação que **um estouro anterior causou** —
  /// isto é, que contém pelo menos um bloco derrubado por ele
  /// ([Block.chainLink]). Volta a 0 quando a pilha assenta ociosa.
  ///
  /// Não basta a combinação aparecer antes da pilha assentar, como valia
  /// antes: o jogador continua jogando durante o estouro, e a trinca que ele
  /// fecha com blocos que ninguém derrubou é combinação nova, não elo. Quando
  /// ela acontece no meio de uma chain, a chain em curso segue com o nível
  /// que tinha — a combinação avulsa é que sai valendo 1.
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
  ///
  /// Quem soma pontos ouve o evento em vez de espiar [comboSize] a cada
  /// quadro: os dois campos ficam parados por vários quadros enquanto a
  /// combinação pisca e estoura, e um placar que somasse por quadro contaria
  /// a mesma combinação dezenas de vezes.
  void update(
    double dt, {
    required bool Function() isSettling,
    required EmitEvent emit,
  }) {
    _advance(dt, emit);
    final match = _detect();
    if (match.size > 0) {
      _comboSize = match.size;
      // Elo, e não combinação qualquer: a chain só sobe quando a combinação
      // nova carrega um bloco que um estouro desta mesma chain derrubou.
      final linked = match.linked && _chainActive;
      final level = linked ? _chainLevel + 1 : 1;
      if (linked || !_chainActive) {
        _chainLevel = level;
      }
      _chainActive = true;
      emit(MatchCleared(comboSize: _comboSize, chainLevel: level));
    }
    _resolving = _anyResolving();
    if (!_resolving && !isSettling()) {
      if (_chainActive) {
        emit(ChainEnded(length: _chainLevel));
        _forgetChainLinks();
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

  /// Leva cada bloco em resolução um passo adiante: quem terminou de piscar
  /// começa a estourar, quem terminou de estourar sai da grade.
  ///
  /// Avisa uma vez quando blocos entram no estouro. O grupo inteiro entra no
  /// mesmo quadro — todos começaram a piscar juntos, com o relógio zerado
  /// junto —, então o aviso sai uma vez por grupo e não uma por bloco.
  void _advance(double dt, EmitEvent emit) {
    var popping = 0;
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
              popping++;
            }
          case BlockState.popping:
            if (block.stateTime >= block.clearAt) {
              grid.clear(row, col);
              _markChainLinksAbove(row, col);
            }
          case BlockState.idle:
            break;
        }
      }
    }
    if (popping > 0) {
      emit(PopStarted(count: popping));
    }
  }

  /// Marca em [BlockState.matched] toda combinação nova encontrada agora.
  ///
  /// `size` é quantos blocos entraram nela (0 se não achou nenhuma), e
  /// `linked` diz se algum deles tinha sido derrubado por um estouro anterior
  /// — a diferença entre um elo da chain e uma combinação que só por acaso
  /// aconteceu enquanto a pilha resolvia.
  ({int size, bool linked}) _detect() {
    final matched = _runs.matchedCells();
    if (matched.isEmpty) {
      return (size: 0, linked: false);
    }

    final order = matched.toList()..sort(cascadeOrder);
    // O grupo inteiro sai quando o último terminar de encolher: a cascata é
    // só visual, e a pilha de cima espera o buraco ficar pronto por completo.
    final clearAt = (order.length - 1) * timings.stagger + timings.pop;
    var linked = false;
    for (var i = 0; i < order.length; i++) {
      final block = grid.blockAt(order[i].row, order[i].col)!
        ..enter(BlockState.matched)
        ..popDelay = i * timings.stagger
        ..clearAt = clearAt;
      linked = linked || block.chainLink;
    }
    return (size: order.length, linked: linked);
  }

  /// Marca como elo todo bloco acima de uma célula que acabou de esvaziar:
  /// são exatamente os que vão cair por causa deste estouro.
  ///
  /// A coluna inteira, e não só a célula de cima — quando um buraco se abre
  /// embaixo, tudo o que está acima dele desce, inclusive o que está separado
  /// por um vão.
  ///
  /// Quem estava no mesmo grupo e por cima já saiu da grade neste quadro,
  /// porque a varredura de [_advance] vai do topo para o piso: ninguém ganha
  /// a marca a caminho de sumir.
  void _markChainLinksAbove(RowIndex row, Column col) {
    for (var above = row.above; above.value >= 0; above = above.above) {
      grid.blockAt(above, col)?.chainLink = true;
    }
  }

  /// Apaga as marcas quando a chain acaba. Uma varredura por chain encerrada,
  /// e não uma por quadro ocioso: é o único instante em que a resposta muda.
  void _forgetChainLinks() {
    for (final row in grid.geometry.playableRows) {
      for (final col in grid.geometry.columns) {
        grid.blockAt(row, col)?.chainLink = false;
      }
    }
  }
}
