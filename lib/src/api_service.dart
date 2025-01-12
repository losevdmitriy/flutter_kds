import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ApiService {
w  static const String baseUrl = "http://192.168.0.15:8000/api"; // пример

  StompClient? _stompClient;

  /// Получаем stationId по screenId
  Future<int?> getStationId(String screenId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/screens/$screenId/station'));
    if (response.statusCode == 200) {
      // допустим, сервер возвращает {"stationId": 123}
      final data = json.decode(response.body);
      return data['stationId'] as int;
    }
    return null;
  }

  /// Получаем список заказов для экрана
  Future<List<OrderItemDto>> getScreenOrderItems(String screenId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/screens/$screenId/orders'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => OrderItemDto.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  /// Обновляем статус заказа (например, переключаем ADDED -> STARTED)
  Future<void> updateStatus(int itemId) async {
    // допустим, POST /api/orders/{id}/updateStatus
    final response =
        await http.post(Uri.parse('$baseUrl/orders/$itemId/updateStatus'));
    if (response.statusCode != 200) {
      throw Exception('Failed to update order status');
    }
  }

  /// Подключаемся к WebSocket, чтобы получать уведомления
  void connectWebSocket({
    required String screenId,
    required Function(String, dynamic) onMessage,
  }) {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://192.168.0.15:8000/ws', // Адрес вашего STOMP-сервера
        onConnect: (StompFrame frame) {
          print('Connected to STOMP');
          // Подписываемся на сообщения, которые сервер отправляет клиенту
          _stompClient?.subscribe(
            destination: '/topic/screen/$screenId',
            callback: (StompFrame frame) {
              try {
                final data = jsonDecode(frame.body ?? '{}');
                final type = data['type'];
                final content = data['content'];
                onMessage(type, content);
              } catch (e) {
                print('STOMP message parse error: $e');
              }
            },
          );
        },
        onStompError: (frame) => print('STOMP Error: ${frame.body}'),
        onWebSocketError: (error) => print('WebSocket Error: $error'),
        onDisconnect: (frame) => print('Disconnected'),
        onDebugMessage: (message) => print('Debug: $message'),
      ),
    );

    _stompClient?.activate();
  }

  void disconnectWebSocket() {
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
