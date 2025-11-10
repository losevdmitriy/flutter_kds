import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_iem_new/src/service/web_socket_service.dart';
import 'package:flutter_iem_new/src/config/api_config.dart';
import '../dto/orderFullDto.dart';
import '../dto/orderItemDto.dart';

class CollectorScreenPage extends StatefulWidget {
  final String initialScreenId;
  final bool fromChefScreen;

  const CollectorScreenPage({
    Key? key,
    required this.initialScreenId,
    this.fromChefScreen = false,
  }) : super(key: key);

  @override
  State<CollectorScreenPage> createState() => _CollectorScreenPageState();
}

class _CollectorScreenPageState extends State<CollectorScreenPage> {
  final WebSocketService webSocketService = WebSocketService();

  List<OrderFullDto> allOrders = [];
  List<OrderFullDto> historyOrders = [];
  bool _showHistory = false;

  Timer? _timer;
  Timer? _reconnectTimer;
  bool _isFirstBuild = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket(widget.initialScreenId);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
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
              webSocketService.sendGetAllOrdersWithItems(screenId);
            }
            break;
          case 'REFRESH':
            if (_isConnected) {
              webSocketService.sendGetAllOrdersWithItems(screenId);
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
        webSocketService.sendGetAllOrdersWithItems(screenId);
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
        automaticallyImplyLeading: !widget.fromChefScreen,
        leading: widget.fromChefScreen
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Collector Screen'),
        actions: [
          TextButton.icon(
            icon: Icon(_showHistory ? Icons.list : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
                if (_showHistory && historyOrders.isEmpty) {
                  _loadHistoryOrders();
                }
              });
            },
            label: Text(_showHistory ? 'Вернуться ко всем заказам' : 'Открыть историю заказов'),
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
            onPressed: _reconnect,
            tooltip: 'Переподключиться',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final ordersToShow = _showHistory ? historyOrders : allOrders;
    
    if (ordersToShow.isEmpty) {
      return const Center(
        child: Text('Нет заказов'),
      );
    }

    // Горизонтальная прокрутка по заказам
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ordersToShow
            .map((orderDto) => _buildOrderColumn(orderDto, isHistory: _showHistory))
            .where((col) => col != null)
            .cast<Widget>()
            .toList(),
      ),
    );
  }

