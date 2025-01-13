class ProcessingActItem {
  final int id;
  final int sourceId;
  final String sourceType;
  final String name;
  final double initAmount;
  final double finalAmount;
  final double lossesAmount;
  final double lossesPercentage;

  ProcessingActItem({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.name,
    required this.initAmount,
    required this.finalAmount,
    required this.lossesAmount,
    required this.lossesPercentage,
  });

  factory ProcessingActItem.fromJson(Map<String, dynamic> json) {
    return ProcessingActItem(
      id: json['id'],
      sourceId: json['sourceId'],
      sourceType: json['sourceType'],
      name: json['name'],
      initAmount: (json['initAmount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      lossesAmount: (json['lossesAmount'] as num).toDouble(),
      lossesPercentage: (json['lossesPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'name': name,
      'initAmount': initAmount,
      'finalAmount': finalAmount,
      'lossesAmount': lossesAmount,
      'lossesPercentage': lossesPercentage,
    };
  }
}

class CompliteProcessingAct {
  final int id;
  final int prepackId;
  final double amount;
  final String? barcode;
  final String? name;
  final List<ProcessingActItem> itemDataList;
  final int employeeId;

  CompliteProcessingAct({
    required this.id,
    required this.prepackId,
    required this.amount,
    this.barcode,
    this.name,
    required this.itemDataList,
    required this.employeeId,
  });

  factory CompliteProcessingAct.fromJson(Map<String, dynamic> json) {
    return CompliteProcessingAct(
      id: json['id'],
      prepackId: json['prepackId'],
      amount: (json['amount'] as num).toDouble(),
      barcode: json['barcode'],
      name: json['name'],
      itemDataList: (json['itemDataList'] as List<dynamic>)
          .map((item) => ProcessingActItem.fromJson(item))
          .toList(),
      employeeId: json['employeeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prepackId': prepackId,
      'amount': amount,
      'barcode': barcode,
      'name': name,
      'itemDataList': itemDataList.map((item) => item.toJson()).toList(),
      'employeeId': employeeId,
    };
  }
}
