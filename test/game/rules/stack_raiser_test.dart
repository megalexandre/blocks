import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/game/rules/stack_raiser.dart';

/// Uma pilha de velocidade fixa, sem a rampa que acelera com o tempo.
///
/// `maxGrowth: 1` é o jeito de dizer "não cresça": estes testes medem a
/// aritmética do acumulador, e um número que muda sozinho entre uma linha e
/// a seguinte tornaria a conta impossível de afirmar.
StackRaiser steady() => StackRaiser(maxGrowth: 1);

void main() {
  group('StackRaiser.advance', () {
    test('acumula fração de linha e só completa linha ao passar de 1', () {
      final raiser = steady();
      // Velocidade base: 1/8 de linha por segundo, então 8s por linha.
      expect(raiser.advance(4), 0, reason: 'metade do caminho não vira linha');
      expect(raiser.offset, closeTo(0.5, 1e-9));

      expect(raiser.advance(4), 1, reason: '8s completam exatamente uma linha');
      expect(raiser.offset, closeTo(0, 1e-9));
    });

    test('um quadro longo não perde linhas', () {
      final raiser = steady();
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
      final base = steady();
      final boosted = steady()..boosting = true;
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
      final rapida = StackRaiser(baseRowsPerSecond: 1, maxGrowth: 1);

      expect(rapida.advance(3), 3);
    });
  });

  group('a velocidade acelera com o tempo de partida', () {
    test('dobra a cada período de duplicação', () {
      final raiser = StackRaiser(doublingSeconds: 10);
      final inicio = raiser.rowsPerSecond;

      raiser.advance(10);
      expect(raiser.rowsPerSecond, closeTo(inicio * 2, 1e-9));

      raiser.advance(10);
      expect(raiser.rowsPerSecond, closeTo(inicio * 4, 1e-9));
    });

    test('para de crescer no teto, que é relativo à velocidade inicial', () {
      // Teto relativo para um cenário que começa acelerado não ser freado por
      // um limite pensado para a partida normal.
      final raiser = StackRaiser(
        baseRowsPerSecond: 2,
        doublingSeconds: 10,
        maxGrowth: 4,
      );

      raiser.advance(1000);

      expect(raiser.growth, 4);
      expect(raiser.rowsPerSecond, closeTo(8, 1e-9));
    });

    test('o congelamento não dá desconto na dificuldade', () {
      // A pilha para, o relógio não: uma combinação longa alivia o tabuleiro,
      // não a velocidade que vem depois dela.
      final correndo = StackRaiser(doublingSeconds: 10);
      final congelada = StackRaiser(doublingSeconds: 10)..frozen = true;

      correndo.advance(10);
      congelada.advance(10);
      congelada.frozen = false;

      expect(congelada.rowsPerSecond, closeTo(correndo.rowsPerSecond, 1e-9));
    });

    test('segurada de fora, nem o relógio corre', () {
      // Senão examinar um tabuleiro parado por um minuto o devolveria
      // acelerado.
      final raiser = StackRaiser(doublingSeconds: 10)..paused = true;
      final inicio = raiser.growth;

      raiser.advance(60);
      raiser.paused = false;

      expect(raiser.growth, inicio);
    });

    test('o impulso multiplica a velocidade do momento', () {
      // Multiplicador, e não taxa fixa: no fim da partida a subida natural
      // alcançaria um valor absoluto e o botão pararia de adiantar nada.
      final raiser = StackRaiser(doublingSeconds: 10);
      raiser.advance(30);
      final natural = raiser.rowsPerSecond;

      raiser.boosting = true;

      expect(
        raiser.rowsPerSecond,
        closeTo(natural * StackRaiser.defaultBoostMultiplier, 1e-9),
      );
    });
  });
}
