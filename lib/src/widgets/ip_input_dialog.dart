import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iem_new/src/config/api_config.dart';
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

  /// Проверяет, является ли строка корректным IP-адресом (IPv4 или IPv6).
  bool _isValidIp(String ip) {
    return validator.ip(ip); // Используем библиотеку regexed_validator
  }

  /// Проверяет, является ли введённый порт числом в диапазоне 1-65535.
  bool _isValidPort(String port) {
    final portNumber = int.tryParse(port);
    return portNumber != null && portNumber >= 1 && portNumber <= 65535;
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
      ApiConfig.ip = ip;
      ApiConfig.port = int.parse(port);
      String fullAddress = "$ip:$port";
      widget.onIpEntered(fullAddress);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Введите IP-адрес и порт"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
