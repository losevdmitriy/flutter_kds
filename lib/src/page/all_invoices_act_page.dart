import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/page/invoice_act_page.dart';
import 'package:flutter_iem_new/src/service/api_service.dart';
import 'package:intl/intl.dart';

import '../dto/Invoice.dart';

class AllInvoicesPage extends StatefulWidget {
  const AllInvoicesPage({Key? key}) : super(key: key);

  @override
  State<AllInvoicesPage> createState() => _AllInvoicesPageState();
}

class _AllInvoicesPageState extends State<AllInvoicesPage> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _priceFormat = NumberFormat('#,##0.00');
  final ApiService _apiService = ApiService(); 

  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    try {
      final invoices = await _apiService.fetchInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки накладных: $e')),
      );
    }
  }

  Future<void> _deleteInvoice(int invoiceId) async {
    try {
      await _apiService.deleteInvoice(invoiceId); // Удаляем накладную
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Накладная удалена')),
      );
      _fetchInvoices(); // Обновляем список после удаления
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления накладной: $e')),
      );
    }
  }

  void _confirmDeleteInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удаление накладной'),
          content: const Text('Вы уверены, что хотите удалить эту накладную?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог
                _deleteInvoice(invoice.id!);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все накладные'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTableHeader(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final inv = _invoices[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoicePage(
                                invoice: inv,
                                isEditMode: false,
                              ),
                            ),
                          ).then((isUpdated) {
                            if (isUpdated == true) {
                              _fetchInvoices(); // Обновляем список, если были изменения
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(_dateFormat.format(inv.date)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(inv.vendor),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  inv.totalLines.toString(),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _priceFormat.format(inv.totalPrice),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteInvoice(inv),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить накладную'),
                      onPressed: _onAddInvoice,
                    ),
                  ),
                )
              ],
            ),
    );
  }

Widget _buildTableHeader() {
    return Container(
      color: const Color.fromARGB(255, 225, 223, 223),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Дата',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Поставщик',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Количество',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Цена',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddInvoice() {
    final newInvoice = Invoice(
      date: DateTime.now(),
      vendor: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          invoice: newInvoice,
          isEditMode: true,
        ),
      ),
    ).then((isSaved) {
      if (isSaved == true) {
        _fetchInvoices(); // Обновление списка после сохранения
      }
    });
  }
}