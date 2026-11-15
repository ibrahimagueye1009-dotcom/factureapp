import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../companies.dart';
import '../models.dart';
import 'account.dart';

class InvoiceStore {
  static const _key = 'invoices_v1';
  static const _scopedPrefix = 'invoices_v2_';

  static String _scopedKey(String accountId) => '$_scopedPrefix$accountId';

  static Future<String> _accountKey() async {
    final account = await AccountStore.current();
    if (account == null) return 'legacy';
    final p = await SharedPreferences.getInstance();
    final key = _scopedKey(account.id);
    if (account.isLegacy && p.getString(key) == null) {
      final oldInvoices = p.getString(_key);
      if (oldInvoices != null) await p.setString(key, oldInvoices);
    }
    return key;
  }

  static Future<List<Invoice>> all({String? companyId}) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(await _accountKey());
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((i) => companyId == null || i.companyId == companyId)
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(List<Invoice> l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        await _accountKey(), jsonEncode(l.map((e) => e.toJson()).toList()));
  }

  static Future<void> save(Invoice inv) async {
    inv.updatedAt = DateTime.now();
    final l = await all();
    final i = l.indexWhere((x) => x.id == inv.id);
    if (i >= 0) {
      l[i] = inv;
    } else {
      l.add(inv);
    }
    await _write(l);
  }

  static Future<void> delete(String id) async {
    final l = await all();
    l.removeWhere((x) => x.id == id);
    await _write(l);
  }

  static Future<int> countForCompany(String companyId) async =>
      (await all(companyId: companyId)).length;

  static Future<void> deleteForCompany(String companyId) async {
    final l = await all();
    l.removeWhere((invoice) => invoice.companyId == companyId);
    await _write(l);
  }

  /// Prochain numéro : PREFIXE-ANNEE-001, 002, ...
  static Future<String> nextNumber(Company c) async {
    final year = DateTime.now().year;
    final re = RegExp('^${RegExp.escape(c.prefix)}-$year-(\\d+)\$');
    var max = 0;
    for (final i in await all(companyId: c.id)) {
      final m = re.firstMatch(i.number);
      if (m != null) {
        final n = int.parse(m.group(1)!);
        if (n > max) max = n;
      }
    }
    return '${c.prefix}-$year-${(max + 1).toString().padLeft(3, '0')}';
  }
}