Widget? _buildOrderColumn(OrderFullDto orderDto, {bool isHistory = false}) {
  // Для истории показываем все блюда (кроме допов)
  final filteredItems = orderDto.items.where((item) {
    if (isHistory) {
      return !item.extra; // Показываем только основные блюда, без допов
    }
    return item.status != OrderItemStationStatus.CANCELED &&
        !item.extra;
  }).toList();

  // Для истории не показываем время, для активных - оставшееся время
  final String timeInfo;
  if (isHistory) {
    timeInfo = ""; // Для истории не показываем время
  } else {
  final remainingTime = orderDto.shouldBeFinishedAt.difference(DateTime.now()).inMinutes;
    timeInfo = remainingTime > 0 ? 'Осталось $remainingTime мин' : "Опаздываем на $remainingTime мин";
  }

  if (filteredItems.isEmpty) {
    return null;
  }

  // Проверяем, находятся ли ВСЕ позиции на станции 4
  bool allItemsAtStation4 = filteredItems.isNotEmpty && 
      filteredItems.every((item) => item.currentStation.id == 4);

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
                'Заказ #${orderDto.name} [${filteredItems.length}]',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (timeInfo.isNotEmpty)
              Text(
                  timeInfo,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 8),
              // Показываем кнопку только если ВСЕ позиции на станции 4 (для активных) или для истории
              if (isHistory || allItemsAtStation4)
                ElevatedButton(
                  onPressed: () {
                    if (!_isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Нет соединения с сервером')),
                      );
                      return;
                    }
                    if (isHistory) {
                      _showReturnItemsDialog(orderDto);
                    } else {
                    webSocketService.sendUpdateAllOrderToDone(
                      widget.initialScreenId,
                      orderDto.id,
                    );
                    }
                  },
                  child: Text(isHistory ? 'Вернуть' : 'Заказ собран'),
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
    final canTap = (item.currentStation.id == 4) && (item.status == OrderItemStationStatus.ADDED);
    final elapsedSeconds = DateTime.now().difference(item.statusUpdatedAt).inSeconds;
    
    // Определяем цвет тайла: желтый для STARTED, зеленый для добавленных, серый для остальных
    Color tileColor;
    if (item.status != OrderItemStationStatus.ADDED && item.currentStation.id == 4) {
      tileColor = Colors.yellow.shade100;
    } else if (canTap && item.status == OrderItemStationStatus.ADDED) {
      tileColor = const Color.fromARGB(255, 0, 255, 64);
    } else {
      tileColor = Colors.grey.shade200;
    }

    String status = "";
    if (item.status == OrderItemStationStatus.COOCKING) {
      status = "Готовится";
    } else if (item.status == OrderItemStationStatus.STARTED) {
      status = "В работе";
    } else if (item.status == OrderItemStationStatus.ADDED) {
      status = "Ожидает";
    } else if (item.status == OrderItemStationStatus.COMPLETED) {
      status = "Завершен";
    } else if (item.status == OrderItemStationStatus.CANCELED) {
      status = "Отменен";
    }

    return GestureDetector(
      onTap: canTap
          ? () {
              if (!_isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Нет соединения с сервером'),
                  ),
                );
                return;
              }
              
              // Локально обновляем статус элемента в списке
                setState(() {
                final ordersToUpdate = _showHistory ? historyOrders : allOrders;
                for (var order in ordersToUpdate) {
                  for (var orderItem in order.items) {
                    if (orderItem.id == item.id && orderItem.status == OrderItemStationStatus.ADDED) {
                      // Создаем новый OrderItemDto с обновленным статусом
                      final updatedOrderItem = OrderItemDto(
                        id: orderItem.id,
                        orderId: orderItem.orderId,
                        orderName: orderItem.orderName,
                        name: orderItem.name,
                        ingredients: orderItem.ingredients,
                        statusUpdatedAt: DateTime.now(),
                        status: OrderItemStationStatus.STARTED,
                        currentStation: orderItem.currentStation,
                        flowStepType: orderItem.flowStepType,
                        timeToCook: orderItem.timeToCook,
                        extra: orderItem.extra,
                      );
                      
                      // Обновляем список элементов заказа
                      final index = order.items.indexOf(orderItem);
                      if (index != -1) {
                        order.items[index] = updatedOrderItem;
                      }
                      break;
                    }
                  }
                }
              });
              
              // Отправляем обновление статуса позиции на сервер
                webSocketService.sendUpdateOrder(
                  widget.initialScreenId,
                  item.id,
                );
              
              // Показываем уведомление
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Обновлен статус: ${item.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          : null,
      onLongPress: (item.currentStation.id != 4 && 
                      (item.status == OrderItemStationStatus.COOCKING || 
                       item.status == OrderItemStationStatus.ADDED))
          ? () {
              _showConfirmReadyDialog(item);
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
            Text('$status: $elapsedSeconds сек назад'),
            if (!canTap && item.status == OrderItemStationStatus.COOCKING)
              const Text(
                'Еще не готов к сборке',
                style: TextStyle(color: Colors.red),
              )
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistoryOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/orders/history'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          historyOrders = data.map((e) => OrderFullDto.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  void _showConfirmReadyDialog(OrderItemDto item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отметь что готово?'),
        content: Text('Вы хотите отметить "${item.name}" как собранное?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final response = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/api/v1/orders/${item.id}/updateToCollecting'),
                );
                
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} отмечено как собранное'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка при обновлении статуса'),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error updating item to collecting: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ошибка подключения к серверу'),
                  ),
                );
              }
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  void _showReturnItemsDialog(OrderFullDto orderDto) {
    // Фильтруем блюда (исключаем допы)
    final itemsToShow = orderDto.items.where((item) {
      return !item.extra; // Показываем только основные блюда, без допов
    }).toList();
    
    Map<int, bool> selectedItems = {};
    for (var item in itemsToShow) {
      selectedItems[item.id] = true; // По умолчанию все выбраны
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Вернуть блюда из заказа #${orderDto.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itemsToShow.length,
                itemBuilder: (context, index) {
                  final item = itemsToShow[index];
                  return CheckboxListTile(
                    title: Text(item.name),
                    value: selectedItems[item.id] ?? false,
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedItems[item.id] = value ?? false;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final selectedIds = selectedItems.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();
                  
                  if (selectedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите хотя бы одно блюдо')),
                    );
                    return;
                  }
                  
                  // Отправляем запрос на возврат
                  try {
                    final response = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/api/v1/orders/${orderDto.id}/returnItems'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(selectedIds),
                    );
                    
                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Позиции возвращены')),
                      );
                      // Обновляем историю
                      _loadHistoryOrders();
                    }
                  } catch (e) {
                    debugPrint('Error returning items: $e');
                  }
                },
                child: const Text('Вернуть'),
              ),
            ],
          );
        },
      ),
    );
  }
}
