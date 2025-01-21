import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../dto/IngredientItemData.dart';
import '../../dto/PrepackItemData.dart';
import '../../dto/writeOffRequest.dart';
import '../../service/api_service.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  late Future<List<IngredientItemData>> _futureIngredients;
  late Future<List<PrepackItemData>> _futurePrepacks;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Загружаем данные
    _futureIngredients = _apiService.fetchIngredientItems();
    _futurePrepacks = _apiService.fetchPrepackItems();
  }

  /// Обновление данных (например, после списания)
  Future<void> _reloadData() async {
    setState(() {
      _futureIngredients = _apiService.fetchIngredientItems();
      _futurePrepacks = _apiService.fetchPrepackItems();
    });
  }

  /// Вкладка с ингредиентами (DataTable)
  Widget _buildIngredientsTab() {
    return FutureBuilder<List<IngredientItemData>>(
      future: _futureIngredients,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Нет ингредиентов на складе'));
        }

        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Наименование')),
              DataColumn(label: Text('Кол-во')),
              DataColumn(label: Text('Списать')),
            ],
            rows: items.map((ingredient) {
              return DataRow(cells: [
                DataCell(Text(ingredient.id?.toString() ?? '')),
                DataCell(Text(ingredient.ingredientName ?? '')),
                DataCell(Text(ingredient.amount?.toStringAsFixed(2) ?? '0')),
                // Кнопка "Списать"
                DataCell(
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      // Открываем диалог и передаем текущий остаток:
                      final result = await showDialog(
                        context: context,
                        builder: (_) => WriteOffDialog(
                          itemId: ingredient.id!,
                          itemType: WarehouseItemType.ingredient,
                          currentAmount: ingredient.amount ?? 0.0,
                        ),
                      );
                      if (result == true) {
                        _reloadData();
                      }
                    },
                    child: const Text('Списать'),
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  /// Вкладка с полуфабрикатами (DataTable)
  Widget _buildPrepacksTab() {
    return FutureBuilder<List<PrepackItemData>>(
      future: _futurePrepacks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Нет полуфабрикатов на складе'));
        }

        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Наименование')),
              DataColumn(label: Text('Кол-во')),
              DataColumn(label: Text('Списать')),
            ],
            rows: items.map((prepack) {
              return DataRow(cells: [
                DataCell(Text(prepack.id?.toString() ?? '')),
                DataCell(Text(prepack.prepackName ?? '')),
                DataCell(Text(prepack.amount?.toStringAsFixed(2) ?? '0')),
                // Кнопка "Списать"
                DataCell(
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => WriteOffDialog(
                          itemId: prepack.id!,
                          itemType: WarehouseItemType.prepack,
                          currentAmount: prepack.amount ?? 0.0,
                        ),
                      );
                      if (result == true) {
                        _reloadData();
                      }
                    },
                    child: const Text('Списать'),
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ингредиенты'),
            Tab(text: 'Полуфабрикаты'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIngredientsTab(),
          _buildPrepacksTab(),
        ],
      ),
    );
  }
}

class WriteOffDialog extends StatefulWidget {
  final int itemId;
  final WarehouseItemType itemType;
  final double currentAmount; // <-- Текущее количество в наличии

  const WriteOffDialog({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.currentAmount,
  });

  @override
  State<WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends State<WriteOffDialog> {
  final _formKey = GlobalKey<FormState>();

  /// Контроллеры для полей формы
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _employeeNameController =
      TextEditingController(text: 'Кичигин Д.'); // Значение по умолчанию

  /// Дата списания (сегодня), только для отображения (read-only).
  late final String _writeOffDateStr;

  /// По умолчанию — причина «Испорчен»
  DiscontinuedReason _selectedReason = DiscontinuedReason.SPOILED;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Форматируем текущую дату
    _writeOffDateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    // Если по умолчанию "Испорчен" => списываем всё количество
    if (_selectedReason == DiscontinuedReason.SPOILED) {
      _amountController.text = widget.currentAmount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Списание продукта',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Поле ввода имени сотрудника
                  TextFormField(
                    controller: _employeeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Сотрудник',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Укажите имя сотрудника';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Отображение даты списания (текущая, редактировать нельзя)
                  TextFormField(
                    initialValue: _writeOffDateStr,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Дата списания',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Поле ввода количества (не больше, чем currentAmount)
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          'Количество для списания (макс. ${widget.currentAmount})',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите количество';
                      }
                      final doubleVal = double.tryParse(value);
                      if (doubleVal == null || doubleVal <= 0) {
                        return 'Введите корректное положительное число';
                      }
                      // Проверяем, чтобы не превышало текущего количества
                      if (doubleVal > widget.currentAmount) {
                        return 'Нельзя списать больше, чем в наличии';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Кнопки выбора причины
                  _buildReasonButtons(),
                  const SizedBox(height: 16),

                  // Поле комментария (только если причина == OTHER)
                  if (_selectedReason == DiscontinuedReason.OTHER)
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Комментарий',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedReason == DiscontinuedReason.OTHER &&
                            (value == null || value.isEmpty)) {
                          return 'Укажите комментарий';
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Кнопки действий (Отмена / OK)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
              onPressed:
                  _isLoading ? null : () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        await _onSubmit();
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('OK'),
            ),
          ],
        ),
      ],
    );
  }

  /// Набор кнопок для выбора причины списания
  Widget _buildReasonButtons() {
    final reasons = [
      {
        'value': DiscontinuedReason.SPOILED,
        'label': 'Испорчен',
      },
      {
        'value': DiscontinuedReason.OTHER,
        'label': 'Другая причина',
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reasons.map((item) {
        final reasonValue = item['value'] as DiscontinuedReason;
        final label = item['label'] as String;
        final bool isSelected = (_selectedReason == reasonValue);

        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedReason = reasonValue;
              if (_selectedReason == DiscontinuedReason.SPOILED) {
                _amountController.text = widget.currentAmount.toString();
              } else {
                // Если выбрали "Другая причина" => обнулим количество
                _amountController.text = '0';
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label),
        );
      }).toList(),
    );
  }

  /// Метод, который формирует WriteOffRequest и отправляет на бэкенд
  Future<void> _onSubmit() async {
    setState(() => _isLoading = true);

    final apiService = ApiService();
    final request = WriteOffRequest(
      sourceItemId: widget.itemId,
      employeeName: _employeeNameController.text.trim(),
      writeOffAmount: double.parse(_amountController.text),
      discontinuedReason: _selectedReason,
      // Здесь самое важное: передаём тип как строку (INGREDIENT / PREPACK).
      sourceType: widget.itemType.sourceTypeString,
      customReasonComment: _selectedReason == DiscontinuedReason.OTHER
          ? _commentController.text
          : null,
    );

    try {
      // Вызываем единый метод списания
      await apiService.writeOffItem(request);

      // Успешно списали
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Ошибка при запросе
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

enum WarehouseItemType {
  ingredient,
  prepack,
}

extension WarehouseItemTypeExtension on WarehouseItemType {
  String get sourceTypeString {
    switch (this) {
      case WarehouseItemType.ingredient:
        return 'INGREDIENT';
      case WarehouseItemType.prepack:
        return 'PREPACK';
    }
  }
}
