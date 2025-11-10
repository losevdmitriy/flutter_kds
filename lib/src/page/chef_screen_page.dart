import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/orderFullDto.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_iem_new/src/service/web_socket_service.dart';
import '../dto/orderItemDto.dart';
import 'collector_screen_page.dart';

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
              // Обновляем _processingOrders: удаляем элементы, которые обновились или исчезли
              _processingOrders = _processingOrders.where((processingOrder) {
                // Ищем соответствующий элемент в новых данных
                OrderItemDto? currentItem;
                for (var order in allOrders) {
                  for (var item in order.items) {
                    if (item.id == processingOrder.id) {
                      currentItem = item;
                      break;
                    }
                  }
                  if (currentItem != null) break;
                }
                
                // Для COMPLETED items: если элемент не найден в новых данных - удаляем из processing
                if (processingOrder.status == OrderItemStationStatus.COMPLETED) {
                  return currentItem != null;
                }
                
                // Для остальных: если элемент не найден в новых данных - удаляем из processing
                if (currentItem == null) {
                  return false;
                }
                
                // Если статус совпадает с тем что пришло с сервера - удаляем из processing
                if (currentItem.status == processingOrder.status) {
                  return false;
                }
                
                // Иначе оставляем в processing
                return true;
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
    final kitchenGotOrderAt = order.kitchenGotOrderAt ?? order.kitchenShouldGetOrderAt;
    final totalTime = order.shouldBeFinishedAt.difference(kitchenGotOrderAt).inMinutes;
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
          TextButton.icon(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorScreenPage(
                    initialScreenId: '4', // ID станции коллектора
                    fromChefScreen: true,
                  ),
                ),
              );
            },
            label: const Text('Все заказы'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
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
    
    // Добавляем processing items с обновленными статусами
    final List<OrderItemDto> processingItemsToShow = _processingOrders
        .where((item) => item.status != OrderItemStationStatus.COMPLETED) // Не показываем COMPLETED
        .toList();
    
    // Объединяем списки, исключая дубликаты
    final Map<int, OrderItemDto> allItemsMap = {};
    
    // Сначала добавляем обычные items
    for (var item in orderItems) {
      allItemsMap[item.id] = item;
    }
    
    // Затем перезаписываем processing items (они имеют приоритет)
    for (var item in processingItemsToShow) {
      allItemsMap[item.id] = item;
    }
    
    final List<OrderItemDto> finalOrderItems = allItemsMap.values.toList();

    if (allOrders.isEmpty || finalOrderItems.isEmpty) {
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
            itemCount: finalOrderItems.length,
            itemBuilder: (context, index) {
              final item = finalOrderItems[index];
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
    final isProcessing = _processingOrders.any((p) => p.id == item.id);

    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    String timeLabel;

    if (item.status == OrderItemStationStatus.STARTED) {
      borderColor = COLOR_IN_PROGRESS;
      backgroundColor = COLOR_IN_PROGRESS.withOpacity(0.1); // Легкий голубой фон
      timeLabel = "Готовка: $elapsedSeconds сек";
      if (elapsedSeconds > item.timeToCook) {
        borderColor = COLOR_IN_PROGRESS; //COLOR_COOKING_WARNING;
        backgroundColor = COLOR_IN_PROGRESS.withOpacity(0.15); // Чуть более насыщенный фон при превышении времени
      }
    } else {
      timeLabel = "Ожидание: $elapsedSeconds сек";
    }

    return InkWell(
      onTap: isProcessing ? null : () => _onOrderTap(item), // Блокируем нажатие если в обработке
      child: Card(
        color: backgroundColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: borderColor,
            width: 3.0,
          ),
        ),
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
    // Проверяем, не находится ли уже в обработке
    if (_processingOrders.any((p) => p.id == item.id)) {
      return; // Игнорируем повторные нажатия
    }
    
    if (!_isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет соединения с сервером')),
      );
      return;
    }

    // Определяем следующий статус
    OrderItemStationStatus nextStatus;
    if (item.status == OrderItemStationStatus.ADDED) {
      nextStatus = OrderItemStationStatus.STARTED;
    } else if (item.status == OrderItemStationStatus.STARTED) {
      nextStatus = OrderItemStationStatus.COMPLETED;
    } else {
      return; // Для других статусов ничего не делаем
    }

    // Создаем копию item с новым статусом
    final processingItem = OrderItemDto(
      id: item.id,
      orderId: item.orderId,
      orderName: item.orderName,
      name: item.name,
      ingredients: item.ingredients,
      statusUpdatedAt: item.statusUpdatedAt, // Оставляем старый timestamp
      status: nextStatus, // Новый статус
      currentStation: item.currentStation,
      flowStepType: item.flowStepType,
      timeToCook: item.timeToCook,
      extra: item.extra,
    );

    setState(() {
      _processingOrders.add(processingItem);
    });

    // Автоматическая разблокировка через 2 секунды
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _processingOrders.removeWhere((p) => p.id == item.id);
        });
      }
    });

    try {
      _webSocketService.sendUpdateOrder(widget.initialScreenId, item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingOrders.removeWhere((p) => p.id == item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления статуса: $e")),
      );
    }
  }
}
