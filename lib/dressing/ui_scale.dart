/// Em quantas vezes cada pixel de arte do pacote é ampliado.
///
/// **Sempre inteiro.** O pacote é pixel art: em escala fracionária umas
/// fileiras de pixel saem com uma largura e outras com outra, e o traço de 1px
/// que desenha todo contorno vira um traço irregular. Em escala inteira o pixel
/// continua quadrado.
///
/// A regra que decide o `FilterQuality` de cada desenhador **não é sobre a
/// arte, é sobre se a coisa se mexe em fração de pixel**:
///
/// * anda em fração de pixel e é arte suave — os blocos, que sobem ~0,1px por
///   quadro — pede `medium`, porque o mipmap pré-média a origem e tira a
///   dependência da fase sub-pixel. É o que `BlockSprites` já faz, e não muda.
/// * fica parado — moldura, HUD, menu, botões, texto — pede `none`. Parado não
///   cintila, e `none` é o que preserva a aresta dura do pixel art.
/// * é pixel art **e** se mexe — só a porta, deslizando — pede `none` mais o
///   arredondamento para pixel de tela inteiro a cada quadro. É a mesma
///   resposta que `BoardViewport.topOf` já dá para o mesmo problema.
abstract final class UiScale {
  /// Painéis de 32px. 32 × 4 = 128, que é exatamente a célula do tabuleiro —
  /// e é isso que faz a moldura e a porta fecharem em tile inteiro sobre um
  /// vão de 768×1536, sem meio tijolo na ponta.
  static const int panel = 4;

  /// Lado da borda da moldura, em unidades do canvas.
  static const double frameBorder = 32.0 * panel;

  /// Fonte grande em manchete — título, placar.
  static const int headline = 7;

  /// Fonte pequena em rótulo, acima do número que ela nomeia. Bem menor que a
  /// manchete de propósito: em escalas parecidas o rótulo compete com o
  /// número, e quem lê o placar de relance lê "PONTOS" antes de ler quantos.
  static const int label = 4;

  /// A palavra SUBIR, deitada letra a letra dentro do rebaixo. Maior que o
  /// rótulo do placar porque ali ela é a única coisa escrita, e a coluna é
  /// estreita o bastante para uma letra pequena sumir.
  static const int boostLabel = 6;

  /// Quanto a porta invade o batente. Só o bastante para a borda dela ficar
  /// escondida sob a parte opaca da moldura — a face externa das arestas do
  /// painel tem 20 unidades transparentes, então qualquer coisa entre 20 e a
  /// borda inteira serve. Invadindo a borda toda, a porta fechada tapava a
  /// madeira inteira e só sobrava o friso de metal.
  static const double doorOverlap = 24;

  /// Ícones de 8×6.
  static const int icon = 7;
}
