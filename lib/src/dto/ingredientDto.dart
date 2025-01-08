class IngredientDto {
  final int? stationId;
  final String name;

  IngredientDto({this.stationId, required this.name});

  factory IngredientDto.fromJson(Map<String, dynamic> json) {
    return IngredientDto(
      stationId: json['stationId'] as int?,
      name: json['name'] as String,
    );
  }
}
