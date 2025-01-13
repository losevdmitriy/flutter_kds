class PrepackRecipeItem {
  final int sourceId;
  final String name;
  final double initAmount;
  final double finalAmount;
  final double lossesAmount;
  final double lossesPercentage;

  PrepackRecipeItem({
    required this.sourceId,
    required this.name,
    required this.initAmount,
    required this.finalAmount,
    required this.lossesAmount,
    required this.lossesPercentage,
  });

  /// Фабричный конструктор для преобразования из JSON
  factory PrepackRecipeItem.fromJson(Map<String, dynamic> json) {
    return PrepackRecipeItem(
      sourceId: json['sourceId'] as int,
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
      };
}
