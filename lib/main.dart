import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_iem_new/src/page/Warehouse/warehouse_page.dart';
import 'package:flutter_iem_new/src/page/collector_screen_page.dart';
import 'src/page/processing_screens/all_processing_acts_screen.dart';
import 'src/page/start_page.dart';
import 'src/page/chef_screen_page.dart';

Future<void> main() async {
  const String envFile = bool.fromEnvironment('dart.vm.product') 
      ? '.env.production' 
      : '.env.development';

  await dotenv.load(fileName: envFile);
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
        } else if (settings.name == '/addPrepack') {
          return MaterialPageRoute(
              builder: (context) => AllProcessingActsScreen());
        } else if (settings.name == '/warehouse') {
          return MaterialPageRoute(builder: (context) => WarehouseScreen());
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
