import 'package:intl/intl.dart';

String formatHours(double hours) {
  if (hours.isInfinite || hours.isNaN) return '—';
  if (hours >= 24) return '${(hours / 24).toStringAsFixed(1)} d';

  int h = hours.floor();
  int m = ((hours - h) * 60).round();

  // Fix: if minutes round to 60, roll over to the next hour
  if (m == 60) {
    h += 1;
    m = 0;
  }

  return '${h}h ${m}m';
}

String formatW(double w) => '${w.toStringAsFixed(0)} W';
String formatWh(double wh) => '${wh.toStringAsFixed(0)} Wh';

String formatTime(DateTime dt) => DateFormat.Hm().format(dt);
String formatDateTime(DateTime dt) => DateFormat('MMM d, HH:mm').format(dt);

String formatAge(DateTime then) {
  final d = DateTime.now().difference(then);
  if (d.inSeconds < 30) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

String formatChartSubtitle(List<double> loads) {
  if (loads.isEmpty) return 'No data yet';
  final min = loads.reduce((a, b) => a < b ? a : b);
  final max = loads.reduce((a, b) => a > b ? a : b);
  final avg = loads.reduce((a, b) => a + b) / loads.length;
  return 'Last ${loads.length} readings  •  '
      '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} W  •  '
      'avg ${avg.toStringAsFixed(0)} W';
}
