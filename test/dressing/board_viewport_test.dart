import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/dressing/board_viewport.dart';
import 'package:blocos/game/model/column.dart';
import 'package:blocos/game/model/row_index.dart';

RowIndex row(int value) => RowIndex(value);
Column col(int value) => Column(value);

BoardViewport viewport({double riseOffset = 0, double zoom = 1}) =>
    BoardViewport(
      size: Vector2(768, 1536),
      cellSize: 128,
      riseOffset: riseOffset,
      zoom: zoom,
    );

void main() {
  group('geometria', () {
    test('cada linha fica uma célula abaixo da anterior', () {
      final view = viewport();
      expect(view.topOf(row(0)), 0);
      expect(view.topOf(row(1)), 128);
      expect(view.topOf(row(12)), 1536);
    });

    test('a pilha subindo puxa todas as linhas para cima juntas', () {
      final view = viewport(riseOffset: 0.5);
      expect(view.topOf(row(0)), -64);
      expect(view.topOf(row(1)), 64);
      // O que importa é a distância entre linhas não mudar: a pilha sobe
      // inteira, não se estica.
      expect(view.topOf(row(2)) - view.topOf(row(1)), 128);
    });

    test('leftOf e cellRect concordam', () {
      final view = viewport();
      expect(view.leftOf(col(3)), 384);
      expect(view.cellRect(row(2), col(3)), const Rect.fromLTWH(384, 256, 128, 128));
    });
  });

  group('arredondamento para pixel de tela', () {
    // Zoom real de uma janela de 420px sobre o canvas de 1080: a célula de
    // 128 vira ~49,78 pixels de tela, e toda posição cai em fração.
    const zoom = 420 / 1080;

    test('o topo sempre cai num pixel inteiro de tela', () {
      for (var passo = 0; passo < 50; passo++) {
        final view = viewport(riseOffset: passo / 50, zoom: zoom);
        for (var index = 0; index < 13; index++) {
          final onScreen = view.topOf(row(index)) * zoom;
          expect(
            onScreen,
            closeTo(onScreen.roundToDouble(), 1e-9),
            reason:
                'linha $index com riseOffset ${passo / 50} caiu em pixel '
                'fracionário — é isso que faz o traço fino pulsar',
          );
        }
      }
    });

    test('sem zoom não arredonda nada', () {
      // zoom 0 acontece antes da câmera ser medida; não pode dividir por ele.
      final view = viewport(riseOffset: 0.3, zoom: 0);
      expect(view.topOf(row(1)), closeTo(128 - 0.3 * 128, 1e-9));
    });

    test('duas linhas vizinhas nunca se sobrepõem depois de arredondar', () {
      for (var passo = 0; passo < 50; passo++) {
        final view = viewport(riseOffset: passo / 50, zoom: zoom);
        for (var index = 0; index < 12; index++) {
          expect(
            view.topOf(row(index + 1)),
            greaterThan(view.topOf(row(index))),
            reason: 'o arredondamento colapsou a linha $index na seguinte',
          );
        }
      }
    });
  });
}
