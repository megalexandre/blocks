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
  const MatchCleared({required this.comboSize, required this.chainLevel});

  /// Quantos blocos saíram juntos.
  final int comboSize;

  /// 1 na primeira combinação depois da pilha assentar; sobe a cada
  /// combinação que uma queda anterior encadeia.
  final int chainLevel;
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

/// Onde um sistema anota o que fez.
///
/// Função e não classe: um argumento só, de um tipo selado, já é a menor
/// coisa que resolve o problema de ordem de parâmetro — e um teste passa
/// `lista.add` direto, sem montar dublê nenhum.
typedef EmitEvent = void Function(GameEvent event);
