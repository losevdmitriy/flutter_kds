import 'package:flutter/material.dart';
import 'package:regexed_validator/regexed_validator.dart';

class IpInputDialog extends StatefulWidget {
  final Function(String) onIpEntered;

  const IpInputDialog({Key? key, required this.onIpEntered}) : super(key: key);

  @override
  _IpInputDialogState createState() => _IpInputDialogState();
}

class _IpInputDialogState extends State<IpInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _validateAndSubmit() {
    String ip = _controller.text.trim();
    if (validator.ip(ip)) {
      widget.onIpEntered(ip);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorText = "Введите корректный IP-адрес";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Введите IP-адрес"),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "192.168.1.1",
          errorText: _errorText,
        ),
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
