import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  StompClient? _stompClient;

  /// Подключение к WebSocket
  void connect({
    required String screenId,
    required Function(String type, dynamic payload) onMessage,
    Function? onConnect,
  }) {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8000/ws', // Адрес STOMP WebSocket-сервера
        onConnect: (StompFrame frame) {
          print('Connected to WebSocket');
          // Подписываемся на уведомления
          _subscribeToNotifications(screenId, onMessage);
          // Подписываемся на заказы
          _subscribeToOrders(screenId, onMessage);
          if (onConnect != null) {
            onConnect();
          }
        },
        onStompError: (StompFrame frame) {
          print('STOMP error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
        },
        onDisconnect: (StompFrame frame) {
          print('Disconnected from WebSocket');
        },
        onDebugMessage: (String message) {
          print('WebSocket debug: $message');
        },
      ),
    );

    _stompClient?.activate();
  }

  /// Подписка на уведомления
  void _subscribeToNotifications(
      String screenId, Function(String type, dynamic payload) onMessage) {
    final destination = '/topic/screen.notification/$screenId';
    _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        try {
          if (frame.body != null) {
            final data = jsonDecode(frame.body!);
            final type = data['type']; // e.g., "NEW_ORDER", "NOTIFICATION"
            final payload = data['payload'];
            onMessage(type, payload);
          }
        } catch (e) {
          print('Error parsing notification message: $e');
        }
      },
    );
    print('Subscribed to $destination');
  }

  /// Подписка на заказы
  void _subscribeToOrders(
      String screenId, Function(String type, dynamic payload) onMessage) {
    final destination = '/topic/screen.orders/$screenId';
    _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        try {
          if (frame.body != null) {
            final data = jsonDecode(frame.body!);
            final type = data['type']; // Тип для обновления списка заказов
            final payload =
                data['payload']; // Предполагаем, что это список заказов
            onMessage(type, payload);
          }
        } catch (e) {
          print('Error parsing orders message: $e');
        }
      },
    );
    print('Subscribed to $destination');
  }

  /// Отправка сообщения (например, для обновления статуса заказа)
  void sendUpdateOrder(String screenId, int orderItemId) {
    final destination =
        '/app/topic/screen/$screenId/update.orderItem/$orderItemId';
    _stompClient?.send(destination: destination, body: '');
    print('Sent update order request for item $orderItemId');
  }

  /// Отправка сообщения (например, для обновления статуса заказа)
  void sendGetAllOrderItems(String screenId) {
    final destination = '/app/topic/screen.getAllOrders/$screenId';
    if (_stompClient == null) {
      throw Exception("WebSocket client is not activated.");
    }
    _stompClient?.send(destination: destination, body: '');
    print('Sent get all order items request for screen id $screenId');
  }

  /// Отправка сообщения для обновления статуса всех позиций заказа
  void sendUpdateOrderToDone(String screenId, int orderId) {
    final destination =
        '/app/topic/screen/$screenId/update.order.done/$orderId';
    _stompClient?.send(destination: destination, body: '');
    print('Sent update order to done for order $orderId');
  }

  /// Отключение от WebSocket
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
