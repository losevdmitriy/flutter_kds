import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String _ip = dotenv.env['BASE_URL'] ?? "127.0.0.1";
  static int _port = 80; // Значение по умолчанию

  /// Геттер для получения полного URL (IP + порт)
  static String get baseUrl => "http://$_ip:$_port";

  /// Геттер для IP-адреса
  static String get ip => _ip;

  /// Сеттер для изменения IP-адреса
  static set ip(String newIp) {
    _ip = newIp;
  }

  /// Геттер для порта
  static int get port => _port;

  /// Сеттер для изменения порта
  static set port(int newPort) {
    if (newPort > 0 && newPort <= 65535) {
      _port = newPort;
    } else {
      throw Exception(
          "Некорректный порт: $newPort. Допустимый диапазон: 1-65535.");
    }
  }

  /// Установка IP-адреса и порта вместе
  static void setIpAndPort(String newIp, int newPort) {
    ip = newIp;
    port = newPort;
  }
}
