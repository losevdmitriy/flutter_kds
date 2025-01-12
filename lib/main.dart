import 'package:flutter/material.dart';
import 'package:flutter_iem_new/src/page/collector_screen_page.dart';
import 'src/page/start_page.dart';
import 'src/page/chef_screen_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef Screen Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/chef') {
          final args = settings.arguments as Map<String, String>?;
          return MaterialPageRoute(
            builder: (context) => ChefScreenPage(
              initialScreenId: args?['screenId'] ?? '',
              name: args?['screenName'] ?? 'Chef Screen',
            ),
          );
        } else if (settings.name == '/collect') {
          final args = settings.arguments as Map<String, String>?;
          return MaterialPageRoute(
            builder: (context) => CollectorScreenPage(
              initialScreenId: args?['screenId'] ?? '',
            ),
          );
        }

        // Неизвестный маршрут
        return MaterialPageRoute(
          builder: (context) => const StartPage(),
        );
      },
      routes: {
        '/': (context) => const StartPage(),
      },
    );
  }
}
