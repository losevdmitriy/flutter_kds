import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

import '../dto/Invoice.dart';
import '../dto/processing_screens/ProcessingAct.dart';
import '../dto/Source.dart';
import '../dto/processing_screens/PrepackRecipeItem.dart';
import '../dto/IngredientItemData.dart';
import '../dto/PrepackItemData.dart';
import '../dto/processing_screens/compliteProcessingAct.dart';
import '../dto/writeOffItemData.dart';
import '../dto/writeOffRequest.dart'; // Импортируем WriteOffRequest

class ApiService {
  ApiService();

  /// Получение всех накладных
  Future<List<Invoice>> fetchInvoices({int page = 0, int size = 10}) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/invoices?pageNumber=$page&pageSize=$size'),
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
      Uri.parse('${ApiConfig.baseUrl}/invoices/$invoiceId'),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка при получении накладной');
    }
  }

  Future<void> deleteInvoice(int invoiceId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/invoices/$invoiceId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка при удалении накладной. Код: ${response.statusCode}');
    }
  }

  /// Сохранение накладной
  Future<void> saveInvoice(Invoice invoice) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/invoices/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoice.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при сохранении накладной');
    }
  }

  /// Метод для списания товара
  Future<void> writeOffItem(WriteOffRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/warehouse/write-off');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при списании: ${response.body}');
    }
  }

  /// Метод для создания списания товара
  Future<void> addWriteOffItem(WriteOffRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/warehouse/add-write-off');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка при списании: ${response.body}');
    }
  }

  /// Получение всех источников (ингредиенты, ПФ)
  Future<List<Source>> fetchSources() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sources/all'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка ингредиентов и ПФ');
    }
  }

  Future<List<Source>> fetchPrepacks() async {
    debugPrint('Запрос Prepacks');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sources/prepacks'),
    );

    debugPrint('Ответ Prepacks');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка заготовок (Prepacks)');
    }
  }

  Future<List<Source>> fetchIngredients() async {
    debugPrint('Запрос Ingredients');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sources/ingredients'),
    );

    debugPrint('Ответ Ingredients');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка ингредиентов (Ingredients)');
    }
  }

  Future<List<PrepackRecipeItem>> fetchPrepackRecipe(int prepackId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/processing/recipe/$prepackId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PrepackRecipeItem.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении рецепта заготовки (Prepacks)');
    }
  }

  Future<void> saveProcessing(ProcessingActDto dto) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/processing/save'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dto.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при сохранении обработки (ProcessingAct)');
    }
  }

  Future<List<ProcessingAct>> fetchProcessingActs() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/processing/acts'),
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
      Uri.parse('${ApiConfig.baseUrl}/processing/acts/$processingActId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return CompliteProcessingAct.fromJson(data);
    } else {
      throw Exception(
          'Ошибка при получении акта обработки: ${response.statusCode}');
    }
  }

  Future<void> deleteProcessingAct(int processingActId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/processing/$processingActId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Ошибка при удалении акта обработки. Код: ${response.statusCode}');
    }
  }

  /// Получение всех ингредиентов
  Future<List<IngredientItemData>> fetchIngredientItems() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouse/ingredients'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((jsonEl) => IngredientItemData.fromJson(jsonEl)).toList();
    } else {
      throw Exception('Ошибка при получении списка ингредиентов');
    }
  }

  /// Получение всех полуфабрикатов
  Future<List<PrepackItemData>> fetchPrepackItems() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouse/prepacks'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((jsonEl) => PrepackItemData.fromJson(jsonEl)).toList();
    } else {
      throw Exception('Ошибка при получении списка полуфабрикатов');
    }
  }

  // Получение всех WriteOffItems
  Future<List<WriteOffItemData>> fetchWriteOffItems(
      int page, int elements) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/warehouse/allWriteOff?p=$page&e=$elements'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((jsonEl) => WriteOffItemData.fromJson(jsonEl)).toList();
    } else {
      throw Exception('Ошибка при получении списка списаний');
    }
  }
}
