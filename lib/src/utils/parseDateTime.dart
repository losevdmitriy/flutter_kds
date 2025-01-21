import 'package:intl/intl.dart';

/// Пытается спарсить дату/время из строки.
/// Если парсинг не удался или строка null/пустая — вернёт null.
DateTime? parseDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    // Если формат даты с бэка "сломанный" или не соответствует ISO-8601
    return null;
  }
}

/// Форматирует дату в читабельном виде "дд.мм.гггг чч:мм"
/// Если дата null, то возвращаем "-"
String formatDateTime(String? dateStr) {
  final dateTime = parseDateTime(dateStr);
  if (dateTime == null) {
    return '-';
  }
  return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
}
