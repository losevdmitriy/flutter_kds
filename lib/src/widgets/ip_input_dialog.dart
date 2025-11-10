import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iem_new/src/config/api_config.dart';
import 'package:flutter_iem_new/src/config/city_config.dart';
import 'package:regexed_validator/regexed_validator.dart';

class IpInputDialog extends StatefulWidget {
  final Function(String address) onIpEntered;

  const IpInputDialog({Key? key, required this.onIpEntered}) : super(key: key);

  @override
  _IpInputDialogState createState() => _IpInputDialogState();
}

class _IpInputDialogState extends State<IpInputDialog> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  String? _ipErrorText;
  String? _portErrorText;
  String? _selectedCity;

  /// Проверяет, является ли строка корректным IP-адресом (IPv4 или IPv6).
  bool _isValidIp(String ip) {
    return validator.ip(ip); // Используем библиотеку regexed_validator
  }

  /// Проверяет, является ли введённый порт числом в диапазоне 1-65535.
  bool _isValidPort(String port) {
    final portNumber = int.tryParse(port);
    return portNumber != null && portNumber >= 1 && portNumber <= 65535;
  }

  /// Обрабатывает выбор города и автоматически заполняет IP и порт
  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      if (city != null) {
        final config = CityConfig.getCityConfig(city);
        _ipController.text = config['ip'] as String;
        _portController.text = config['port'].toString();
        
        // Очищаем ошибки при автоматическом заполнении
        _ipErrorText = null;
        _portErrorText = null;
      }
    });
  }

  void _validateAndSubmit() {
    String ip = _ipController.text.trim();
    String port = _portController.text.trim();

    setState(() {
      if (ip.isNotEmpty) {
        _ipErrorText = _isValidIp(ip) ? null : "Введите корректный IP-адрес";
      }
      if (port.isNotEmpty) {
        _portErrorText = _isValidPort(port) ? null : "Введите порт (1-65535)";
      }
    });

    if (_ipErrorText == null && _portErrorText == null) {
      // Если выбран город, используем его конфигурацию
      if (_selectedCity != null) {
        ApiConfig.setCityConfig(_selectedCity!);
      } else {
        // Иначе устанавливаем вручную введенные значения
        ApiConfig.ip = ip;
        ApiConfig.port = int.parse(port);
      }
      String fullAddress = "$ip:$port";
      widget.onIpEntered(fullAddress);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Настройка подключения"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Выбор города
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: const InputDecoration(
              labelText: "Выберите город",
              border: OutlineInputBorder(),
            ),
            items: CityConfig.availableCities.map((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: _onCitySelected,
          ),
          const SizedBox(height: 16),
          
          // Разделитель
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text("или", style: TextStyle(color: Colors.grey[600])),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Ручной ввод IP
          TextField(
            controller: _ipController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true), // Числовая клавиатура с точкой
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(
                  "[0-9.:]")), // Разрешает только цифры, точки и двоеточия
            ],
            decoration: InputDecoration(
              labelText: "IP-адрес",
              hintText: ApiConfig.ip,
              errorText: _ipErrorText,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Только цифры
            ],
            decoration: InputDecoration(
              labelText: "Порт",
              hintText: ApiConfig.port.toString(),
              errorText: _portErrorText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }
}
