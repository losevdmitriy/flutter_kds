import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/Invoice.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/ProcessingAct.dart';
import 'package:flutter_iem_new/src/dto/Source.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/PrepackRecipeItem.dart';

import 'package:http/http.dart' as http;

import '../dto/processing_screens/compliteProcessingAct.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080";

  ApiService();

  /// Получение всех накладных
  Future<List<Invoice>> fetchInvoices({int page = 0, int size = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices?pageNumber=$page&pageSize=$size'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Invoice.getAllFromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка накладных');
    }
  }

  /// Получение накладной по ID
  Future<Invoice> fetchInvoiceById(int invoiceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/$invoiceId'),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка при получении накладной');
    }
  }

  Future<void> deleteInvoice(int invoiceId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/invoices/$invoiceId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка при удалении накладной. Код: ${response.statusCode}');
    }
  }

  /// Сохранение накладной
  Future<void> saveInvoice(Invoice invoice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoice.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при сохранении накладной');
    }
  }

  /// Получение всех накладных
  Future<List<Source>> fetchSources() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sources/all'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка ингридиентов и ПФок');
    }
  }

  Future<List<Source>> fetchPrepacks() async {
    debugPrint('Пробуем Prepacks');

    final response = await http.get(
      Uri.parse('$baseUrl/sources/prepacks'),
    );

    debugPrint('Получили Prepacks');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Преобразуем каждый элемент в Source
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка заготовок (Prepacks)');
    }
  }

  Future<List<PrepackRecipeItem>> fetchPrepackRecipe(int prepackId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/processing/recipe/$prepackId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PrepackRecipeItem.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получения рецепта заготовки (Prepacks)');
    }
  }

  Future<void> saveProcessing(ProcessingActDto dto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/processing/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dto.toJson()),
    );

    // На бэке метод ничего не возвращает, но проверяем статус
    if (response.statusCode != 200) {
      throw Exception('Ошибка при сохранении обработки (ProcessingAct)');
    }
  }

  Future<List<ProcessingAct>> fetchProcessingActs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/processing/acts'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProcessingAct.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка актов (ProcessingAct)');
    }
  }

  Future<CompliteProcessingAct> fetchProcessingActItems(
      int processingActId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/processing/acts/$processingActId'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return CompliteProcessingAct.fromJson(data);
    } else {
      throw Exception(
          'Ошибка при получении акта обработки (ProcessingAct): ${response.statusCode}');
    }
  }

  Future<void> deleteProcessingAct(int processingActId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/processing/$processingActId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка при удалении накладной. Код: ${response.statusCode}');
    }
  }
}
