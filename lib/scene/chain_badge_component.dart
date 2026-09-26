import 'dart:ui';

import 'package:flame/components.dart';

import '../dressing/chain_badge_painter.dart';

/// O selo do multiplicador solto no tabuleiro: nasce rente ao grupo que fechou
/// a combinação, sobe um pouco e desbota.
///
/// Componente, e não um item numa lista guardada no pintor: o que ele tem é
/// **tempo de vida**, e sair da cena quando acaba é o que o Flame já sabe
/// fazer. Filho do tabuleiro, então anda no espaço dele sem repetir conta
/// nenhuma — e vai embora junto com ele quando a partida recomeça, em vez de
/// sobrar na tela anunciando uma chain da partida perdida.
///
/// Não lê o jogo. Recebe o número pronto e nunca mais pergunta nada: a chain
/// que ele anuncia já acabou de acontecer, e um selo que consultasse o estado
/// atual mudaria de número no meio do voo.
class ChainBadgeComponent extends PositionComponent {
  ChainBadgeComponent({
    required this.level,
    required this.painter,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  /// Quanto tempo o selo fica na tela.
  ///
  /// Um pouco menos que o intervalo entre dois elos de uma chain — meio
  /// segundo piscando, mais o estouro e a queda: o "×2" já está saindo quando
  /// o "×3" aparece, e os dois nunca se acumulam parados sobre o tabuleiro.
  static const double lifetime = 0.9;

  /// Quanto ele sobe nesse tempo, em unidades do canvas: meia célula.
  static const double rise = 64;

  /// Fração da vida em que ele começa a desbotar. Sobe cheio e apaga no fim —
  /// desbotando desde o começo, o número não chega a ser lido.
  static const double fadeFrom = 0.55;

  /// O número anunciado.
  final int level;

  /// Quem desenha. Vem de fora, e é o mesmo para todos os selos: o que muda de
  /// um para o outro é o número e o retângulo.
  final ChainBadgePainter painter;

  /// Onde ele nasceu. `late` porque só existe depois de o construtor ter
  /// posto o componente no lugar.
  late final double _startY = position.y;

  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    final elapsed = _age / lifetime;
    // Sobe rápido e vai parando: é esse desenho de movimento que o olho lê
    // como "saltou dali". Arredondado para unidade inteira do canvas porque o
    // selo é pixel art **e se mexe** — em posição fracionária cada quadro
    // amostra a fita de um jeito e as fileiras de pixel pulsam de largura. É a
    // mesma resposta que `BoardViewport.topOf` dá para o mesmo problema.
    position.y = (_startY - rise * (1 - _sq(1 - elapsed))).roundToDouble();
  }

  @override
  void render(Canvas canvas) {
    final elapsed = _age / lifetime;
    painter.render(
      canvas,
      Offset.zero & Size(size.x, size.y),
      level: level,
      fade: ((elapsed - fadeFrom) / (1 - fadeFrom)).clamp(0.0, 1.0),
    );
  }

  static double _sq(double value) => value * value;
}
