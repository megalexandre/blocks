class Score {
  static const int pointsPerBlock = 10;

  int get total => _total;

  int _total = 0;

  void register(int comboSize, int chainLevel) {
    _total += comboSize * pointsPerBlock * chainLevel;
  }
}
