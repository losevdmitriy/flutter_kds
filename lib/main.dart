import 'package:flutter/material.dart';
import 'src/start_page.dart';
import 'src/chef_screen_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Определяем маршруты (routes) в MaterialApp:
  // '/' (root) – это StartPage
  // '/chef' – это ChefScreenPage
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef Screen Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/chef') {
          final args = settings.arguments as Map<String, String>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ChefScreenPage(
                initialScreenId: args['screenId'] ?? '',
                name: args['screenName'] ?? 'Chef Screen',
              ),
            );
          } else {
            // Если аргументы не переданы, используем значения по умолчанию
            return MaterialPageRoute(
              builder: (context) => const ChefScreenPage(
                initialScreenId: '',
                name: 'Chef Screen',
              ),
            );
          }
        }
        return null; // Возвращаем null, если маршрут неизвестен
      },
      routes: {
        '/': (context) => const StartPage(),
      },
    );
  }
}
