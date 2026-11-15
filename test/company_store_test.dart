import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facturation_pro/companies.dart';
import 'package:facturation_pro/models.dart';
import 'package:facturation_pro/services/account.dart';
import 'package:facturation_pro/services/profile.dart';
import 'package:facturation_pro/services/store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('company serialization preserves invoice profile fields', () {
    final company =
        Company.custom(id: 'fayo-1', name: 'FAYO Services').copyWith(
      taxIdLabel: 'NINEA',
      taxId: '123456789',
      rccm: 'SN.DKR.2026.A.1',
      address: 'Dakar',
      phone: '+221 77 000 00 00',
      email: 'contact@fayo.example',
      signatureAsset: '/local/signature.png',
      stampAsset: '/local/stamp.png',
      currencies: ['FCFA', '€'],
    );

    final restored = Company.fromJson(company.toJson());

    expect(restored.id, company.id);
    expect(restored.name, company.name);
    expect(restored.taxId, company.taxId);
    expect(restored.rccm, company.rccm);
    expect(restored.signatureAsset, company.signatureAsset);
    expect(restored.currencies, company.currencies);
  });

  test('companies and invoices remain isolated per local account', () async {
    expect(
        await AccountStore.create('User A', 'a@example.com', 'passA'), isTrue);
    final companyA = Company.custom(id: 'a-company', name: 'Company A');
    await ProfileStore.save(companyA);
    await InvoiceStore.save(Invoice(
      id: 'invoice-a',
      companyId: companyA.id,
      number: 'A-001',
      date: '2026-01-01',
      clientName: 'Client A',
    ));

    await AccountStore.logout();
    expect(
        await AccountStore.create('User B', 'b@example.com', 'passB'), isTrue);
    expect(await ProfileStore.companies(), isEmpty);
    expect(await InvoiceStore.all(), isEmpty);

    final companyB = Company.custom(id: 'b-company', name: 'Company B');
    await ProfileStore.save(companyB);
    await InvoiceStore.save(Invoice(
      id: 'invoice-b',
      companyId: companyB.id,
      number: 'B-001',
      date: '2026-01-01',
      clientName: 'Client B',
    ));

    await AccountStore.logout();
    expect(await AccountStore.login('a@example.com', 'passA'), isTrue);
    expect((await ProfileStore.companies()).map((c) => c.id), ['a-company']);
    expect((await InvoiceStore.all()).map((i) => i.id), ['invoice-a']);
  });

  test('legacy company profiles and invoices migrate without deleting old data',
      () async {
    SharedPreferences.setMockInitialValues({
      'account_v1': jsonEncode({
        'name': 'Ancien compte',
        'contact': 'ancien@example.com',
        'hash': 'legacy-hash',
        'createdAt': '2025-01-01T00:00:00.000',
      }),
      'account_session_v1': true,
      'company_profiles_v1': jsonEncode({
        'saer': {
          'displayName': 'SAER personnalisé',
          'footerLines': ['Adresse historique'],
        },
      }),
      'invoices_v1': jsonEncode([
        {
          'id': 'legacy-invoice',
          'companyId': 'saer',
          'number': 'SD-2025-001',
          'date': '2025-01-02',
          'clientName': 'Client historique',
          'items': [],
        },
      ]),
    });

    final companies = await ProfileStore.companies();
    final saer = companies.singleWhere((company) => company.id == 'saer');
    final invoices = await InvoiceStore.all(companyId: 'saer');
    final preferences = await SharedPreferences.getInstance();

    expect(companies.map((company) => company.id), ['saer', 'dte']);
    expect(saer.displayName, 'SAER personnalisé');
    expect(saer.footerLines, ['Adresse historique']);
    expect(invoices.single.id, 'legacy-invoice');
    expect(preferences.getString('company_profiles_v1'), isNotNull);
    expect(preferences.getString('invoices_v1'), isNotNull);
  });
}
