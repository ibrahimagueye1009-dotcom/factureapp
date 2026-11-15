import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:facturation_pro/companies.dart';
import 'package:facturation_pro/models.dart';
import 'package:facturation_pro/services/pdf_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les deux modèles génèrent un PDF avec le profil de l’entreprise',
      () async {
    final invoice = Invoice(
      id: 'pdf-test',
      companyId: 'company-test',
      number: 'FAC-2026-001',
      date: '2026-11-03',
      clientName: 'Client test',
      items: [InvoiceItem(desc: 'Prestation', qty: 1, price: 25000)],
    );

    for (final style in InvoiceStyle.values) {
      final company = Company.custom(
        id: 'company-test',
        name: 'Entreprise Test',
      ).copyWith(
        style: style,
        logoAsset: 'assets/images/dte_logo.png',
        signatureAsset: 'assets/images/tampon.png',
        stampAsset: 'assets/images/tampon.png',
        taxId: '123456789',
        rccm: 'SN.DKR.2026.A.1',
        address: 'Dakar',
        phone: '+221 77 000 00 00',
        email: 'contact@example.com',
        invoiceTerms: 'Paiement à réception.',
      );

      final bytes = await PdfBuilder.build(invoice, company);

      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    }
  });
}
