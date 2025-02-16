import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/widgets/ip_input_dialog.dart';
import 'package:flutter_iem_new/src/page/all_invoices_act_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  /// Открывает диалог настройки IP-адреса и порта
  void _showIpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => IpInputDialog(
        onIpEntered: (String fullAddress) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("IP-адрес успешно обновлен!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная страница"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showIpDialog(context),
            tooltip: "Настроить IP-адрес",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Холодный цех"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chef',
                  arguments: {"screenId": "1", "screenName": "Холодный цех"},
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Горячий цех"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chef',
                  arguments: {"screenId": "2", "screenName": "Горячий цех"},
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Сборка"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/chef',
                  arguments: {"screenId": "3", "screenName": "Сборка"},
                );
              },
            ),
            ElevatedButton(
              child: const Text("Сборка NEW"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/collect',
                  arguments: {"screenId": "3"},
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Накладные"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllInvoicesPage(),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Внести товар"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/addPrepack',
                );
              },
            ),
            ElevatedButton(
              child: const Text("Склад"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/warehouse',
                );
              },
            ),
            ElevatedButton(
              child: const Text("Принтер"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/print',
                );
              },
            ),
            ElevatedButton(
              child: const Text("Списания"),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/writeOff',
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
