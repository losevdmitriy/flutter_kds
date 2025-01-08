import 'dart:async';
import 'package:flutter/material.dart';
import 'dto/orderItemDto.dart'; // ваши модели
import 'web_socket_service.dart'; // ваш WebSocket сервис

class ChefScreenPage extends StatefulWidget {
  final String initialScreenId;
  final String name;

  const ChefScreenPage(
      {super.key, required this.initialScreenId, required this.name});

  @override
  _ChefScreenPageState createState() => _ChefScreenPageState();
}

class _ChefScreenPageState extends State<ChefScreenPage> {
  static const Color COLOR_IN_PROGRESS = Colors.lightBlue;
  static const Color COLOR_WAITING_WARNING = Colors.orange;
  static const int SECONDS_WAITING_WARNING = 20;
  static const Color COLOR_COOKING_WARNING = Color(0xffff6969);
  static const int SECONDS_COOKING_WARNING = 30;

  final WebSocketService _webSocketService = WebSocketService();
  late TextEditingController _screenIdController;
  List<OrderItemDto> orders = [];
  Timer? _timer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _screenIdController = TextEditingController(text: widget.initialScreenId);

    if (widget.initialScreenId.isNotEmpty) {
      _connectToWebSocket(widget.initialScreenId);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webSocketService.disconnect();
    _screenIdController.dispose();
    super.dispose();
  }

  void _connectToWebSocket(String screenId) {
    _webSocketService.connect(
      screenId: screenId,
      onMessage: (String type, dynamic payload) {
        switch (type) {
          case 'NOTIFICATION':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload.toString())),
            );
            _webSocketService.sendGetAllOrderItems(screenId);
            break;
          case 'GET_ALL_ORDER_ITEMS':
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
        // Отправляем запрос на получение всех заказов после успешного подключения
        _webSocketService.sendGetAllOrderItems(screenId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _buildOrdersArea(),
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersArea() {
    if (orders.isEmpty) {
      return const Center(child: Text("Заказов нет"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
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
    );
  }

  Widget _buildOrderCard(OrderItemDto item) {
    final elapsedSeconds = DateTime.now().difference(item.createdAt).inSeconds;

    Color backgroundColor = Colors.white;
    String timeLabel;
    if (item.status == OrderItemStationStatus.STARTED) {
      backgroundColor = COLOR_IN_PROGRESS;
      timeLabel = "Готовка: $elapsedSeconds сек";
      if (elapsedSeconds > SECONDS_COOKING_WARNING) {
        backgroundColor = COLOR_COOKING_WARNING;
      }
    } else {
      timeLabel = "ожидание: $elapsedSeconds сек";
      if (elapsedSeconds > SECONDS_WAITING_WARNING) {
        backgroundColor = COLOR_WAITING_WARNING;
      }
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
                    "Заказ #${item.orderId}: ${item.name}",
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
                          return Text("- ${ingredient.name}",
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.06,
                              ));
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
    try {
      _webSocketService.sendUpdateOrder(widget.initialScreenId, item.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления статуса: $e")),
      );
    }
  }
}
