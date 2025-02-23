import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_iem_new/src/widgets/ip_input_dialog.dart';
import 'package:flutter_iem_new/src/page/all_invoices_act_page.dart';

import '../widgets/menu_item.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 16,
            runSpacing: 16,
            children: [
              MenuItem(
                icon: Icons.ac_unit,
                title: "Холодный цех",
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chef',
                    arguments: {"screenId": "1", "screenName": "Холодный цех"},
                  );
                },
              ),
              MenuItem(
                icon: Icons.whatshot,
                title: "Горячий цех",
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chef',
                    arguments: {"screenId": "2", "screenName": "Горячий цех"},
                  );
                },
              ),
              MenuItem(
                icon: Icons.build_circle,
                title: "Сборка",
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/collect',
                    arguments: {"screenId": "3"},
                  );
                },
              ),
              MenuItem(
                icon: Icons.receipt,
                title: "Накладные",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllInvoicesPage(),
                    ),
                  );
                },
              ),
              MenuItem(
                icon: Icons.add_shopping_cart,
                title: "Внести товар",
                onTap: () {
                  Navigator.pushNamed(context, '/addPrepack');
                },
              ),
              MenuItem(
                icon: Icons.store,
                title: "Склад",
                onTap: () {
                  Navigator.pushNamed(context, '/warehouse');
                },
              ),
              MenuItem(
                icon: Icons.print,
                title: "Принтер",
                onTap: () {
                  Navigator.pushNamed(context, '/print');
                },
              ),
              MenuItem(
                icon: Icons.delete,
                title: "Списания",
                onTap: () {
                  Navigator.pushNamed(context, '/writeOff');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
