import 'model/block_grid.dart';
import 'model/board_geometry.dart';
import 'model/board_row.dart';
import 'model/cell.dart';
import 'model/column.dart';
import 'game_event.dart';
import 'match_timings.dart';
import 'rules/block_dealer.dart';
import 'rules/gravity_system.dart';
import 'rules/match_system.dart';
import 'rules/random_dealer.dart';
import 'rules/stack_filler.dart';
import 'rules/stack_raiser.dart';
import 'rules/swap_animation.dart';
import 'rules/swap_system.dart';
import 'score.dart';

/// O jogo inteiro de um jogador: a grade, a pilha subindo, a gravidade, as
/// combinações e o placar — e, acima de tudo, **a ordem em que essas coisas
/// acontecem dentro de um quadro**.
///
/// Essa ordem é a regra mais delicada do jogo e morava no componente do
/// Flame: para testá-la era preciso subir um motor gráfico, então na prática
/// ela nunca foi testada. Aqui ela é Dart puro e cabe num `expect`. A
/// alternativa rejeitada — deixar a cena orquestrar e só extrair os
/// sistemas — mantinha a regra na camada de desenho, que é justamente onde
/// ela não pode estar.
///
/// O nome: `Match` já significa "combinação de três" nesta base, `Game`
/// colide com o do Flame, e `GameSession` sugere sessão de usuário.
/// `Playfield` é a área viva de **um** jogador — e é ela que tem pilha,
/// gravidade, chain e placar, então dois deles lado a lado é tudo o que um
/// modo versus precisaria.
///
/// Nada aqui devolve estado interno mutável: quem desenha lê pela grade, e
/// quem reage lê a lista de eventos do quadro.
class Playfield {
  Playfield({
    required this.geometry,
    BlockDealer? dealer,
    StackRaiser? raiser,
    this.timings = MatchTimings.standard,
  }) : _dealer = dealer ?? RandomDealer(),
       _raiser = raiser ?? StackRaiser() {
    // No corpo do construtor: os campos abaixo são `late`, e o inicializador
    // de um `late` só roda quando alguém pergunta pelo campo. Sem isto a
    // pilha de abertura só nasceria quando o primeiro quadro a procurasse.
    _filler
      ..dealOpeningStack()
      ..fillIncomingRow();
  }

  /// O tabuleiro do jogo: seis colunas, doze linhas visíveis mais a que
  /// entra por baixo.
  factory Playfield.standard({BlockDealer? dealer, StackRaiser? raiser}) =>
      Playfield(
        geometry: BoardGeometry.standard,
        dealer: dealer,
        raiser: raiser,
      );

  final BoardGeometry geometry;
  final MatchTimings timings;

  final BlockDealer _dealer;

  late final BlockGrid _grid = BlockGrid(geometry);
  late final StackFiller _filler = StackFiller(grid: _grid, dealer: _dealer);
  late final GravitySystem _gravity = GravitySystem(grid: _grid);
  late final MatchSystem _matches = MatchSystem(grid: _grid, timings: timings);
  late final SwapSystem _swaps = SwapSystem(grid: _grid);
  final StackRaiser _raiser;
  final Score _score = Score();

  /// Leitura para quem desenha. Nenhum método daqui muda a grade.
  BlockGrid get grid => _grid;
  Score get score => _score;
  SwapAnimation? get swapAnimation => _swaps.animation;
  BoardRow? get cursorRow => _swaps.cursorRow;
  Column get cursorColumn => _swaps.cursorColumn;

  /// Fração da linha que a pilha já subiu, de 0 a 1.
  double get riseOffset => _raiser.offset;

  /// Nível da chain em curso. Lido pelo HUD, que antes atravessava três
  /// objetos (`board.matchResolver.chainLevel`) para chegar até aqui.
  int get chainLevel => _matches.chainLevel;

  /// O jogador perdeu: a pilha empurrou bloco para fora pelo topo.
  ///
  /// A partir daqui [update] ignora o tempo — nada sobe, cai, combina ou
  /// anima. É o estado final de uma partida, e quem quiser jogar de novo
  /// constrói outro [Playfield]: recomeçar é uma partida nova, não um campo
  /// que se limpa.
  bool get isOver => _over;

  bool _over = false;

