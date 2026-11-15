import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../companies.dart';
import '../models.dart';
import '../services/pdf_builder.dart';

/// Aperçu du PDF avec boutons Partager / Imprimer / Enregistrer.
class PdfScreen extends StatelessWidget {
  final Invoice invoice;
  final Company company;
  const PdfScreen({super.key, required this.invoice, required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(company.color),
        foregroundColor: Colors.white,
        title: Text('Facture ${invoice.number}'),
      ),
      body: PdfPreview(
        build: (format) => PdfBuilder.build(invoice, company),
        pdfFileName: 'Facture_${company.name.replaceAll(' ', '_')}_${invoice.number}.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
