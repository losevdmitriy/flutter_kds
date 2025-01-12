import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/page/all_invoices_act_page.dart';

import 'invoice_act_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная страница"),
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
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   child: const Text("Накладная"),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const InvoicePage(isEditMode: true, invoice: null),
            //       ),
            //     );
            //   },
            // ),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
