import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/processing_screens/ProcessingAct.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import 'package:intl/intl.dart';

import 'add_product_screen.dart';
import 'processing_act_items_screen.dart';

class AllProcessingActsScreen extends StatefulWidget {
  const AllProcessingActsScreen({Key? key}) : super(key: key);

  @override
  State<AllProcessingActsScreen> createState() =>
      _AllProcessingActsScreenState();
}

class _AllProcessingActsScreenState extends State<AllProcessingActsScreen> {
  late Future<List<ProcessingAct>> futureProcessingActs;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futureProcessingActs = apiService.fetchProcessingActs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список Processing Acts')),
      body: FutureBuilder<List<ProcessingAct>>(
        future: futureProcessingActs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Нет данных для отображения'),
            );
          }

          final processingActs = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: DataTable(
                columnSpacing: 24.0, // Увеличиваем расстояние между колонками
                dataRowHeight: 60.0, // Увеличиваем высоту строк
                headingRowHeight: 70.0, // Увеличиваем высоту заголовка таблицы
                columns: const [
                  DataColumn(
                    label: Text('#', style: TextStyle(fontSize: 18.0)),
                  ),
                  DataColumn(
                    label: Text('Наименование ПФ',
                        style: TextStyle(fontSize: 18.0)),
                  ),
                  DataColumn(
                    label: Text('Количество', style: TextStyle(fontSize: 18.0)),
                  ),
                  DataColumn(
                    label: Text('Дата', style: TextStyle(fontSize: 18.0)),
                  ),
                  DataColumn(
                    label: Text('Сотрудник', style: TextStyle(fontSize: 18.0)),
                  ),
                  DataColumn(
                    label: Text('Удалить', style: TextStyle(fontSize: 18.0)),
                  ),
                ],
                rows: List<DataRow>.generate(
                  processingActs.length,
                  (index) {
                    final act = processingActs[index];
                    final isEvenRow = index % 2 == 0;

                    return DataRow(
                      color: MaterialStateProperty.all(
                        isEvenRow ? Colors.grey[50] : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Text(act.id.toString(),
                              style: const TextStyle(fontSize: 16.0)),
                          onTap: () {
                            _navigateToDetails(act.id);
                          },
                        ),
                        DataCell(
                          Text(act.prepackName,
                              style: const TextStyle(fontSize: 16.0)),
                          onTap: () {
                            _navigateToDetails(act.id);
                          },
                        ),
                        DataCell(
                          Text('${act.amount}${act.measurementUnit}',
                              style: const TextStyle(fontSize: 16.0)),
                          onTap: () {
                            _navigateToDetails(act.id);
                          },
                        ),
                        DataCell(
                          Text(DateFormat('dd.MM.yyyy').format(act.date),
                              style: const TextStyle(fontSize: 16.0)),
                          onTap: () {
                            _navigateToDetails(act.id);
                          },
                        ),
                        DataCell(
                          Text(act.employeeName,
                              style: const TextStyle(fontSize: 16.0)),
                          onTap: () {
                            _navigateToDetails(act.id);
                          },
                        ),
                        // Кнопка "Удалить"
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Удалить акт',
                            onPressed: () {
                              _deleteProcessingAct(act.id);
                            },
                          ),
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
      floatingActionButton: SizedBox(
        height: 70,
        width: 120, // Увеличиваем ширину для размещения текста
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );
          },
          backgroundColor: Colors.blue,
          child: const Text(
            'Создать',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Переход на детальный просмотр акта (список позиций)
  void _navigateToDetails(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingActItemsScreen(
          processingActId: id,
        ),
      ),
    );
  }

  /// Удаляем акт и обновляем список
  Future<void> _deleteProcessingAct(int id) async {
    try {
      await apiService.deleteProcessingAct(id);
      // После удаления запрашиваем свежий список
      setState(() {
        futureProcessingActs = apiService.fetchProcessingActs();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Акт $id успешно удалён')),
      );
    } catch (e) {
      debugPrint('Ошибка при удалении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }
}
