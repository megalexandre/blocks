import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/config/layout.dart';
import 'package:blocos/dressing/ui_scale.dart';
import 'package:blocos/scene/boost_component.dart';
import 'package:blocos/scene/gate_component.dart';

void main() {
  group('BoostComponent: onde o botão aceita toque', () {
    test('o alvo é o rebaixo, e não a margem inteira', () {
      // Era a faixa de 156 do topo ao pé do tabuleiro. Um alvo desse tamanho
      // aceita toque na madeira do batente e na borda da tela — lugares que
      // não parecem botão.
      for (final side in BoostSide.values) {
        final alvo = BoostComponent.targetRect(side);
        expect(alvo.width, lessThan(GameLayout.boardVoidLeft));
        expect(alvo.height, lessThan(GameLayout.boardVoidHeight));
      }
    });

    test('cabe dentro do batente da moldura, sem invadir o tabuleiro', () {
      final frame = GateComponent.frameRect();
      final vao = frame.deflate(UiScale.frameBorder);

      for (final side in BoostSide.values) {
        final alvo = BoostComponent.targetRect(side);
        expect(
          frame.contains(alvo.topLeft) && frame.contains(alvo.bottomRight),
          isTrue,
          reason: 'o alvo de $side saiu da moldura',
        );
        final invasao = alvo.intersect(vao);
        expect(
          invasao.width <= 0 || invasao.height <= 0,
          isTrue,
          reason: 'o alvo de $side entrou no vão, onde o toque já tem dono',
        );
      }
    });

    test('os dois lados são espelhados e ficam na mesma altura', () {
      final esquerda = BoostComponent.targetRect(BoostSide.left);
      final direita = BoostComponent.targetRect(BoostSide.right);

      expect(esquerda.top, direita.top);
      expect(esquerda.size, direita.size);
      expect(
        esquerda.center.dx + direita.center.dx,
        closeTo(GameLayout.width, 1e-9),
        reason: 'espelhados em torno do meio da tela',
      );
    });
  });
}
