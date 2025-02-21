// // ignore_for_file: depend_on_referenced_packages

// import 'dart:async';
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
// import 'package:flutter_thermal_printer/utils/printer.dart';

// class ThermalPrintPage extends StatefulWidget {
//   const ThermalPrintPage({Key? key}) : super(key: key);

//   @override
//   State<ThermalPrintPage> createState() => _ThermalPrintPageState();
// }

// class _ThermalPrintPageState extends State<ThermalPrintPage> {
//   final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

//   String _ip = '192.168.0.100';
//   String _port = '9100';

//   List<Printer> printers = [];
//   StreamSubscription<List<Printer>>? _devicesStreamSubscription;

//   // Метод для поиска принтеров
//   void startScan() async {
//     _devicesStreamSubscription?.cancel();

//     // Подбирайте нужные ConnectionType в зависимости от ситуации
//     await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
//       ConnectionType.BLE,
//     ]);

//     _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
//         .listen((List<Printer> event) {
//       log(event.map((e) => e.name).toList().toString());
//       setState(() {
//         printers = event;
//         // Удаляем устройства без имени
//         printers.removeWhere(
//             (element) => element.name == null || element.name!.isEmpty);
//       });
//     });
//   }

//   // Остановка поиска принтеров
//   void stopScan() {
//     _flutterThermalPrinterPlugin.stopScan();
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       startScan();
//     });
//   }

//   @override
//   void dispose() {
//     // Не забывайте отменять подписку
//     _devicesStreamSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Thermal Printer Example'),
//         systemOverlayStyle: const SystemUiOverlayStyle(
//           statusBarColor: Colors.transparent,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'NETWORK',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 12),
//             TextFormField(
//               initialValue: _ip,
//               decoration: const InputDecoration(
//                 labelText: 'Enter IP Address',
//               ),
//               onChanged: (value) {
//                 _ip = value;
//               },
//             ),
//             const SizedBox(height: 12),
//             TextFormField(
//               initialValue: _port,
//               decoration: const InputDecoration(
//                 labelText: 'Enter Port',
//               ),
//               onChanged: (value) {
//                 _port = value;
//               },
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final service = FlutterThermalPrinterNetwork(
//                         _ip,
//                         port: int.parse(_port),
//                       );
//                       await service.connect();
//                       final profile = await CapabilityProfile.load();
//                       final generator = Generator(PaperSize.mm58, profile);

//                       if (!mounted) return;
//                       // Печатаем виджет
//                       List<int> bytes =
//                           await FlutterThermalPrinter.instance.screenShotWidget(
//                         context,
//                         generator: generator,
//                         widget: receiptWidget("Network"),
//                       );

//                       // Добавляем команду обрезки
//                       bytes += generator.cut();

//                       // Печать
//                       await service.printTicket(bytes);

//                       // Отключаемся
//                       await service.disconnect();
//                     },
//                     child: const Text('Test network printer'),
//                   ),
//                 ),
//                 const SizedBox(width: 22),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final service = FlutterThermalPrinterNetwork(
//                         _ip,
//                         port: int.parse(_port),
//                       );
//                       await service.connect();
//                       final bytes = await _generateReceipt();
//                       await service.printTicket(bytes);
//                       await service.disconnect();
//                     },
//                     child: const Text('Test network printer widget'),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             const Divider(),
//             const SizedBox(height: 22),
//             Text(
//               'USB/BLE',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 22),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: startScan,
//                     child: const Text('Get Printers'),
//                   ),
//                 ),
//                 const SizedBox(width: 22),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: stopScan,
//                     child: const Text('Stop Scan'),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: printers.length,
//                 itemBuilder: (context, index) {
//                   final printer = printers[index];
//                   return ListTile(
//                     onTap: () async {
//                       if (printer.isConnected == true) {
//                         await _flutterThermalPrinterPlugin.disconnect(printer);
//                       } else {
//                         await _flutterThermalPrinterPlugin.connect(printer);
//                       }
//                       setState(() {});
//                     },
//                     title: Text(printer.name ?? 'No Name'),
//                     subtitle: Text("Connected: ${printer.isConnected == true}"),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.connect_without_contact),
//                       onPressed: () async {
//                         await _flutterThermalPrinterPlugin.printWidget(
//                           context,
//                           printOnBle: true,
//                           printer: printer,
//                           widget: receiptWidget(
//                             printer.connectionTypeString,
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Виджет, который мы печатаем (генерируется в виде картинки, затем переводится в байты)
//   Widget receiptWidget(String printerType) {
//     return SizedBox(
//       width: 200,
//       child: Material(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Center(
//                 child: Text(
//                   'ЛёняпоелкрутокрутокрутивкусноЛёняпоелкрутокрутокрутивкусно',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const Divider(thickness: 2),
//               const SizedBox(height: 10),
//               _buildReceiptRow('Item', 'Price'),
//               const Divider(),
//               _buildReceiptRow('Apple', '\$1.00'),
//               _buildReceiptRow('Banana', '\$0.50'),
//               _buildReceiptRow('Orange', '\$0.75'),
//               const Divider(thickness: 2),
//               _buildReceiptRow('Total', '\$2.25', isBold: true),
//               const SizedBox(height: 20),
//               _buildReceiptRow('Printer Type', printerType),
//               const SizedBox(height: 50),
//               const Center(
//                 child: Text(
//                   'Thank you for your purchase!',
//                   style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//   }

//   Widget _buildReceiptRow(String leftText, String rightText,
//       {bool isBold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             leftText,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             rightText,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
