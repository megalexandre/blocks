import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/rules/stack_raiser.dart';

void main() {
  group('StackRaiser.advance', () {
    test('acumula fração de linha e só completa linha ao passar de 1', () {
      final raiser = StackRaiser();
      // Velocidade base: 1/8 de linha por segundo, então 8s por linha.
      expect(raiser.advance(4), 0, reason: 'metade do caminho não vira linha');
      expect(raiser.offset, closeTo(0.5, 1e-9));

      expect(raiser.advance(4), 1, reason: '8s completam exatamente uma linha');
      expect(raiser.offset, closeTo(0, 1e-9));
    });

    test('um quadro longo não perde linhas', () {
      final raiser = StackRaiser();
      // Vinte segundos de uma vez: duas linhas inteiras e sobra.
      expect(raiser.advance(20), 2);
      expect(raiser.offset, closeTo(0.5, 1e-9));
    });

    test('congelada não sobe', () {
      final raiser = StackRaiser()..frozen = true;
      expect(raiser.advance(100), 0);
      expect(raiser.offset, 0);
    });

    test('o boost sobe oito vezes mais rápido que a base', () {
      final base = StackRaiser();
      final boosted = StackRaiser()..boosting = true;
      // Meio segundo: no boost isso é meia linha. Um segundo completaria a
      // linha, advance zeraria o offset e a comparação não diria nada.
      base.advance(0.5);
      boosted.advance(0.5);
      expect(boosted.offset, closeTo(base.offset * 8, 1e-9));
    });
  });

  group('controles de desenvolvimento', () {
    test('paused segura a pilha mesmo com o jogo destravado', () {
      // Separado do `frozen` porque quem conduz o quadro reescreve o frozen
      // toda vez: o que fosse escrito nele de fora duraria um quadro.
      final raiser = StackRaiser()
        ..frozen = false
        ..paused = true;

      expect(raiser.advance(100), 0);
      expect(raiser.offset, 0);

      raiser.paused = false;
      expect(raiser.advance(8), 1, reason: 'destravada, volta a subir');
    });

    test('a taxa injetada é respeitada', () {
      // É o que permite a um cenário levar a pilha ao topo em segundos em vez
      // de um minuto e meio.
      final rapida = StackRaiser(baseRowsPerSecond: 1);

      expect(rapida.advance(3), 3);
    });
  });
}
