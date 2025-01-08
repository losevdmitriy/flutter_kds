// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'dto/orderFullDto.dart';
// import 'web_socket_service.dart';

// class CollectorScreenPage extends StatefulWidget {
//   const CollectorScreenPage({Key? key}) : super(key: key);

//   @override
//   State<CollectorScreenPage> createState() => _CollectorScreenPageState();
// }

// class _CollectorScreenPageState extends State<CollectorScreenPage> {
//   final ApiService _apiService = ApiService();

//   /// Все заказы (OrderFullDto) с позициями
//   List<OrderFullDto> allOrders = [];

//   /// Храним «состояние клика» (подсветки) по позициям:
//   /// key = orderItemId, value = true, если подсвечена (ожидает второго клика).
//   final Map<int, bool> itemClickedState = {};

//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     // 1) Подписываемся на WebSocket
//     _apiService.connectWebSocket(
//       onMessage: (type, content) {
//         if (type == 'REFRESH_PAGE') {
//           _refreshPage();
//         } else if (type == 'NOTIFICATION') {
//           // Показываем всплывающее сообщение
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(content.toString())),
//           );
//           // Звук можно воспроизвести через плагин audioplayers или подобный
//         }
//       },
//     );

//     // 2) Раз в секунду обновляем состояние, чтобы показывать "время в статусе"
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {});
//     });

//     // 3) Сразу загружаем список
//     _refreshPage();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _apiService.disconnectWebSocket();
//     super.dispose();
//   }

//   Future<void> _refreshPage() async {
//     try {
//       final orders = await _apiService.getAllOrdersWithItems();
//       setState(() {
//         allOrders = orders;
//         itemClickedState.clear();
//       });
//     } catch (e) {
//       debugPrint('Failed to load orders: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Не удалось загрузить заказы")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Collector Screen'),
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (allOrders.isEmpty) {
//       return const Center(
//         child: Text('Нет заказов в системе'),
//       );
//     }

//     // Горизонтальная прокрутка с "колонками" (Row внутри SingleChildScrollView)
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.all(10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: allOrders
//             .map(
//               (orderDto) => _buildOrderColumn(orderDto),
//             )
//             .where((col) => col != null)
//             .cast<Widget>()
//             .toList(),
//       ),
//     );
//   }

//   /// Для каждого заказа строим вертикальную колонку.
//   /// Если после фильтрации позиций (убираем CANCELED / READY) ничего не осталось,
//   /// то не рисуем колонку (вернём null).
//   Widget? _buildOrderColumn(OrderFullDto orderDto) {
//     // 1) Фильтруем позиции: убираем CANCELED и те, у кого статус == READY
//     final filteredItems = orderDto.items.where((item) {
//       return item.status != OrderItemStationStatus.CANCELED &&
//           item.status != OrderItemStationStatus.COMPLETED &&
//           // у вас в Java есть "READY" и "DONE";
//           // в Dart enum их надо точно сопоставить.
//           // Ниже предполагаем, что COMPLETED мапится на READY:
//           // Если у вас "READY" == COOCKING, нужно подправить.
//           // Или вы хотите убрать только READY?
//           // Тогда if item.status != OrderItemStationStatus.READY ...
//           // Скорректируйте под вашу реальную логику:
//           true;
//     }).toList();

//     if (filteredItems.isEmpty) {
//       return null;
//     }

//     // Проверим, все ли позиции уже (CREATED/COOKING) или они "готовы"?
//     // В Vaadin: allOrderItemsReady = нет позиций в CREATED или COOKING
//     // (т.е. все либо DONE, либо ...). В вашем коде enum может отличаться.
//     final allOrderItemsReady = !filteredItems.any((item) {
//       return item.status == OrderItemStationStatus.ADDED ||
//           item.status == OrderItemStationStatus.STARTED ||
//           item.status == OrderItemStationStatus.COOCKING;
//     });

//     return Container(
//       width: 300,
//       margin: const EdgeInsets.only(right: 20),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(color: Colors.black12.withOpacity(0.15), blurRadius: 6),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Заказ #${orderDto.name}',
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           if (allOrderItemsReady) ...[
//             ElevatedButton(
//               onPressed: () async {
//                 try {
//                   await _apiService.updateAllOrderItemsToDone(orderDto.id);
//                   await _refreshPage();
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Ошибка: $e')),
//                   );
//                 }
//               },
//               child: const Text('Заказ собран'),
//             ),
//             const SizedBox(height: 10),
//           ],
//           // Теперь плитки
//           ...filteredItems.map(
//             (item) => _buildItemTile(item),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Аналог buildItemTile:
//   /// - показываем название, станцию, статус, время
//   /// - если station == "СБОР ЗАКАЗА" => двойной клик
//   /// - иначе полупрозрачная
//   Widget _buildItemTile(OrderItemDto item) {
//     // Для удобства считаем "время в статусе" = разница между сейчас и createdAt
//     final elapsedSeconds = DateTime.now().difference(item.createdAt).inSeconds;
//     final isHighlighted = itemClickedState[item.id] == true;

//     // Допустим, в вашем item нет поля currentStationName.
//     // Тогда нужно добавить его в модель (OrderItemDto) или как-то получать.
//     // Здесь предполагаем, что есть item.currentStationName (String).
//     final stationName = item.currentStationName ?? "N/A";

//     final bool isCollectorStation = stationName.toLowerCase() == "сбор заказа";

//     // Если позиция подсвечена, background желтоватый, иначе белый
//     final tileColor = isHighlighted ? Colors.yellow.shade100 : Colors.white;

//     return GestureDetector(
//       onTap: () async {
//         if (!isCollectorStation) {
//           // Станция не "СБОР ЗАКАЗА": ничего не делаем
//           return;
//         }
//         final currentlyClicked = itemClickedState[item.id] ?? false;
//         if (!currentlyClicked) {
//           // Первый клик => подсветим
//           setState(() {
//             itemClickedState[item.id] = true;
//           });
//         } else {
//           // Второй клик => updateStatus + уведомление
//           try {
//             await _apiService.updateStatus(item.id);
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Позиция собрана: ${item.name}')),
//             );
//             // Убираем подсветку и обновляем страницу
//             setState(() {
//               itemClickedState.remove(item.id);
//             });
//             _refreshPage();
//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Ошибка: $e')),
//             );
//           }
//         }
//       },
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.symmetric(vertical: 5),
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: tileColor,
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         // Если станция не "СБОР ЗАКАЗА" -> opacity 0.7
//         child: Opacity(
//           opacity: isCollectorStation ? 1.0 : 0.7,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Позиция: ${item.name}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               Text('Станция: $stationName'),
//               Text('Статус: ${item.status.name}'), // или как-то отображайте
//               Text('В этом статусе: $elapsedSeconds сек'),
//               // Можно ещё ингредиенты вывести, если нужно
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
