import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/Invoice.dart';
import 'package:flutter_iem_new/src/dto/Source.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import 'package:flutter_iem_new/src/widgets/invoice_item_row.dart';
import 'package:intl/intl.dart';

/// Страница накладной
class InvoicePage extends StatefulWidget {
  final Invoice invoice;
  final bool isEditMode; // если true, можно редактировать

  const InvoicePage({
    Key? key,
    required this.invoice,
    required this.isEditMode,
  }) : super(key: key);

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final ApiService _apiService = ApiService(); 

  late TextEditingController _dateController;
  late TextEditingController _supplierController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _priceFormat = NumberFormat('#,##0.00');

  bool get _isReadOnly => !widget.isEditMode;

@override
void initState() {
  super.initState();
  _dateController = TextEditingController(
    text: _dateFormat.format(widget.invoice.date),
  );
  _supplierController = TextEditingController(text: widget.invoice.vendor);

  if (widget.invoice.items.isEmpty) {
    _fetchInvoice(widget.invoice.id!); // Загрузка накладной по ID
  }
}

Future<void> _fetchInvoice(int invoiceId) async {
  try {
    final fetchedInvoice = await _apiService.fetchInvoiceById(invoiceId);
    setState(() {
      widget.invoice.items = fetchedInvoice.items;
      _dateController.text = _dateFormat.format(fetchedInvoice.date);
      _supplierController.text = fetchedInvoice.vendor;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка загрузки накладной: $e')),
    );
  }
}

  @override
  void dispose() {
    _dateController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.invoice.totalPrice;
  int get _totalLines => widget.invoice.totalLines;

  Future<void> _pickDate(BuildContext context) async {
    if (_isReadOnly) return;
    final newDate = await showDatePicker(
      context: context,
      initialDate: widget.invoice.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        widget.invoice.date = newDate;
        _dateController.text = _dateFormat.format(newDate);
      });
    }
  }

  void _addNewItem() {
    if (_isReadOnly) return;
    setState(() {
      widget.invoice.items.add(
        InvoiceItem(amount: 1, price: 0.0, name: ''),
      );
    });
  }

  void _removeItem(int index) {
    if (_isReadOnly) return;
    setState(() {
      widget.invoice.items.removeAt(index);
    });
  }

  void _onEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          invoice: widget.invoice, // Передаём текущую накладную
          isEditMode: true, // Включаем режим редактирования
        ),
      ),
    );

    if (result == true) {
      // Если накладная была сохранена, обновляем данные на экране
      setState(() {});
    }
  }


  void _onSave() async {
    if (_isReadOnly) {
      Navigator.pop(context);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.invoice.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы не добавили ни одной записи.'),
          ),
        );
    }

    for (final item in widget.invoice.items) {
      if (item.name.isEmpty || item.amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заполните все наименования и количество корректно.'),
          ),
        );
        return;
      }
    }

    try {
      await _apiService.saveInvoice(widget.invoice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Накладная сохранена!')),
      );
      Navigator.pop(context, true); // Возвращаем результат для обновления списка
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения накладной: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isReadOnly ? 'Накладная (read-only)' : 'Накладная (edit)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Блок формы (Дата, Поставщик)
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pickDate(context),
                      child: IgnorePointer(
                        ignoring: _isReadOnly,
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Дата',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите дату';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _supplierController,
                      readOnly: _isReadOnly,
                      decoration: const InputDecoration(
                        labelText: 'Поставщик',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Укажите поставщика';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        if (!_isReadOnly) {
                          invoice.vendor = val;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Заголовок таблицы
            _buildTableHeader(),
            const Divider(),

            // Список позиций
            Expanded(
              child: FutureBuilder<List<Source>>(
                future: _apiService.fetchSources(), // Асинхронный вызов
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Ошибка загрузки источников: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final availableSources = snapshot.data!; // Загруженные данные

                    return ListView.builder(
                      key: const PageStorageKey('invoice_items_list'), // ключ для списка
                      itemCount: invoice.totalItems,
                      itemBuilder: (context, index) {
                        final item = invoice.items[index];

                        return InvoiceItemRow(
                          key: ObjectKey(item),
                          item: item,
                          priceFormat: _priceFormat,
                          availableSources: availableSources, // Передаём список
                          readOnly: _isReadOnly,
                          onRemove: () => _removeItem(index),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('Нет данных.'));
                  }
                },
              ),
            ),

            // Кнопка "Добавить позицию" (только если редактируем)
            if (!_isReadOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить позицию'),
                  onPressed: _addNewItem,
                ),
              ),

            const Divider(),
            const SizedBox(height: 10),

            // Итоги + кнопка "Сохранить" / "Назад"
            _buildSummaryRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 4,
          child: Text(
            'Наименование',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Кол-во',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Цена',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Сумма',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 40), // под иконку удаления
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Позиций: $_totalLines'),
        Text('Сумма: ${_priceFormat.format(_totalPrice)}'),
        ElevatedButton(
          onPressed: _isReadOnly ? _onEdit : _onSave,
          child: Text(_isReadOnly ? 'Редактировать' : 'Сохранить'),
        ),
      ],
    );
  }
}
