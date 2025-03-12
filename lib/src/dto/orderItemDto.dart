import 'dart:ffi';

import 'package:flutter_iem_new/src/dto/ingredientDto.dart';
import 'package:flutter_iem_new/src/dto/stationDto.dart';

class OrderItemDto {
  final int id;
  final int orderId;
  final String orderName;
  final String name;
  final List<IngredientDto> ingredients;
  final DateTime statusUpdatedAt;
  final OrderItemStationStatus status;
  final StationDto currentStation;
  final String flowStepType;
  final int timeToCook;
  final bool extra;

  OrderItemDto({
    required this.id,
    required this.orderId,
    required this.orderName,
    required this.name,
    required this.statusUpdatedAt,
    required this.status,
    required this.currentStation,
    this.ingredients = const [],
    required this.flowStepType,
    required this.extra,
    required this.timeToCook
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      name: json['name'] as String,
      orderName: json['orderName'] as String,
      ingredients: (json['ingredients'] is List)
          ? (json['ingredients'] as List)
          .whereType<Map<String, dynamic>>() // Фильтруем только корректные элементы
          .map((item) => IngredientDto.fromJson(item))
          .toList()
          : [],
      statusUpdatedAt: DateTime.parse(json['statusUpdatedAt'] as String),
      status: OrderItemStationStatus.values.firstWhere(
            (e) => e.toString() == 'OrderItemStationStatus.${json['status']}',
        orElse: () => OrderItemStationStatus.ADDED,
      ),
      currentStation: StationDto.fromJson(json['currentStation'] as Map<String, dynamic>),
      flowStepType: json['flowStepType'] as String,
      timeToCook: json['timeToCook'] as int,
      extra: json['extra'] as bool,
    );
  }

}

enum OrderItemStationStatus { ADDED, STARTED, COOCKING, COMPLETED, CANCELED }
