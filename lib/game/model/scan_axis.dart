import 'column.dart';
import 'row_index.dart';

/// Os dois eixos em que uma sequência de mesma cor pode existir.
///
/// Era um record `({int index, int col})` chamado `GridStep`,
/// **estruturalmente idêntico** ao par que descrevia uma célula — os dois
/// eram intercambiáveis para o compilador, e nada impedia passar uma posição
/// onde se esperava uma direção. Enum resolve isso de vez: direção não é
/// posição, e só existem duas.
enum ScanAxis {
  horizontal,
  vertical;

  /// A linha que se alcança andando [steps] passos neste eixo. Negativo anda
  /// para o outro lado — é assim que uma busca cobre os dois sentidos com um
  /// laço só.
  RowIndex rowFrom(RowIndex row, int steps) =>
      this == vertical ? row.shifted(steps) : row;

  /// A coluna que se alcança andando [steps] passos neste eixo.
  Column colFrom(Column col, int steps) =>
      this == horizontal ? col.shifted(steps) : col;
}
