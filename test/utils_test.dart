import 'package:facturation_pro/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fmtNum groupe les milliers', () {
    expect(fmtNum(85000), '85 000');
    expect(fmtNum(1234567), '1 234 567');
    expect(fmtNum(12.5), '12,5');
  });
  test('dateLabel', () {
    expect(dateLabel('2026-11-02'), '02/11/2026');
  });
}
