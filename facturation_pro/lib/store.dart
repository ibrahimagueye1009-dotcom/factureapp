import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Store extends ChangeNotifier {
  static final Store i = Store();
  late SharedPreferences _p;
  List<Company> companies = [];
  List<Invoice> invoices = [];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final c = _p.getString('companies'), v = _p.getString('invoices');
    companies = c == null
        ? _seed()
        : (jsonDecode(c) as List).map((e) => Company.fromJson(e)).toList();
    invoices = v == null
        ? []
        : (jsonDecode(v) as List).map((e) => Invoice.fromJson(e)).toList();
    if (c == null) await _save();
  }

  List<Company> _seed() => [
        Company(
            id: 'saer',
            name: 'SAER DRAME',
            prefix: 'SAER',
            activity: 'Fabrication - Mécanique · Monteur Dépanneur Frigoriste',
            rc: 'SN.DKR.2018.A.12566',
            phone: '00 221 77 638 74 14',
            address: 'Dakar, Sénégal',
            logo: 'asset:assets/saer_logo.jpg',
            stamp: 'asset:assets/saer_stamp.png'),
        Company(
            id: 'dte',
            name: 'D-T-E',
            prefix: 'DTE',
            activity: 'Drame Technologique et Électronique',
            ninea: '013210018',
            rc: 'SN.DKR.2026.A.40988',
            phone: '78 584 15 88 / 77 988 49 16',
            address: 'Dakar, Sénégal',
            logo: 'asset:assets/dte_logo.png'),
      ];

  Future<void> _save() async {
    await _p.setString(
        'companies', jsonEncode(companies.map((e) => e.toJson()).toList()));
    await _p.setString(
        'invoices', jsonEncode(invoices.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Company? company(String id) => companies.where((c) => c.id == id).firstOrNull;
  Future<void> saveCompany(Company c) async {
    final k = companies.indexWhere((x) => x.id == c.id);
    k >= 0 ? companies[k] = c : companies.add(c);
    await _save();
  }

  Future<void> deleteCompany(String id) async {
    companies.removeWhere((c) => c.id == id);
    invoices.removeWhere((v) => v.companyId == id);
    await _save();
  }

  Future<void> saveInvoice(Invoice v) async {
    final k = invoices.indexWhere((x) => x.id == v.id);
    k >= 0 ? invoices[k] = v : invoices.insert(0, v);
    await _save();
  }

  Future<void> deleteInvoice(String id) async {
    invoices.removeWhere((v) => v.id == id);
    await _save();
  }

  String nextNumber(Company c) {
    final n = invoices.where((v) => v.companyId == c.id).length + 1;
    return '${c.prefix}-${DateTime.now().year}-${n.toString().padLeft(3, '0')}';
  }
}
