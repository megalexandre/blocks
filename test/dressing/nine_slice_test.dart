import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/config/layout.dart';
import 'package:blocos/dressing/nine_slice.dart';
import 'package:blocos/dressing/ui_scale.dart';

/// O retângulo da moldura: o vão do tabuleiro inflado pela borda.
Rect get molduraPadrao => Rect.fromLTWH(
      GameLayout.boardVoidLeft - UiScale.frameBorder,
      GameLayout.boardVoidTop - UiScale.frameBorder,
      GameLayout.boardVoidWidth + UiScale.frameBorder * 2,
      GameLayout.boardVoidHeight + UiScale.frameBorder * 2,
    );

void main() {
  const slice = NineSlice(tile: 32, scale: UiScale.panel);

  group('NineSlice: o quadro cobre a área', () {
    test('a união dos pedaços é a área inteira, sem buraco', () {
      final area = const Rect.fromLTWH(100, 50, 640, 480);
      final pieces = slice.piecesFor(area);

      // Amostragem no centro de cada célula de 8×8: toda amostra dentro da
      // área tem que cair em algum pedaço. Um buraco de uma fileira inteira
      // — que é o erro que dá — não escapa dessa peneira.
      for (var y = area.top + 4; y < area.bottom; y += 8) {
        for (var x = area.left + 4; x < area.right; x += 8) {
          final cobre = pieces.any((p) => p.dst.contains(Offset(x, y)));
          expect(cobre, isTrue, reason: 'nada cobre ($x, $y)');
        }
      }
    });

    test('dois pedaços nunca se sobrepõem', () {
      final pieces = slice.piecesFor(const Rect.fromLTWH(0, 0, 512, 384));
      for (var i = 0; i < pieces.length; i++) {
        for (var j = i + 1; j < pieces.length; j++) {
          final corte = pieces[i].dst.intersect(pieces[j].dst);
          expect(
            corte.width <= 0 || corte.height <= 0,
            isTrue,
            reason: 'os pedaços $i e $j se sobrepõem em $corte',
          );
        }
      }
    });
  });

  group('NineSlice: a escala é uniforme em todo pedaço', () {
    test('todo pedaço tem dst igual a src vezes a escala', () {
      // É o que prende o canto: esticar o canto junto com a aresta é o erro
      // clássico do nine-slice, e ele passa despercebido a olho nu em painel
      // grande. Aqui a conta denuncia.
      for (final area in [
        const Rect.fromLTWH(0, 0, 512, 384),
        const Rect.fromLTWH(7, 13, 500, 371), // sobra em ambos os eixos
        molduraPadrao,
      ]) {
        for (final p in slice.piecesFor(area)) {
          expect(p.dst.width, closeTo(p.src.width * slice.scale, 1e-9));
          expect(p.dst.height, closeTo(p.src.height * slice.scale, 1e-9));
        }
      }
    });

    test('os quatro cantos saem no tamanho natural e encostam nas quinas', () {
      final area = const Rect.fromLTWH(100, 50, 640, 480);
      final b = slice.border;
      final cantos = {
        Offset(area.left, area.top),
        Offset(area.right - b, area.top),
        Offset(area.left, area.bottom - b),
        Offset(area.right - b, area.bottom - b),
      };
      final achados = slice
          .piecesFor(area)
          .where((p) => p.dst.width == b && p.dst.height == b)
          .map((p) => p.dst.topLeft)
          .toSet();
      expect(achados.containsAll(cantos), isTrue);
    });
  });

  group('NineSlice: a moldura do jogo fecha em tile inteiro', () {
    test('nenhum pedaço sai recortado no retângulo da moldura', () {
      // Trava a conta do §escala: 768 e 1536 são múltiplos de 128, então a
      // moldura e a parede não têm meio tijolo na ponta. Se alguém mexer em
      // GameLayout ou em UiScale.panel, este teste quebra e diz por quê.
      for (final p in slice.piecesFor(molduraPadrao, fillCenter: false)) {
        expect(
          p.src.width,
          slice.tile,
          reason: 'pedaço recortado na horizontal: ${p.dst}',
        );
        expect(
          p.src.height,
          slice.tile,
          reason: 'pedaço recortado na vertical: ${p.dst}',
        );
      }
    });

    test('as arestas da moldura dão 6 tiles na horizontal e 12 na vertical', () {
      final pieces = slice.piecesFor(molduraPadrao, fillCenter: false);
      final b = slice.border;
      // Só as arestas: o canto também encosta no topo e na esquerda.
      final topo = pieces.where(
        (p) =>
            p.dst.top == molduraPadrao.top &&
            p.dst.left >= molduraPadrao.left + b &&
            p.dst.right <= molduraPadrao.right - b,
      );
      final lado = pieces.where(
        (p) =>
            p.dst.left == molduraPadrao.left &&
            p.dst.top >= molduraPadrao.top + b &&
            p.dst.bottom <= molduraPadrao.bottom - b,
      );
      expect(topo, hasLength(GameLayout.boardVoidWidth ~/ b));
      expect(lado, hasLength(GameLayout.boardVoidHeight ~/ b));
    });
  });

  group('NineSlice: o modo moldura', () {
    test('sem fillCenter o miolo fica vazio, e só o miolo', () {
      final area = const Rect.fromLTWH(0, 0, 512, 384);
      final b = slice.border;
      final vao = Rect.fromLTWH(b, b, area.width - b * 2, area.height - b * 2);

      final semMiolo = slice.piecesFor(area, fillCenter: false);
      for (final p in semMiolo) {
        final corte = p.dst.intersect(vao);
        expect(
          corte.width <= 0 || corte.height <= 0,
          isTrue,
          reason: 'o pedaço ${p.dst} invadiu o vão',
        );
      }

      final comMiolo = slice.piecesFor(area);
      expect(comMiolo.length, greaterThan(semMiolo.length));
    });
  });

  group('NineSlice: sobra', () {
    test('a fileira que não fecha sai recortada, nunca esticada', () {
      // 300 de miolo com tile de 128: dois cheios e um de 44.
      final area = Rect.fromLTWH(0, 0, slice.border * 2 + 300, slice.border * 2);
      final topo = slice
          .piecesFor(area, fillCenter: false)
          .where((p) =>
              p.dst.top == 0 &&
              p.dst.left >= slice.border &&
              p.dst.right <= area.right - slice.border)
          .toList()
        ..sort((a, b) => a.dst.left.compareTo(b.dst.left));

      expect(topo, hasLength(3));
      expect(topo[0].dst.width, slice.border);
      expect(topo[1].dst.width, slice.border);
      expect(topo[2].dst.width, 300 - slice.border * 2);
      expect(topo[2].src.width, (300 - slice.border * 2) / slice.scale);
      expect(topo.last.dst.right, area.right - slice.border);
    });
  });
}
