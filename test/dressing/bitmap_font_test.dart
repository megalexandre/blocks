import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:blocos/dressing/bitmap_font.dart';

void main() {
  const grande = BitmapFont.grande;
  const pequena = BitmapFont.pequena;

  group('BitmapFont: a ordem da fita', () {
    test('o zero é o ÚLTIMO glifo, não o primeiro dos dígitos', () {
      // A armadilha do pacote: a fita vai A–Z, 1–9 e só então 0. Quem escrever
      // '0123456789' na ordem troca todo dígito de lugar, e isso só aparece
      // quando o placar bate num número redondo.
      expect(grande.indexOf('0'), 35);
      expect(grande.indexOf('1'), 26);
      expect(grande.indexOf('9'), 34);
      expect(pequena.indexOf('0'), 35);
    });

    test('as letras começam em zero', () {
      expect(grande.indexOf('A'), 0);
      expect(grande.indexOf('Z'), 25);
    });

    test('a fonte pequena tem a pontuação depois dos dígitos', () {
      expect(pequena.indexOf('-'), 36);
      expect(pequena.indexOf('×'), 38);
      expect(pequena.indexOf('.'), 47);
      expect(pequena.glyphCount, 52);
    });

    test('minúscula cai na maiúscula', () {
      expect(grande.indexOf('a'), grande.indexOf('A'));
    });

    test('caractere que a fonte não tem devolve -1', () {
      // Nenhuma das duas tem acento. É o que decide a cópia do menu.
      expect(grande.indexOf('É'), -1);
      expect(grande.indexOf('Ç'), -1);
      expect(grande.indexOf('.'), -1, reason: 'a grande não tem ponto');
      expect(grande.indexOf('×'), -1, reason: 'nem o sinal de vezes');
    });

    test('missingIn lista o que não dá para desenhar, e ignora o espaço', () {
      expect(grande.missingIn('JOGAR DE NOVO'), isEmpty);
      expect(grande.missingIn('OPÇÕES'), ['Ç', 'Õ']);
      expect(grande.missingIn('1.280'), ['.']);
    });
  });

  group('BitmapFont: a medida', () {
    test('texto vazio não ocupa nada', () {
      expect(grande.measure('', scale: 4), Size.zero);
    });

    test('um glifo é a célula vezes a escala', () {
      expect(grande.measure('A', scale: 4).width, 40);
      expect(grande.measure('A', scale: 4).height, 44);
    });

    test('o avanço não é a largura: a grande compartilha o contorno', () {
      // 10 + (-1) + 10 = 19. Se alguém "consertar" o letterSpacing para 0,
      // este teste quebra — e a costura entre letras engorda para 2px.
      expect(grande.measure('AB', scale: 4).width, 76);
      expect(grande.measure('AB', scale: 1).width, 19);
    });

    test('a pequena separa as letras em vez de encostar', () {
      expect(pequena.measure('AB', scale: 1).width, 11);
    });

    test('o espaçamento entra entre os glifos, nunca depois do último', () {
      // Somado depois de todos, todo texto centralizado saía meio
      // espaçamento fora do centro.
      final um = pequena.measure('A', scale: 1).width;
      final dois = pequena.measure('AA', scale: 1).width;
      expect(dois - um, pequena.glyphWidth + pequena.letterSpacing);
    });

    test('o espaço tem largura própria', () {
      final semEspaco = grande.measure('AB', scale: 1).width;
      final comEspaco = grande.measure('A B', scale: 1).width;
      expect(
        comEspaco - semEspaco,
        grande.spaceWidth + grande.letterSpacing,
      );
    });
  });

  group('BitmapFont: a escala que cabe', () {
    test('devolve inteiro e não estoura a caixa', () {
      const texto = 'PONTOS';
      for (final largura in [50.0, 200.0, 640.0, 1080.0]) {
        final escala = grande.fitScale(texto, largura);
        expect(escala, greaterThanOrEqualTo(1));
        if (escala > 1) {
          expect(
            grande.measure(texto, scale: escala).width,
            lessThanOrEqualTo(largura),
          );
        }
      }
    });

    test('nunca devolve zero, mesmo sem espaço nenhum', () {
      expect(grande.fitScale('PONTOS', 1), 1);
    });

    test('o maior placar cabe na faixa do HUD', () {
      // Sete dígitos na escala de manchete, contra a largura do canvas menos
      // as margens. Se o placar crescer mais que isso, é aqui que se descobre.
      expect(grande.measure('9999999', scale: 6).width, lessThan(1080 - 140));
    });
  });
}
