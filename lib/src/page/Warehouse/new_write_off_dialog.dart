import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/IngredientItemData.dart';
import 'package:flutter_iem_new/src/dto/PrepackItemData.dart';
import 'package:flutter_iem_new/src/dto/Source.dart';
import 'package:flutter_iem_new/src/dto/writeOffRequest.dart';
import 'package:intl/intl.dart';
import '../../service/api_service.dart'; // Сервис API

// Типы товаров на складе
enum WarehouseItemType {
  ingredient,
  prepack,
}

// Расширение для преобразования типа в строку
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

class NewWriteOffDialog extends StatefulWidget {
  const NewWriteOffDialog({super.key});

  @override
  State<NewWriteOffDialog> createState() => _NewWriteOffDialogState();
}

class _NewWriteOffDialogState extends State<NewWriteOffDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  WarehouseItemType _selectedType = WarehouseItemType.ingredient;
  dynamic _selectedItem; // Может быть IngredientItemData или PrepackItemData
  double? _currentAmount; // Текущее количество на складе
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _employeeNameController =
      TextEditingController(text: 'Кичигин Д.');
  late final String _writeOffDateStr;
  DiscontinuedReason _selectedReason = DiscontinuedReason.SPOILED;
  bool _isLoading = false;

  Future<List<Source>>? _ingredientsFuture;
  Future<List<Source>>? _prepacksFuture;

  @override
  void initState() {
    super.initState();
    _writeOffDateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
    _loadItems();
  }

  // Загрузка списка товаров в зависимости от типа
  void _loadItems() {
    if (_selectedType == WarehouseItemType.ingredient) {
      _ingredientsFuture = _apiService.fetchIngredients();
      _prepacksFuture = null;
    } else {
      _prepacksFuture = _apiService.fetchPrepacks();
      _ingredientsFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новое списание',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTypeSelector(), // Выбор типа товара
                      const SizedBox(height: 16),
                      _buildItemSelector(), // Выбор конкретного товара
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Сотрудник',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Укажите имя сотрудника'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _writeOffDateStr,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Дата списания',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              'Количество для списания${_currentAmount != null ? ' (макс. $_currentAmount)' : ''}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите количество';
                          }
                          final doubleVal = double.tryParse(value);
                          if (doubleVal == null || doubleVal <= 0) {
                            return 'Введите корректное число';
                          }
                          if (_currentAmount != null &&
                              doubleVal > _currentAmount!) {
                            return 'Нельзя списать больше, чем в наличии';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildReasonButtons(), // Кнопки выбора причины
                      const SizedBox(height: 16),
                      if (_selectedReason == DiscontinuedReason.OTHER)
                        TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Комментарий',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Укажите комментарий'
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600),
                  onPressed:
                      _isLoading ? null : () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Выбор типа товара (ингредиент или полуфабрикат)
  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: const Text('Ингредиент'),
            leading: Radio<WarehouseItemType>(
              value: WarehouseItemType.ingredient,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _selectedItem = null;
                  _currentAmount = null;
                  _amountController.clear();
                  _loadItems();
                });
              },
            ),
          ),
        ),
        Expanded(
          child: ListTile(
            title: const Text('Полуфабрикат'),
            leading: Radio<WarehouseItemType>(
              value: WarehouseItemType.prepack,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _selectedItem = null;
                  _currentAmount = null;
                  _amountController.clear();
                  _loadItems();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Выбор конкретного товара из списка
  Widget _buildItemSelector() {
    return _selectedType == WarehouseItemType.ingredient
        ? FutureBuilder<List<Source>>(
            future: _ingredientsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) return Text('Ошибка: ${snapshot.error}');
              final items = snapshot.data ?? [];
              return DropdownButtonFormField<dynamic>(
                value: _selectedItem,
                hint: const Text('Выберите ингредиент'),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                    _currentAmount = value.amount;
                    if (_selectedReason == DiscontinuedReason.SPOILED) {
                      _amountController.text = _currentAmount.toString();
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Выберите ингредиент' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              );
            },
          )
        : FutureBuilder<List<Source>>(
            future: _prepacksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) return Text('Ошибка: ${snapshot.error}');
              final items = snapshot.data ?? [];
              return DropdownButtonFormField<dynamic>(
                value: _selectedItem,
                hint: const Text('Выберите полуфабрикат'),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                    _currentAmount = value.amount;
                    if (_selectedReason == DiscontinuedReason.SPOILED) {
                      _amountController.text = _currentAmount.toString();
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Выберите полуфабрикат' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              );
            },
          );
  }

  // Кнопки выбора причины списания
  Widget _buildReasonButtons() {
    final reasons = [
      {'value': DiscontinuedReason.SPOILED, 'label': 'Испорчен'},
      {'value': DiscontinuedReason.OTHER, 'label': 'Другая причина'},
    ];
    return Wrap(
      spacing: 8,
      children: reasons.map((item) {
        final value = item['value'] as DiscontinuedReason;
        final label = item['label'] as String;
        final isSelected = _selectedReason == value;
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedReason = value;
              if (value == DiscontinuedReason.SPOILED &&
                  _currentAmount != null) {
                _amountController.text = _currentAmount.toString();
              } else {
                _amountController.clear();
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          child: Text(label),
        );
      }).toList(),
    );
  }

  // Отправка данных списания
  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final request = WriteOffRequest(
        id: _selectedItem.id,
        employeeName: _employeeNameController.text.trim(),
        writeOffAmount: double.parse(_amountController.text),
        discontinuedReason: _selectedReason,
        sourceType: _selectedType.sourceTypeString,
        customReasonComment: _selectedReason == DiscontinuedReason.OTHER
            ? _commentController.text.trim()
            : "'продукт испорчен'",
      );
      try {
        await _apiService.addWriteOffItem(request);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
