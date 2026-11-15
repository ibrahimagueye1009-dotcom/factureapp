/// Format 1 234 567,5 (espace normale, compatible avec la police du PDF).
String fmtNum(num n) {
  final v = (n * 100).round() / 100;
  final neg = v < 0;
  final abs = v.abs();
  final whole = abs.floor();
  final cents = ((abs - whole) * 100).round();
  final s = whole.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  var out = b.toString();
  if (cents > 0) {
    out += ',${cents.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '')}';
  }
  return neg ? '-$out' : out;
}

String money(num n, String currency) => '${fmtNum(n)} $currency';

String todayIso() => toIso(DateTime.now());

String toIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// yyyy-MM-dd -> dd/MM/yyyy
String dateLabel(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso.isEmpty ? '—' : iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

double parseNum(String s) =>
    double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
