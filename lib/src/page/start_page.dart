import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/widgets/ip_input_dialog.dart';
import 'package:flutter_iem_new/src/config/api_config.dart';

import '../widgets/menu_item.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    // Проверяем IP при запуске приложения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIpConfiguration();
    });
  }

  void _checkIpConfiguration() {
    if (!ApiConfig.isIpConfigured()) {
      _showIpDialog();
    }
  }

  void _showIpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Нельзя закрыть диалог без выбора
      builder: (context) => IpInputDialog(
        onIpEntered: (String fullAddress) {
          setState(() {}); // Обновляем UI для отображения нового города
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("IP-адрес успешно обновлен!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCity = ApiConfig.getCurrentCity();
    final isConfigured = ApiConfig.isIpConfigured();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Главная страница"),
            if (isConfigured && currentCity != null)
              Text(
                currentCity,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              )
            else if (isConfigured)
              Text(
                "${ApiConfig.ip}:${ApiConfig.port}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              )
            else
              const Text(
                "IP не настроен",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isConfigured ? Icons.settings : Icons.warning,
              color: isConfigured ? null : Colors.orange,
            ),
            onPressed: () => _showIpDialog(),
            tooltip: isConfigured ? "Настроить IP-адрес" : "Настроить подключение",
          ),
        ],
      ),
      body: Column(
        children: [
          // Предупреждение, если IP не настроен
          if (!isConfigured)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Необходимо настроить подключение к серверу",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showIpDialog(),
                    child: const Text("Настроить"),
                  ),
                ],
              ),
            ),
          
          // Основное содержимое
          Expanded(
            child: Center(
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
                icon: Icons.restaurant_menu,
                title: "ТТК",
                onTap: () {
                  Navigator.pushNamed(context, '/ttk');
                },
              ),
            ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
