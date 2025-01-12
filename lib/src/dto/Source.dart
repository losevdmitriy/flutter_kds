import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Source {
  final int? id;
  String name;
  String type;

  Source({
    this.id,
    required this.name,
    required this.type,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}