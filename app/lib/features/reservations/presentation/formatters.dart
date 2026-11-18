import 'package:intl/intl.dart';

/// MXN prices, as the mockups show them ("$75.00").
final mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "17 de noviembre de 2026, 20:15" in the phone's time zone. The API sends
/// UTC; the user reads local time. Kept manual to avoid loading locale data.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} de ${_months[local.month - 1]} de ${local.year}, '
      '$hour:$minute';
}
