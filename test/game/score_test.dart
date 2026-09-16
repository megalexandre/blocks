import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/score.dart';

void main() {
  test('combo maior e chain maior valem mais pontos', () {
    final score = Score();

    score.register(3, 1);
    expect(score.total, 3 * Score.pointsPerBlock);

    score.register(4, 2);
    expect(score.total, 3 * Score.pointsPerBlock + 4 * Score.pointsPerBlock * 2);
  });
}
