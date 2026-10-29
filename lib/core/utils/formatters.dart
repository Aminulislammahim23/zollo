const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `2450` → `৳2,450`, `99.5` → `৳99.50`.
String formatTaka(num amount) {
  final negative = amount < 0;
  final value = amount.abs();
  final isWhole = value == value.roundToDouble();
  final fixed = isWhole ? value.round().toString() : value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = _groupThousands(parts[0]);
  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}৳$grouped$decimals';
}

/// `3400` → `3.4k sold`, `120` → `120 sold`.
String formatSold(int count) {
  if (count >= 1000000) return '${_compact(count / 1000000)}m sold';
  if (count >= 1000) return '${_compact(count / 1000)}k sold';
  return '$count sold';
}

String _compact(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// `DateTime(2026, 10, 13)` → `13 Oct`.
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

/// `13 Oct 2026`.
String formatDateLong(DateTime date) {
  final local = date.toLocal();
  return '${formatDate(local)} ${local.year}';
}

/// `13 Oct, 4:05 PM`.
String formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${formatDate(local)}, $hour:$minute $period';
}

/// `4:05 PM`.
String formatTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

/// Short, human order number for display: `#ZL-1A2B3C`.
String formatOrderNumber(String id) {
  final clean = id.replaceAll('-', '').toUpperCase();
  final short = clean.length > 6 ? clean.substring(0, 6) : clean;
  return '#ZL-$short';
}

/// `just now`, `5m ago`, `3h ago`, `2d ago`, then `13 Oct`.
String formatRelative(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(date);
}
