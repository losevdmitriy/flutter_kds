import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/service/web_socket_service.dart';
import '../dto/orderFullDto.dart';
import '../dto/orderItemDto.dart';

class CollectorScreenPage extends StatefulWidget {
  final String initialScreenId;

  const CollectorScreenPage({Key? key, required this.initialScreenId})
      : super(key: key);

  @override
  State<CollectorScreenPage> createState() => _CollectorScreenPageState();
}

class _CollectorScreenPageState extends State<CollectorScreenPage> {
  final WebSocketService webSocketService = WebSocketService();

  List<OrderFullDto> allOrders = [];
  final Map<int, bool> itemClickedState = {};

  Timer? _timer;
  Timer? _reconnectTimer;
  bool _isFirstBuild = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Таймер для обновления UI
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {}); // Просто перерисовка каждую секунду
    });
    _reconnectTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _reconnect();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _connectToWebSocket(widget.initialScreenId);
      _isFirstBuild = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reconnectTimer?.cancel();
    webSocketService.disconnect();
    super.dispose();
  }

  void _connectToWebSocket(String screenId) {
    webSocketService.connect(
      screenId: screenId,
      onMessage: (String type, dynamic payload) {
        if (!mounted) return;
        switch (type) {
          case 'NOTIFICATION':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload.toString())),
            );
            if (_isConnected) {
              webSocketService.sendGetAllOrdersWithItems();
            }
            break;
          case 'REFRESH':
            if (_isConnected) {
              webSocketService.sendGetAllOrdersWithItems();
            }
            break;
          case 'GET_ALL_ORDERS':
            setState(() {
              allOrders = (payload as List<dynamic>)
                  .map((e) => OrderFullDto.fromJson(e))
                  .toList();
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
        webSocketService.sendGetAllOrdersWithItems();
      },
      onDisconnect: () {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
        });
      },
    );
  }

  void _reconnect() {
    webSocketService.disconnect();
    _connectToWebSocket(widget.initialScreenId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Screen'),
        actions: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
            tooltip: 'Переподключиться',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (allOrders.isEmpty) {
      return const Center(
        child: Text('Нет заказов в системе'),
      );
    }

    // Горизонтальная прокрутка по заказам
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allOrders
            .map((orderDto) => _buildOrderColumn(orderDto))
            .where((col) => col != null)
            .cast<Widget>()
            .toList(),
      ),
    );
  }

Widget? _buildOrderColumn(OrderFullDto orderDto) {
  final filteredItems = orderDto.items.where((item) {
    return item.status != OrderItemStationStatus.CANCELED &&
        item.status != OrderItemStationStatus.COMPLETED &&
        item.flowStepType != 'FINAL_STEP' &&
        !item.extra;
  }).toList();

  if (filteredItems.isEmpty) {
    return null;
  }

  // Проверяем, находятся ли ВСЕ позиции НЕ на станции 4
  bool allItemsNotAtStation4 = orderDto.items.every((item) => item.currentStation.id == 4);

  // Фильтруем позиции, у которых extra == true
  final extraItems = orderDto.items.where((item) => item.extra).toList();

  // Группируем и считаем количество повторений
  Map<String, int> extraCounts = {};
  for (var item in extraItems) {
    extraCounts[item.name] = (extraCounts[item.name] ?? 0) + 1;
  }

  return Container(
    width: 300,
    margin: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.15), blurRadius: 6)],
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              Text(
                'Заказ #${orderDto.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Показываем кнопку только если ВСЕ позиции НЕ на станции 4
              if (allItemsNotAtStation4)
                ElevatedButton(
                  onPressed: () async {
                    if (!_isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Нет соединения с сервером')),
                      );
                      return;
                    }
                    webSocketService.sendUpdateAllOrderToDone(
                      widget.initialScreenId,
                      orderDto.id,
                    );
                    await _refreshPage();
                  },
                  child: Text('Заказ собран'),
                ),
              // Вывод списка extra-позиций, если они есть
              if (extraCounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: extraCounts.entries.map((entry) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start, // Выравнивание влево
                        children: [
                          Text(
                            'x${entry.value} ', // Количество жирным
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            entry.key, // Название обычным шрифтом
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: filteredItems.map(_buildItemTile).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildItemTile(OrderItemDto item) {
    //TODO Добавить ENUM
    final canTap = (item.currentStation.id == 4);
    final elapsedSeconds = DateTime.now().difference(item.createdAt).inSeconds;
    final tileColor = (item.status == OrderItemStationStatus.STARTED &&
            item.currentStation.id == 4)
        ? Colors.yellow.shade100
        : canTap
            ? Colors.white
            : Colors.grey.shade200;

    return GestureDetector(
      onTap: canTap
          ? () async {
              if (!_isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Нет соединения с сервером'),
                  ),
                );
                return;
              }
              // "двойной клик"
              final currentlyClicked = itemClickedState[item.id] ?? false;
              if (!currentlyClicked) {
                setState(() {
                  itemClickedState[item.id] = true;
                });
                webSocketService.sendUpdateOrder(
                  widget.initialScreenId,
                  item.id,
                );
              } else {
                webSocketService.sendUpdateOrder(
                  widget.initialScreenId,
                  item.id,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Позиция собрана: ${item.name}')),
                );
                setState(() {
                  itemClickedState.remove(item.id);
                });
                await _refreshPage();
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileColor,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Станция: ${item.currentStation.name}'),
            Text('На этой станции: $elapsedSeconds сек'),
            if (!canTap)
              const Text(
                'Еще не готов к сборке',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPage() async {
    webSocketService.disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    _connectToWebSocket(widget.initialScreenId);
    webSocketService.sendGetAllOrdersWithItems();
  }
}
