/// Конфигурация IP-адресов для разных городов
class CityConfig {
  /// IP-адреса для Ухты
  static const String ukhtaIp = '92.53.120.183';
  static const int ukhtaPort = 8005;
  
  /// IP-адреса для Санкт-Петербурга (Парнас)
  static const String spbIp = '92.53.120.183';
  static const int spbPort = 8000;
  
  /// Названия городов
  static const String ukhtaName = 'Ухта';
  static const String spbName = 'Санкт-Петербург (Парнас)';
  
  /// Получить IP и порт по названию города
  static Map<String, dynamic> getCityConfig(String cityName) {
    switch (cityName) {
      case ukhtaName:
        return {'ip': ukhtaIp, 'port': ukhtaPort};
      case spbName:
        return {'ip': spbIp, 'port': spbPort};
      default:
        return {'ip': '', 'port': 0};
    }
  }
  
  /// Получить список всех доступных городов
  static List<String> get availableCities => [ukhtaName, spbName];
}
