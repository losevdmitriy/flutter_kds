import 'dart:convert';
import 'package:flutter_iem_new/src/dto/Invoice.dart';
import 'package:flutter_iem_new/src/dto/Source.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.0.6:8000"; // пример

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
      Uri.parse('$baseUrl/sources'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Source.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка ингридиентов и ПФок');
    }
  }
}
