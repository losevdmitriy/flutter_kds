import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/utils/parseDateTime.dart';
import '../../dto/writeOffItemData.dart';
import '../../service/api_service.dart';

class WriteOffScreen extends StatefulWidget {
  const WriteOffScreen({super.key});

  @override
  State<WriteOffScreen> createState() => _WriteOffScreenState();
}

class _WriteOffScreenState extends State<WriteOffScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<WriteOffItemData>> _futureWriteOffItems;
  int _currentPage = 0;
  int _elementsPerPage = 10;

  // Добавляем переменные состояния для сортировки
  bool _isAscending = true; // Флаг для отслеживания порядка сортировки
  int _sortColumnIndex = 0; // Индекс текущей сортируемой колонки

  @override
  void initState() {
    super.initState();
    _futureWriteOffItems =
        _apiService.fetchWriteOffItems(_currentPage, _elementsPerPage);
  }

  /// Обновление данных
  Future<void> _reloadData() async {
    setState(() {
      _futureWriteOffItems =
          _apiService.fetchWriteOffItems(_currentPage, _elementsPerPage);
    });
  }

  void _nextPage() {
    setState(() => _currentPage++);
    _reloadData();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _reloadData();
    }
  }

  void _onElementsPerPageChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _elementsPerPage = newValue;
        _currentPage = 0;
      });
      _reloadData();
    }
  }

  /// Вкладка с выводом всех списаний
  Widget _buildWriteOffItemsTab() {
    return FutureBuilder<List<WriteOffItemData>>(
      future: _futureWriteOffItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Нет списаний на складе'));
        }

        // Сортировка данных по id
        if (_sortColumnIndex == 0) {
          items.sort((a, b) => _isAscending
              ? (a.id ?? 0).compareTo(b.id ?? 0)
              : (b.id ?? 0).compareTo(a.id ?? 0));
        }

        return Column(
          children: [
            _buildPaginationControls(items),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _isAscending,
                  columns: [
                    DataColumn(
                      label: const Text('ID'),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _sortColumnIndex = columnIndex;
                          _isAscending = ascending;
                        });
                      },
                    ),
                    const DataColumn(label: Text('Тип')),
                    const DataColumn(label: Text('Имя')),
                    const DataColumn(label: Text('Id на складе')),
                    const DataColumn(label: Text('Колл-во')),
                    const DataColumn(label: Text('Комментарий')),
                    const DataColumn(label: Text('Дата создания')),
                    const DataColumn(label: Text('Cписал')),
                    const DataColumn(label: Text('Успешно?')),
                  ],
                  rows: items.map((writeOff) {
                    return DataRow(
                      cells: [
                        DataCell(Text(writeOff.id?.toString() ?? '')),
                        DataCell(Text(writeOff.sourceType ?? '')),
                        DataCell(Text(writeOff.name ?? '')),
                        DataCell(Text(writeOff.sourceId?.toString() ?? '')),
                        DataCell(
                            Text(writeOff.amount?.toStringAsFixed(2) ?? '0')),
                        DataCell(Text(writeOff.discontinuedComment ?? '')),
                        DataCell(Text(formatDateTime(writeOff.createdAt))),
                        DataCell(Text(writeOff.createdBy ?? '')),
                        DataCell(Text(writeOff.isCompleted?.toString() ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(List<WriteOffItemData> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 0 ? _previousPage : null,
          ),
          Text('Страница ${_currentPage + 1}'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: items.length >= _elementsPerPage ? _nextPage : null,
          ),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: _elementsPerPage,
            items: [10, 20, 50].map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value на странице'),
              );
            }).toList(),
            onChanged: _onElementsPerPageChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Списания на складе'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadData, // Кнопка для обновления данных
          ),
        ],
      ),
      body: _buildWriteOffItemsTab(),
    );
  }
}
