import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/orderFullDto.dart';
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
  static const Color COLOR_PROCESSING = Colors.grey;

  final WebSocketService _webSocketService = WebSocketService();
  final ScrollController _scrollController = ScrollController();

  List<OrderFullDto> allOrders = [];
  Timer? _timer;
  Timer? _reconnectTimer;
  bool isLoading = true;
  bool _isConnected = false;
  Set<OrderItemDto> _processingOrders = {};

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
            FlutterRingtonePlayer().play(
                ios: IosSounds.electronic, android: AndroidSounds.notification);
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
              allOrders = (payload as List<dynamic>)
                  .map((e) => OrderFullDto.fromJson(e))
                  .toList();
              _processingOrders = _processingOrders.where((processingOrder) {
                return allOrders.every((order) => order.items.every((item) =>
                  !processingOrder.statusUpdatedAt.isBefore(item.statusUpdatedAt)
                ));
              }).toSet();
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

  Widget _buildTimeIndicator(OrderFullDto order) {
    final totalTime = order.shouldBeFinishedAt.difference(order.kitchenGotOrderAt).inMinutes;
    final remainingTime = order.shouldBeFinishedAt.difference(DateTime.now()).inMinutes;
    final elapsedTime = totalTime - remainingTime;

    return Column(
      children: [
        SizedBox(
          width: 40.0,
          height: 40.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: (elapsedTime / totalTime).clamp(0.0, 1.0),
                strokeWidth: 5.0,
                backgroundColor: Colors.blue[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingTime > 0 ? const Color(0xFFE0E0E0) : Colors.red,
                ),
              ),
              Text(
                '$remainingTime',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: remainingTime > 0 ? Colors.black : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "№ ${order.name}",
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Строка с таймерами заказов
  Widget _buildTimerRow() {
    if (allOrders.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allOrders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildTimeIndicator(allOrders[index]),
          );
        },
      ),
    );
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
          : Column(
        children: [
          _buildTimerRow(), // Добавляем строку с таймерами
          Expanded(child: _buildOrdersArea()), // Основная область заказов
        ],
      ),
    );
  }

  Widget _buildOrdersArea() {
    final List<OrderItemDto> orderItems = allOrders
        .expand((order) => order.items)
        .toList();

    if (allOrders.isEmpty || orderItems.isEmpty) {
      return const Center(child: Text("Заказов нет"));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Область сетки
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemCount: orderItems.length,
            itemBuilder: (context, index) {
              final item = orderItems[index];
              return _buildOrderCard(item);
            },
          ),
        ),
        // Кнопки справа
        SizedBox(
          width: 60, // Фиксированная ширина для кнопок
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка "Вверх"
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: FloatingActionButton(
                  mini: true, // Уменьшенный размер кнопки
                  onPressed: () {
                    if (_scrollController.hasClients && _scrollController.offset > 0) {
                      _scrollController.animateTo(
                        _scrollController.offset - 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  tooltip: 'Прокрутить вверх',
                  child: const Icon(Icons.arrow_upward),
                ),
              ),
              // Кнопка "Вниз"
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: FloatingActionButton(
                  mini: true, // Уменьшенный размер кнопки
                  onPressed: () {
                    if (_scrollController.hasClients &&
                        _scrollController.offset < _scrollController.position.maxScrollExtent) {
                      _scrollController.animateTo(
                        _scrollController.offset + 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  tooltip: 'Прокрутить вниз',
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderItemDto item) {
    final elapsedSeconds = DateTime.now().difference(item.statusUpdatedAt).inSeconds;
    final isProcessing = _processingOrders.contains(item);

    Color backgroundColor = Colors.white;
    String timeLabel;

    if (isProcessing) {
      backgroundColor = COLOR_PROCESSING;
      timeLabel = "Загрузка...";
    } else if (item.status == OrderItemStationStatus.STARTED) {
      backgroundColor = COLOR_IN_PROGRESS;
      timeLabel = "Готовка: $elapsedSeconds сек";
      if (elapsedSeconds > item.timeToCook) {
        backgroundColor = COLOR_IN_PROGRESS; //COLOR_COOKING_WARNING;
      }
    } else {
      timeLabel = "Ожидание: $elapsedSeconds сек";
    }

    return InkWell(
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
                    "№${item.orderName}: ${item.name}",
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

    setState(() {
      _processingOrders.add(item);
    });

    try {
      _webSocketService.sendUpdateOrder(widget.initialScreenId, item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingOrders.remove(item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления статуса: $e")),
      );
    }
  }
}
