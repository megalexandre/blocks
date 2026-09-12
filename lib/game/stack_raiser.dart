/// Único ponto que decide a velocidade de subida da pilha.
class StackRaiser {
  
  static const double baseRowsPerSecond = 1 / 8;
  static const double boostRowsPerSecond = 1;

  bool boosting = false;

  /// A pilha para de subir enquanto há combinação resolvendo ou bloco caindo.
  /// É o que dá ao jogador a folga para emendar o chain — e o raise manual
  /// também não fura essa pausa.
  bool frozen = false;

  double get rowsPerSecond => frozen
      ? 0
      : (boosting ? boostRowsPerSecond : baseRowsPerSecond);
}