  /// A pilha alcançou a folga do topo: ainda dá para jogar, mas o próximo
  /// descuido custa a partida.
  ///
  /// Mora aqui, e não em quem desenha, porque é regra: a linha tracejada é a
  /// **representação** disto, e antes de existir a derrota ela era só um
  /// enfeite que não queria dizer nada.
  bool get isInDanger {
    for (final row in geometry.dangerRows) {
      for (final col in geometry.columns) {
        if (_grid.blockAt(row, col) != null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Segurar para subir mais rápido.
  set boosting(bool value) => _raiser.boosting = value;

  /// Há quanto tempo a partida corre, em segundos.
  double get elapsed => _raiser.elapsed;

  /// Quantas vezes a velocidade inicial a pilha sobe agora. Começa em 1 e
  /// cresce com o tempo de partida.
  double get speedGrowth => _raiser.growth;

  /// Segura a pilha onde está, sem congelar o resto do jogo: blocos continuam
  /// caindo, combinando e estourando. Serve para examinar um tabuleiro sem
  /// ele escorrer para cima enquanto se olha.
  bool get risePaused => _raiser.paused;

  set risePaused(bool value) => _raiser.paused = value;

  /// Um quadro inteiro. Devolve o que aconteceu nele, em ordem.
  ///
  /// A ordem é a regra: **subir → cair → combinar → recalcular o
  /// congelamento → animar a troca**. Subir primeiro porque a linha nova tem
  /// que existir antes de qualquer bloco procurar apoio nela; combinar depois
  /// de cair porque no original só bloco assentado fecha combinação; e o
  /// congelamento por último porque ele vale **a partir do quadro seguinte**
  /// — é assim desde a primeira versão, e antecipá-lo em um quadro muda o
  /// instante exato em que a pilha trava, que é coisa que o jogador sente.
  List<GameEvent> update(double dt) {
    final events = <GameEvent>[];
    if (_over) {
      return events;
    }
    _raise(events.add, dt);
    // Logo depois de subir, e não no momento de subir: é a chegada do bloco
    // à linha do topo que encerra a partida, não a saída dele por cima.
    if (_toppedOut(events.add)) {
      return events;
    }
    _gravity.update(dt, emit: events.add);
    // `isSettling` é perguntado depois de o sistema de combinação tirar da
    // grade quem terminou de estourar — é essa remoção que solta o bloco de
    // cima, e perguntar antes perderia a chain nesse instante exato.
    _matches.update(dt, isSettling: _isSettling, emit: events.add);
    _raiser.frozen = _matches.isResolving || _gravity.isSettling;
    _swaps.update(dt);
    for (final event in events) {
      _score.handle(event);
    }
    return events;
  }

  // --- entrada do jogador -------------------------------------------------

  void grab(Cell cell) => _swaps.beginDrag(cell.col, _grid.rowAt(cell.row));

  void dragTo(Column col) => _swaps.dragTo(col);

  void release() => _swaps.endDrag();

  void _raise(EmitEvent emit, double dt) {
    // advance() consome o dt: uma chamada por quadro, e é por isso que ela
    // mora aqui dentro em vez de ficar exposta a quem desenha.
    final risenRows = _raiser.advance(dt);
    if (risenRows == 0) {
      return;
    }
    for (var i = 0; i < risenRows; i++) {
      _grid.shiftUp();
      _filler.fillIncomingRow();
    }
    emit(RowsRisen(count: risenRows));
  }

  /// Encerra a partida se algum bloco alcançou a linha do topo, e diz se foi
  /// o caso.
  ///
  /// **Chegar, não sair.** A verificação era feita no instante em que a linha
  /// do topo ia embora — e isso é tarde demais: entre o bloco alcançar a
  /// primeira linha e a linha ser descartada, a pilha sobe uma célula inteira,
  /// que é o tempo do bloco deslizar para cima até desaparecer da área
  /// visível. O jogador via peças sumindo pelo teto com o jogo ainda
  /// correndo. Agora a partida acaba com o bloco encostado na borda de cima,
  /// onde ele ainda é visível e o motivo é óbvio.
  ///
  /// Por consequência, a linha do topo deixou de ser jogável: ela é o teto.
  bool _toppedOut(EmitEvent emit) {
    if (_grid.rowAt(geometry.topRow).isEmpty) {
      return false;
    }
    _over = true;
    emit(const ToppedOut());
    return true;
  }

  bool _isSettling() => _gravity.isSettling;
}
