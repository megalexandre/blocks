import 'dart:math' as math;
import 'dart:ui';

import 'game_assets.dart';

/// Uma fonte de bitmap: uma fita de glifos do mesmo tamanho e a ordem em que
/// eles foram desenhados.
///
/// Só métrica — não conhece `Canvas` nem `Image`. Quem desenha é `BitmapText`,
/// pela mesma divisão que separa `BoardViewport` de `BoardPainter`.
class BitmapFont {
  const BitmapFont({
    required this.asset,
    required this.glyphWidth,
    required this.glyphHeight,
    required this.characters,
    required this.letterSpacing,
    required this.spaceWidth,
    required this.monochrome,
  });

  /// A manchete: A–Z e então 1–9 e **0 por último**, que é a ordem em que a
  /// Pixel Frog desenhou a fita. Trocar isso por `0123456789` é o erro fácil,
  /// e ele só aparece quando alguém marca um ponto redondo.
  ///
  /// [letterSpacing] é **−1**, e não é engano. O desenho colorido ocupa as
  /// colunas 1–8 da célula de 10; as colunas 0 e 9 são o contorno escuro. Com
  /// avanço 10, dois contornos ficam lado a lado e a costura entre letras sai
  /// com 2px de escuro. Com 9, o contorno direito de um glifo cai exatamente
  /// sobre o esquerdo do seguinte — mesma cor, costura de 1px, que é o que a
  /// fonte foi desenhada para fazer.
  static const BitmapFont grande = BitmapFont(
    asset: GameAsset.bigText,
    glyphWidth: 10,
    glyphHeight: 11,
    characters: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
    letterSpacing: -1,
    spaceWidth: 5,
    monochrome: false,
  );

  /// O rótulo. Sem contorno — é `#33323D` chapado sobre transparente —, então
  /// as letras se encostariam com avanço 5 e o espaçamento é +1. Por ser de
  /// uma cor só, aceita ser tingida; a grande não.
  ///
  /// As quatro últimas pontuações foram lidas da fita ampliada e não de uma
  /// tabela do pacote: se alguma sair errada, é uma delas.
  static const BitmapFont pequena = BitmapFont(
    asset: GameAsset.smallText,
    glyphWidth: 5,
    glyphHeight: 6,
    characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-+×/=()#@!?.,:'\$",
    letterSpacing: 1,
    spaceWidth: 3,
    monochrome: true,
  );

  final GameAsset asset;
  final int glyphWidth;
  final int glyphHeight;

  /// A ordem dos glifos na fita. O comprimento **é** a contagem de glifos, e
  /// é por ele que a largura da folha é conferida no carregamento.
  final String characters;

  /// Em pixels de arte. Negativo quando os glifos compartilham o contorno.
  final int letterSpacing;

  /// Largura do espaço, que não tem glifo na fita.
  final int spaceWidth;

  /// Uma cor só, então dá para tingir com `BlendMode.srcIn`.
  final bool monochrome;

  int get glyphCount => characters.length;

  /// Índice do glifo na fita, ou −1 quando a fonte não tem esse caractere.
  int indexOf(String character) => characters.indexOf(character.toUpperCase());

  /// Quanto [text] ocupa desenhado em [scale].
  ///
  /// O espaçamento entra **entre** os glifos e não depois do último: somando
  /// depois de todos, todo texto centralizado saía meio espaçamento à
  /// esquerda do centro.
  Size measure(String text, {required int scale}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    var width = 0.0;
    for (var i = 0; i < text.length; i++) {
      width += (text[i] == ' ' ? spaceWidth : glyphWidth).toDouble();
      if (i < text.length - 1) {
        width += letterSpacing;
      }
    }
    return Size(width * scale, (glyphHeight * scale).toDouble());
  }

  /// A maior escala **inteira** em que [text] ainda cabe em [maxWidth].
  ///
  /// Nunca devolve zero: um texto que não cabe nem em escala 1 sai maior que a
  /// caixa, o que é feio mas legível — em escala 0 ele sumiria, o que é pior e
  /// mais difícil de notar.
  int fitScale(String text, double maxWidth) {
    final unit = measure(text, scale: 1).width;
    if (unit <= 0) {
      return 1;
    }
    return math.max(1, (maxWidth / unit).floor());
  }

  /// Os caracteres de [text] que esta fonte não sabe desenhar.
  Iterable<String> missingIn(String text) =>
      text.split('').where((c) => c != ' ' && indexOf(c) < 0);
}
