class PrepackRecipeItem {
  int sourceId;
  String name;
  double initAmount;
  double finalAmount;
  double lossesAmount;
  double lossesPercentage;
  String sourceType;

  PrepackRecipeItem(
      {required this.sourceId,
      required this.name,
      required this.initAmount,
      required this.finalAmount,
      required this.lossesAmount,
      required this.lossesPercentage,
      required this.sourceType});

  /// Фабричный конструктор для преобразования из JSON
  factory PrepackRecipeItem.fromJson(Map<String, dynamic> json) {
    return PrepackRecipeItem(
      sourceId: json['sourceId'] as int,
      sourceType: json['sourceType'] as String,
      name: json['name'] as String,
      initAmount: (json['initAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      lossesAmount: (json['lossesAmount'] as num?)?.toDouble() ?? 0.0,
      lossesPercentage: (json['lossesPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'name': name,
        'initAmount': initAmount,
        'finalAmount': finalAmount,
        'lossesAmount': lossesAmount,
        'lossesPercentage': lossesPercentage,
        'sourceType': sourceType
      };
}
