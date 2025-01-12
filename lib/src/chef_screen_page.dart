import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Добавьте этот импорт
import 'dart:async';

import 'models.dart';    // ваши модели
import 'api_service.dart'; // ваш сервис

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
  static const Color COLOR_WAITING_WARNING = Colors.orange;
  static const int SECONDS_WAITING_WARNING = 20;
  static const Color COLOR_COOKING_WARNING = Color(0xffff6969);
  static const int SECONDS_COOKING_WARNING = 30;

  final ApiService apiService = ApiService();

  /// Контроллер для поля ввода screenId
  late TextEditingController _screenIdController;

  int? stationId;
  List<OrderItemDto> orders = [];

  // Храним предыдущий список заказов, чтобы понять, появились ли новые
  List<OrderItemDto> _oldOrders = [];

  Timer? _timer;

  // Поля для аудио
  late AudioCache _audioCache;

  @override
  void initState() {
    super.initState();  

    // Инициализируем аудио-кэш. 
    // При необходимости можно и AudioPlayer использовать, но для коротких звуков AudioCache удобнее.
    _audioCache = AudioCache(prefix: 'assets/sounds/eventually.mp3');

    // Изначально заполним TextField значением из конструктора
    _screenIdController = TextEditingController(text: widget.initialScreenId);

    // Запросим данные, если initialScreenId не пуст
    if (widget.initialScreenId.isNotEmpty) {
      _loadStationAndOrders(widget.initialScreenId);
    }

    // Таймер, чтобы каждую секунду обновлять "таймер" готовки
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    apiService.disconnectWebSocket();
    _screenIdController.dispose();
    super.dispose();
  }

  Future<void> _loadStationAndOrders(String screenId) async {
    apiService.disconnectWebSocket(); // Отключаем предыдущий сокет, если был

    final stId = await apiService.getStationId(screenId);
    if (stId == null) {
      setState(() {
        stationId = null;
        orders.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Такого screenId не существует")),
      );
      return;
    }
    stationId = stId;

    // Подключаемся к WebSocket
    apiService.connectWebSocket(
      screenId: screenId,
      onMessage: (type, content) {
        if (type == 'REFRESH_PAGE') {
          // Когда сервер просит рефреш, мы снова загружаем заказы
          _refreshPage(screenId);
        } else if (type == 'NOTIFICATION') {
          // Показываем сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(content.toString())),
          );
        }
      },
    );

    _refreshPage(screenId);
  }

  Future<void> _refreshPage(String screenId) async {
    if (stationId == null) return;
    try {
      // Загружаем новый список
      final list = await apiService.getScreenOrderItems(screenId);

      // Сравниваем, появились ли новые заказы (по количеству)
      // Можно и глубже сравнивать, если нужно понимать, какие именно заказы добавились
      final bool hasNewOrder = list.length > orders.length;

      setState(() {
        _oldOrders = orders; // запоминаем старые заказы
        orders = list;       // заменяем на новые
      });

      // Если новые заказы появились, проиграем звук
      if (hasNewOrder) {
        _playNotificationSound();
      }
    } catch (e) {
      debugPrint("Failed to load orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не удалось загрузить заказы")),
      );
    }
  }

  /// Воспроизводит короткий звуковой сигнал
void _playNotificationSound() async {
  final player = AudioPlayer();
  await player.play(AssetSource('assets/notification.wav'));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildOrdersArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersArea() {
    if (stationId == null) {
      return const Center(
        child: Text("Станция не определена. Введите screenId.")
      );
    }

    if (orders.isEmpty) {
      return const Center(child: Text("Заказов нет"));
    }

    // Пример: 3-колоночная сетка
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
      timeLabel = "Время готовки: $elapsedSeconds сек";
      if (elapsedSeconds > SECONDS_COOKING_WARNING) {
        backgroundColor = COLOR_COOKING_WARNING;
      }
    } else {
      // ADDED
      timeLabel = "Время ожидания: $elapsedSeconds сек";
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
              // Можно посмотреть размер плитки и подстроить текст
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
                  // Список ингредиентов
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.ingredients.map((ingredient) {
                          if (ingredient.stationId == stationId ||
                              ingredient.stationId == null) {
                            return Text(
                              "- ${ingredient.name}",
                              style: TextStyle(
                                fontSize: constraints.maxWidth * 0.06,
                              ),
                            );
                          }
                          return Container();
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
      await apiService.updateStatus(item.id);
      _refreshPage(_screenIdController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления статуса: $e")),
      );
    }
  }
}
