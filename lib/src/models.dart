class OrderItemDto {
  final int id;
  final int orderId;
  final String name;
  final DateTime createdAt;
  final OrderItemStationStatus status;
  final List<IngredientDto> ingredients;

  OrderItemDto({
    required this.id,
    required this.orderId,
    required this.name,
    required this.createdAt,
    required this.status,
    required this.ingredients,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: OrderItemStationStatus.values.firstWhere(
        (e) => e.toString() == 'OrderItemStationStatus.${json['status']}',
        orElse: () => OrderItemStationStatus.ADDED,
      ),
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((item) => IngredientDto.fromJson(item))
          .toList(),
    );
  }
}

enum OrderItemStationStatus { ADDED, STARTED, COMPLETED, CANCELED }

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
