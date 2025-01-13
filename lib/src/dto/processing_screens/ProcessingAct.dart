import 'PrepackRecipeItem.dart';

class ProcessingAct {
  int id;
  int prepackId;
  String prepackName;
  double amount;
  String measurementUnit;
  String name;
  String employeeName;
  DateTime date;

  ProcessingAct(
      {required this.id,
      required this.prepackId,
      required this.prepackName,
      required this.measurementUnit,
      required this.amount,
      required this.date,
      required this.employeeName,
      required this.name});

  factory ProcessingAct.fromJson(Map<String, dynamic> json) {
    return ProcessingAct(
        id: json['id'],
        prepackId: json['prepackId'],
        prepackName: json['prepackName'],
        measurementUnit: json['measurementUnit'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        employeeName: json['employeeName'],
        name: json['name']);
  }
}

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
