/// Date helpers ported from the prototype's dates.ts. Calendar dates are local
/// `YYYY-MM-DD` strings; timestamps are [DateTime]s.
String _pad(int n) => n.toString().padLeft(2, '0');

String ymd(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

String today([DateTime? now]) => ymd(now ?? DateTime.now());

DateTime parseYmd(String s) {
  final p = s.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String base, int days) {
  final d = parseYmd(base);
  return ymd(DateTime(d.year, d.month, d.day + days));
}

/// Whole local days from [a] to [b] (b - a). Uses calendar fields, so DST does not skew it.
int daysBetween(String a, String b) {
  final x = parseYmd(a), y = parseYmd(b);
  return DateTime.utc(
    y.year,
    y.month,
    y.day,
  ).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
}

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
const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _daysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String shortDateYmd(String s) => shortDate(parseYmd(s));

String longDate([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${_daysLong[d.weekday - 1]}, ${d.day} ${_monthsLong[d.month - 1]}';
}

String timeOf(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';

String relative(DateTime at, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = daysBetween(ymd(at), ymd(n));
  if (days <= 0) return 'Today, ${timeOf(at)}';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return shortDate(at);
}

enum ActivityGroup {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('Earlier this week'),
  earlier('Earlier');

  const ActivityGroup(this.label);
  final String label;
}

ActivityGroup groupOf(DateTime at, {DateTime? now}) {
  final days = daysBetween(ymd(at), ymd(now ?? DateTime.now()));
  if (days <= 0) return ActivityGroup.today;
  if (days == 1) return ActivityGroup.yesterday;
  if (days < 7) return ActivityGroup.thisWeek;
  return ActivityGroup.earlier;
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  return h < 12
      ? 'Good morning'
      : h < 18
      ? 'Good afternoon'
      : 'Good evening';
}
