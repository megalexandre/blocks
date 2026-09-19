import '../model/block.dart';

/// Quem **escolhe** o que entra na grade: a altura de cada coluna na pilha de
/// abertura e a cor de cada bloco.
///
/// Só escolhe. Não conhece a grade, não conhece a regra de combinação e não
/// põe bloco em lugar nenhum. Era uma classe concreta que guardava o
/// `BlockGrid` que a tinha criado — ciclo fechado — e ainda carregava o veto
/// de cor, que é regra do jogo e não sorteio. Separando, o acaso fica isolado
/// atrás desta interface e o veto vai para `StackFiller`, onde pode usar o
/// mesmo `ColorRuns` que o detector de combinação usa.
abstract interface class BlockDealer {
  /// Quantas linhas cada coluna recebe na pilha de abertura, da esquerda para
  /// a direita.
  List<int> startHeights(int columnCount);

  /// Uma cor entre as permitidas. Nunca recebe lista vazia.
  BlockColor pickColor(List<BlockColor> allowed);
}
