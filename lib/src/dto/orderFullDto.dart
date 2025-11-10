// models.dart

import 'package:flutter_iem_new/src/dto/orderItemDto.dart';

/// Пример enum для статусов заказа (OrderStatus)
/// В Java у вас, возможно, свои значения, нужно учесть это при парсинге.
enum OrderStatus { CREATED, COOKING, COLLECTING, READY, CANCELED, DONE }

/// Dart-модель, соответствующая Java-классу OrderFullDto.
class OrderFullDto {
  final int id;
  final String name;
  final OrderStatus status;
  final List<OrderItemDto> items;
  final DateTime shouldBeFinishedAt;
  final DateTime kitchenShouldGetOrderAt;
  final DateTime? kitchenGotOrderAt;

  OrderFullDto({
    required this.id,
    required this.name,
    required this.status,
    required this.items,
    required this.kitchenShouldGetOrderAt,
    required this.shouldBeFinishedAt,
    this.kitchenGotOrderAt,
  });

  /// Фабричный конструктор для парсинга из JSON в Dart-объект.
  factory OrderFullDto.fromJson(Map<String, dynamic> json) {
    return OrderFullDto(
      id: json['id'] as int,
      name: json['name'] as String,
      status: _orderStatusFromString(json['status']), // см. функцию ниже
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemDto.fromJson(item))
              .toList() ?? [],
      kitchenShouldGetOrderAt: json['kitchenShouldGetOrderAt'] != null 
          ? DateTime.parse(json['kitchenShouldGetOrderAt'] as String)
          : DateTime.now(),
      shouldBeFinishedAt: json['shouldBeFinishedAt'] != null
          ? DateTime.parse(json['shouldBeFinishedAt'] as String)
          : DateTime.now(),
      kitchenGotOrderAt: json['kitchenGotOrderAt'] != null
          ? DateTime.parse(json['kitchenGotOrderAt'] as String)
          : null,
    );
  }
}

/// Функция-помощник для конвертации строки статуса в enum OrderStatus
OrderStatus _orderStatusFromString(String? statusString) {
  if (statusString == null) return OrderStatus.CREATED; // значение по умолчанию
  switch (statusString.toUpperCase()) {
    case 'CREATED':
      return OrderStatus.CREATED;
    case 'COOKING':
      return OrderStatus.COOKING;
    case 'COLLECTING':
      return OrderStatus.COLLECTING;
    case 'READY':
      return OrderStatus.READY;
    case 'CANCELED':
      return OrderStatus.CANCELED;
    case 'DONE':
      return OrderStatus.DONE;
    default:
      return OrderStatus.CREATED; // или выбросить ошибку, если непредвиденный статус
  }
}
