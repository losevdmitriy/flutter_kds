import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_iem_new/src/service/web_socket_service.dart';
import '../dto/orderItemDto.dart';

class ChefScreenPage extends StatefulWidget {
  final String initialScreenId;
  final String name;

  const ChefScreenPage({
    Key? key,
    required this.initialScreenId,
    required this.name,
  }) : super(key: key);

  @override
  _ChefScreenPageState createState() => _ChefScreenPageState();
}

class _ChefScreenPageState extends State<ChefScreenPage> {
  static const Color COLOR_IN_PROGRESS = Colors.lightBlue;
  static const Color COLOR_COOKING_WARNING = Color(0xffff6969);

  final WebSocketService _webSocketService = WebSocketService();
  final ScrollController _scrollController = ScrollController();

  List<OrderItemDto> orders = [];
  Timer? _timer;
  Timer? _reconnectTimer;
  bool isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialScreenId.isNotEmpty) {
      _connectToWebSocket(widget.initialScreenId);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
    });

    _reconnectTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _refreshOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reconnectTimer?.cancel();
    _webSocketService.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectToWebSocket(String screenId) {
    _webSocketService.connect(
      screenId: screenId,
      onMessage: (String type, dynamic payload) {
        switch (type) {
          case 'NOTIFICATION':
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload.toString())),
            );
            FlutterRingtonePlayer().play(ios: IosSounds.electronic, android: AndroidSounds.notification);
            if (_isConnected) {
              _webSocketService.sendGetAllOrderItems(screenId);
            }
            break;
          case 'REFRESH':
            if (_isConnected) {
              _webSocketService.sendGetAllOrderItems(screenId);
            }
            break;
          case 'GET_ALL_ORDER_ITEMS':
            if (!mounted) return;
            setState(() {
              orders = (payload as List<dynamic>)
                  .map((e) => OrderItemDto.fromJson(e))
                  .toList();
              isLoading = false;
            });
            break;
          default:
            debugPrint('Unknown message type: $type');
        }
      },
      onConnect: () {
        if (!mounted) return;
        setState(() {
          _isConnected = true;
        });
        _webSocketService.sendGetAllOrderItems(screenId);
      },
      onDisconnect: () {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
        });
      },
    );
  }

  void _refreshOrders() {
    _webSocketService.disconnect();
    if (widget.initialScreenId.isNotEmpty) {
      _connectToWebSocket(widget.initialScreenId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _refreshOrders,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
            tooltip: 'Обновить или переподключиться',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildOrdersArea(),
    );
  }

  Widget _buildOrdersArea() {
    if (orders.isEmpty) {
      return const Center(child: Text("Заказов нет"));
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 10.0,
      radius: const Radius.circular(4.0),
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 8), // Увеличиваем отступ справа
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.95,
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final item = orders[index];
          return _buildOrderCard(item);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderItemDto item) {
    final elapsedSeconds = DateTime.now().difference(item.createdAt).inSeconds;

    Color backgroundColor = Colors.white;
    String timeLabel;

    if (item.status == OrderItemStationStatus.STARTED) {
      backgroundColor = COLOR_IN_PROGRESS;
      timeLabel = "Готовка: $elapsedSeconds сек";
      if (elapsedSeconds > item.timeToCook) {
        backgroundColor = COLOR_COOKING_WARNING;
      }
    } else {
      timeLabel = "Ожидание: $elapsedSeconds сек";
    }

    return GestureDetector(
      onTap: () => _onOrderTap(item),
      child: Card(
        color: backgroundColor,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${item.orderName}: ${item.name}",
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.08,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.ingredients.map((ingredient) {
                          return Text(
                            "- ${ingredient.name}",
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.06,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onOrderTap(OrderItemDto item) async {
    if (!_isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет соединения с сервером')),
      );
      return;
    }

    try {
      _webSocketService.sendUpdateOrder(widget.initialScreenId, item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления статуса: $e")),
      );
    }
  }
}
