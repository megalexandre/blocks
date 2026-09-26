import 'model/cell.dart';
import 'model/column.dart';

/// O que aconteceu num quadro.
///
/// Hierarquia selada **num arquivo só** porque a linguagem exige: `sealed` só
/// é exaustivo dentro da mesma biblioteca. É a única exceção à regra de uma
/// classe por arquivo neste projeto, e ela é do compilador, não de gosto.
///
/// Os eventos saem numa lista devolvida pelo quadro, e não por `Stream`: o
/// jogo não tem nada assíncrono na lógica e não deve ganhar. `Stream` traria
/// entrega fora da ordem do tick e teste com `await`, e um callback por tipo
/// de evento — o que existia — multiplica campos mutáveis opcionais a cada
/// evento novo. Uma lista é síncrona, ordenada e casável sem `default`.
sealed class GameEvent {
  const GameEvent();
}

/// Uma combinação nova fechou agora.
///
/// Parâmetros **nomeados** de propósito: isto substitui um
/// `onMatch(int comboSize, int chainLevel)` ligado a um
/// `Score.register(int, int)` por posição. Inverter os dois inteiros
/// compilava e passava calado, e o placar contava chain como combo pelo
/// resto da partida sem ninguém notar.
final class MatchCleared extends GameEvent {
  const MatchCleared({
    required this.comboSize,
    required this.chainLevel,
    required this.at,
  });

  /// Quantos blocos saíram juntos.
  final int comboSize;

  /// 1 na primeira combinação depois da pilha assentar, e também em toda
  /// combinação que o jogador fecha por conta própria; sobe só quando a
  /// combinação contém um bloco que um estouro anterior derrubou.
  final int chainLevel;

  /// Onde ela aconteceu: a célula **do meio** do grupo, na ordem da cascata —
  /// a do meio da fileira numa combinação horizontal, a do meio da pilha numa
  /// vertical. É por ela que o selo do multiplicador sabe onde nascer.
  ///
  /// Posição **visual**, e por isso só vale no quadro do evento: a linha muda
  /// de significado quando a pilha sobe. Quem for segurar isso por mais de um
  /// quadro converte para pixel na hora em que o evento chega — é o que o
  /// `BoardComponent` faz ao soltar o selo.
  final Cell at;
}

/// A pilha assentou e a chain que estava em curso terminou com este tamanho.
final class ChainEnded extends GameEvent {
  const ChainEnded({required this.length});

  final int length;
}

/// A pilha completou linhas inteiras neste quadro.
final class RowsRisen extends GameEvent {
  const RowsRisen({required this.count});

  final int count;
}

/// O jogador trocou dois blocos de lugar.
final class BlocksSwapped extends GameEvent {
  const BlocksSwapped({required this.grabbed, required this.displaced});

  /// Onde o bloco escolhido está agora.
  final Column grabbed;

  /// Onde o bloco empurrado está agora.
  final Column displaced;
}

/// Fim de jogo: a pilha empurrou bloco para fora pelo topo.
final class ToppedOut extends GameEvent {
  const ToppedOut();
}

/// Blocos terminaram de cair neste quadro: estavam descendo e encontraram
/// apoio.
///
/// **Um evento por quadro, com a contagem**, e não um por bloco. Uma fila
/// inteira pousa no mesmo passo de gravidade, e quem transforma isto em som
/// quer um impacto só — seis cópias do mesmo som disparadas juntas não soam
/// seis vezes mais alto, soam embolado.
final class BlocksLanded extends GameEvent {
  const BlocksLanded({required this.count});

  final int count;
}

/// Blocos começaram a sumir: acabaram de piscar e entraram no estouro.
///
/// É o início do efeito visual de encolher e desbotar, e não a combinação em
/// si — essa é [MatchCleared], que acontece meio segundo antes, quando o
/// grupo começa a piscar. Os dois são momentos diferentes que alguém pode
/// querer marcar de formas diferentes.
///
/// Um por quadro, pelo mesmo motivo de [BlocksLanded]: o grupo inteiro entra
/// no estouro no mesmo quadro, porque todos começaram a piscar juntos.
final class PopStarted extends GameEvent {
  const PopStarted({required this.count});

  final int count;
}

/// Onde um sistema anota o que fez.
///
/// Função e não classe: um argumento só, de um tipo selado, já é a menor
/// coisa que resolve o problema de ordem de parâmetro — e um teste passa
/// `lista.add` direto, sem montar dublê nenhum.
typedef EmitEvent = void Function(GameEvent event);
