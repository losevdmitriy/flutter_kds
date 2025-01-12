class IngredientDto {
  final int id;
  final int? stationId;
  final String name;
  final double lossPercent;

  IngredientDto(
      {required this.id,
      this.stationId,
      required this.name,
      required this.lossPercent});

  factory IngredientDto.fromJson(Map<String, dynamic> json) {
    return IngredientDto(
      id: 1,
      stationId: json['stationId'] as int?,
      name: json['name'] as String,
      lossPercent: 0.10,
    );
  }
}
