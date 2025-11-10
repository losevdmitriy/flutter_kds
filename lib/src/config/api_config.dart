import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'city_config.dart';

class ApiConfig {
  static String _ip = dotenv.env['BASE_URL'] ?? "127.0.0.1";
  static int _port = int.parse(dotenv.env['BASE_PORT'] ?? "8000");

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

  /// Установка конфигурации по названию города
  static void setCityConfig(String cityName) {
    final config = CityConfig.getCityConfig(cityName);
    if (config['ip'] != null && config['port'] != null) {
      setIpAndPort(config['ip'] as String, config['port'] as int);
    }
  }

  /// Получить название текущего города на основе установленного IP
  static String? getCurrentCity() {
    for (String city in CityConfig.availableCities) {
      final config = CityConfig.getCityConfig(city);
      if (config['ip'] == _ip && config['port'] == _port) {
        return city;
      }
    }
    return null; // IP не соответствует ни одному из предустановленных городов
  }

  /// Проверить, установлен ли корректный IP (не дефолтный)
  static bool isIpConfigured() {
    // Проверяем, что IP не является дефолтным значением
    final defaultIp = dotenv.env['BASE_URL'] ?? "127.0.0.1";
    return _ip != "127.0.0.1" && _ip != defaultIp;
  }
}
