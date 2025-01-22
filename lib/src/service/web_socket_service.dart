import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  StompClient? _stompClient;

  bool get isConnected => _stompClient?.connected == true;

  void connect({
    required String screenId,
    required Function(String type, dynamic payload) onMessage,
    Function? onConnect,
    Function? onDisconnect,
  }) {
    // Если уже подключено - return
    if (_stompClient?.connected == true) {
      print('[WebSocketService] Already connected, skip.');
      return;
    }
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://192.168.0.15:8000/ws',
        onConnect: (StompFrame frame) {
          print('Connected to WebSocket');
          // Подписываемся
          _subscribeToNotifications(screenId, onMessage);
          _subscribeToOrders(screenId, onMessage);
          _subscribeToRefreshAll(onMessage);
          onConnect?.call();
        },
        onDisconnect: (StompFrame frame) {
          print('Disconnected from WebSocket');
          onDisconnect?.call();
        },
        onStompError: (StompFrame frame) {
          print('STOMP error: ${frame.body}');
          // Обычно после ошибки - отключаемся
          onDisconnect?.call();
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
          onDisconnect?.call();
        },
        onDebugMessage: (String message) {
          print('WebSocket debug: $message');
        },
      ),
    );

    _stompClient?.activate();
  }

  void _subscribeToNotifications(
    String screenId,
    Function(String type, dynamic payload) onMessage,
  ) {
    _stompClient?.subscribe(
      destination: '/topic/screen.notification/$screenId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          onMessage(data['type'], data['payload']);
        }
      },
    );
  }

  void _subscribeToRefreshAll(
    Function(String type, dynamic payload) onMessage,
  ) {
    _stompClient?.subscribe(
      destination: '/topic/screen.refresh',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          onMessage(data['type'], data['payload']);
        }
      },
    );
  }

  void _subscribeToOrders(
    String screenId,
    Function(String type, dynamic payload) onMessage,
  ) {
    _stompClient?.subscribe(
      destination: '/topic/screen.orders/$screenId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          onMessage(data['type'], data['payload']);
        }
      },
    );
  }

  bool _canSend() {
    return _stompClient != null && _stompClient!.connected;
  }

  void sendGetAllOrderItems(String screenId) {
    if (!_canSend()) {
      print('[sendGetAllOrderItems] Not connected -> skip');
      return;
    }
    final destination = '/app/topic/screen.getAllOrders/$screenId';
    _stompClient!.send(destination: destination, body: '');
  }

  void sendUpdateOrder(String screenId, int orderItemId) {
    if (!_canSend()) {
      print('[sendUpdateOrder] Not connected -> skip');
      return;
    }
    final destination =
        '/app/topic/screen/$screenId/update.orderItem/$orderItemId';
    _stompClient!.send(destination: destination, body: '');
  }

  void sendGetAllOrdersWithItems(String screenId) {
    if (!_canSend()) {
      print('[sendGetAllOrdersWithItems] Not connected -> skip');
      return;
    }
    final destination = '/app/topic/screen.getAllOrdersWithItems';
    _stompClient!.send(destination: destination, body: '');
  }

  void sendUpdateAllOrderToDone(String screenId, int orderId) {
    if (!_canSend()) {
      print('[sendUpdateAllOrderToDone] Not connected -> skip');
      return;
    }
    final destination =
        '/app/topic/screen/$screenId/update.allOrder.done/$orderId';
    _stompClient!.send(destination: destination, body: '');
  }

  void disconnect() {
    if (_stompClient != null) {
      print('[WebSocketService] Deactivating client...');
      _stompClient!.deactivate();
      _stompClient = null;
    }
  }
}
