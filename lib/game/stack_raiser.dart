class StackRaiser {
  static const double baseRowsPerSecond = 1 / 8;
  static const double boostRowsPerSecond = 1;

  bool boosting = false;
  bool frozen = false;

  double get rowsPerSecond =>
      frozen ? 0 : (boosting ? boostRowsPerSecond : baseRowsPerSecond);
}
