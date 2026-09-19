import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/game_event.dart';
import 'package:blocos/game/score.dart';

void main() {
  test('combo maior e chain maior valem mais pontos', () {
    final score = Score();

    score.handle(const MatchCleared(comboSize: 3, chainLevel: 1));
    expect(score.total, 3 * Score.pointsPerBlock);

    score.handle(const MatchCleared(comboSize: 4, chainLevel: 2));
    expect(score.total, 3 * Score.pointsPerBlock + 4 * Score.pointsPerBlock * 2);
  });

  test('evento que não é combinação não mexe no placar', () {
    // O placar casa sobre o tipo do evento, então um evento novo na
    // hierarquia não passa a somar ponto sozinho.
    final score = Score();

    score.handle(const RowsRisen(count: 3));
    score.handle(const ChainEnded(length: 4));
    score.handle(const ToppedOut());

    expect(score.total, 0);
  });
}
