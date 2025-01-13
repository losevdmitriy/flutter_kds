import 'PrepackRecipeItem.dart';

class ProcessingActDto {
  final int employeeId; // в Java final Long employeeId = 1L
  final int prepackId; // выбранная заготовка
  final double amount; // итоговое кол-во готового продукта (если нужно)
  final int? barcode; // можно передавать null
  final String? name; // можно передавать null
  final List<PrepackRecipeItem> itemDataList; // список ингредиентов/рецепта

  ProcessingActDto({
    required this.employeeId,
    required this.prepackId,
    required this.amount,
    this.barcode,
    this.name,
    required this.itemDataList,
  });

  /// Конвертация в JSON для передачи на сервер
  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'prepackId': prepackId,
        'amount': amount,
        'barcode': barcode,
        'name': name,
        'itemDataList': itemDataList
            .map((PrepackRecipeItem item) => item.toJson())
            .toList(),
      };
}
