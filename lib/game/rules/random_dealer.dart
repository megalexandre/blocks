import 'dart:math' as math;

import '../model/block.dart';
import 'block_dealer.dart';

/// O carteador de verdade: o **único** dono de acaso do jogo.
///
/// O `Random` entra pelo construtor. Sem isso, o teste do veto de cor
/// precisava rodar trezentas partidas na força bruta torcendo para alguma
/// falhar; com semente, uma partida basta e ela é a mesma sempre. É também o
/// que dispensa qualquer dublê em teste: o teste usa esta mesma classe, só
/// que semeada — o projeto continua sem um único mock.
class RandomDealer implements BlockDealer {
  RandomDealer({math.Random? random}) : _random = random ?? math.Random();

  /// Para teste e para repetir uma partida: mesma semente, mesmo tabuleiro.
  RandomDealer.seeded(int seed) : _random = math.Random(seed);

  /// Altura da pilha inicial, em linhas, sorteada por coluna.
  static const int minStartHeight = 3;
  static const int maxStartHeight = 6;

  final math.Random _random;

  /// Sorteadas por coluna para o tabuleiro não começar com o topo reto.
  @override
  List<int> startHeights(int columnCount) =>
      List.generate(columnCount, (_) => _randomStartHeight());

  @override
  BlockColor pickColor(List<BlockColor> allowed) =>
      allowed[_random.nextInt(allowed.length)];

  int _randomStartHeight() =>
      minStartHeight + _random.nextInt(maxStartHeight - minStartHeight + 1);
}
