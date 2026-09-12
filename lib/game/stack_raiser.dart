/// Único ponto que decide a velocidade de subida da pilha.
class StackRaiser {
  
  static const double baseRowsPerSecond = 1 / 8;
  static const double boostRowsPerSecond = 1;

  bool boosting = false;

  double get rowsPerSecond =>
      boosting ? boostRowsPerSecond : baseRowsPerSecond;
}
