import 'package:flutter_iem_new/src/dto/ingredientDto.dart';
import 'package:flutter_iem_new/src/dto/stationDto.dart';

class OrderItemDto {
  final int id;
  final int orderId;
  final String name;
  final List<IngredientDto> ingredients;
  final DateTime createdAt;
  final OrderItemStationStatus status;
  final StationDto currentStation;
  final String flowStepType;

  OrderItemDto(
      {required this.id,
      required this.orderId,
      required this.name,
      required this.createdAt,
      required this.status,
      required this.currentStation,
      required this.ingredients,
      required this.flowStepType});

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
        id: json['id'] as int,
        orderId: json['orderId'] as int,
        name: json['name'] as String,
        ingredients: (json['ingredients'] as List<dynamic>)
            .map((item) => IngredientDto.fromJson(item))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: OrderItemStationStatus.values.firstWhere(
          (e) => e.toString() == 'OrderItemStationStatus.${json['status']}',
          orElse: () => OrderItemStationStatus.ADDED,
        ),
        currentStation:
            StationDto.fromJson(json['currentStation'] as Map<String, dynamic>),
        flowStepType: json['flowStepType'] as String);
  }
}

enum OrderItemStationStatus { ADDED, STARTED, COOCKING, COMPLETED, CANCELED }
