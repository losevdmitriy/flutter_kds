import 'package:flutter_iem_new/src/dto/orderStatus.dart';

class StationDto {
  final int id;
  final String name;
  final OrderStatus orderStatus;

  StationDto({
    required this.id,
    required this.name,
    required this.orderStatus,
  });

  factory StationDto.fromJson(Map<String, dynamic> json) {
    return StationDto(
      id: json['id'] as int,
      name: json['name'] as String,
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['orderStatusAtStation']}',
        orElse: () => OrderStatus.CREATED,
      ),
    );
  }
}
