import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/dto/Invoice.dart';
import 'package:intl/intl.dart';

import '../dto/Source.dart';

class InvoiceItemRow extends StatefulWidget {
  final InvoiceItem item;
  final NumberFormat priceFormat;
  final List<Source> availableSources;
  final bool readOnly;
  final VoidCallback onRemove;

  const InvoiceItemRow({
    Key? key,
    required this.item,
    required this.priceFormat,
    required this.availableSources,
    required this.readOnly,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _amountController;
  late TextEditingController _priceController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.amount == 0 ? '' : widget.item.amount.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.price == 0 ? '' : widget.item.price.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Наименование (Autocomplete)
          Expanded(
            flex: 4,
            child: widget.readOnly
                ? _buildReadOnlyField(widget.item.name)
                : _buildSourceAutocomplete(),
          ),
          const SizedBox(width: 8),

          // Количество
          Expanded(
            flex: 2,
            child: widget.readOnly
                ? _buildReadOnlyField('${widget.item.amount}')
                : _buildamountField(),
          ),
          const SizedBox(width: 8),

          // Цена
          Expanded(
            flex: 2,
            child: widget.readOnly
                ? _buildReadOnlyField(
                    widget.priceFormat.format(widget.item.price),
                  )
                : _buildPriceField(),
          ),
          const SizedBox(width: 8),

          // Сумма
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.priceFormat.format(widget.item.lineTotal),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Иконка удаления строки
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }

  /// Autocomplete для выбора источника
  Widget _buildSourceAutocomplete() {
    return Autocomplete<Source>(
      // Показываем варианты, которые подходят по вводу
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Source>.empty();
        }
        return widget.availableSources.where((source) {
          return source.name
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      displayStringForOption: (Source source) => source.name, // Отображаем имя источника
      // Изначальное значение в поле
      initialValue: TextEditingValue(text: widget.item.name),

      // Когда пользователь выбрал вариант из выпадающего списка
      onSelected: (Source selection) {
        setState(() {
          widget.item.name = selection.name;
          widget.item.sourceId = selection.id;
          widget.item.sourceType = selection.type;
        });
      },

      // Отображение поля ввода
      fieldViewBuilder:
          (context, textEditingController, focusNode, onEditingComplete) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onEditingComplete: () {
            // Если введённое значение отсутствует в списке, сбросим его
            final matchingSource = widget.availableSources.firstWhere(
              (source) => source.name == textEditingController.text,
              orElse: () => Source(name: '', type: '', id: null),
            );
            if (matchingSource.name.isEmpty) {
              textEditingController.clear();
            }
            onEditingComplete();
          },
          decoration: const InputDecoration(
            hintText: 'Наименование',
            border: OutlineInputBorder(),
          ),
        );
      },

      // Отображение одного элемента в списке Autocomplete
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.name),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Поле ввода количества
  Widget _buildamountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: '0',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsed = int.tryParse(value.replaceAll(',', '.')) ?? 0;
        setState(() {
          widget.item.amount = parsed;
        });
      },
    );
  }

  /// Поле ввода цены
  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: '0.0',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final sanitized = value.replaceAll(',', '.');
        final parsed = double.tryParse(sanitized) ?? 0.0;
        setState(() {
          widget.item.price = parsed;
        });
      },
    );
  }

  /// Поле для отображения только текста (readOnly)
  Widget _buildReadOnlyField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text),
    );
  }
}
