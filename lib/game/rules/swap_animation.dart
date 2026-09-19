import '../model/board_row.dart';
import '../model/column.dart';

/// A troca que acabou de acontecer, enquanto ainda está sendo animada.
///
/// A grade já está no estado final: as colunas aqui são onde cada bloco
/// **está agora**. Quem desenha interpola de volta até de onde ele veio.
class SwapAnimation {
  SwapAnimation({
    required this.row,
    required this.grabbedColumn,
    required this.displacedColumn,
  });

  static const double duration = 0.15;

  /// Linha da troca. É a própria linha, então a animação sobrevive à subida
  /// da pilha sem precisar reajustar nada.
  final BoardRow row;

  /// Coluna onde o bloco escolhido está agora — ele vem para a frente.
  final Column grabbedColumn;

  /// Coluna onde o bloco empurrado está agora — ele vai para trás.
  final Column displacedColumn;

  double _elapsed = 0;

  /// 0 quando os blocos ainda estão nas posições antigas, 1 no fim.
  double get progress => (_elapsed / duration).clamp(0.0, 1.0);

  bool get isDone => _elapsed >= duration;

  void advance(double dt) => _elapsed += dt;
}
