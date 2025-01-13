import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/compliteProcessingAct.dart';

import '../../service/api_service.dart';

class ProcessingActItemsScreen extends StatefulWidget {
  final int processingActId;

  const ProcessingActItemsScreen({Key? key, required this.processingActId})
      : super(key: key);

  @override
  State<ProcessingActItemsScreen> createState() =>
      _ProcessingActItemsScreenState();
}

class _ProcessingActItemsScreenState extends State<ProcessingActItemsScreen> {
  late Future<CompliteProcessingAct> futureProcessingAct;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futureProcessingAct =
        apiService.fetchProcessingActItems(widget.processingActId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Позиции акта #${widget.processingActId}'),
      ),
      body: FutureBuilder<CompliteProcessingAct>(
        future: futureProcessingAct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.itemDataList.isEmpty) {
            return const Center(
              child: Text('Нет позиций для данного акта'),
            );
          }

          final items = snapshot.data!.itemDataList;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: DataTable(
                columnSpacing: 24.0,
                dataRowHeight: 60.0,
                headingRowHeight: 70.0,
                columns: const [
                  DataColumn(
                      label: Text('Наименование',
                          style: TextStyle(fontSize: 18.0))),
                  DataColumn(
                      label: Text('Нач. кол-во',
                          style: TextStyle(fontSize: 18.0))),
                  DataColumn(
                      label: Text('Итог. кол-во',
                          style: TextStyle(fontSize: 18.0))),
                  DataColumn(
                      label:
                          Text('Потери (г)', style: TextStyle(fontSize: 18.0))),
                  DataColumn(
                      label:
                          Text('Потери (%)', style: TextStyle(fontSize: 18.0))),
                ],
                rows: List<DataRow>.generate(
                  items.length,
                  (index) {
                    final item = items[index];
                    final isEvenRow = index % 2 == 0;

                    return DataRow(
                      color: MaterialStateProperty.all(
                        isEvenRow ? Colors.grey[50] : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Text(item.name,
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                        DataCell(
                          Text(item.initAmount.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                        DataCell(
                          Text(item.finalAmount.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                        DataCell(
                          Text(item.lossesAmount.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                        DataCell(
                          Text(item.lossesPercentage.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 16.0)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
