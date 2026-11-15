import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../companies.dart';
import '../models.dart';
import '../utils.dart';
import '../utils/image_bytes.dart' show loadImageBytes;

class PdfBuilder {
  /// Charge une image : d'abord depuis le fichier choisi dans le profil
  /// (chemin local), sinon depuis les assets intégrés à l'application.
  static Future<pw.MemoryImage?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = await loadImageBytes(path);
      if (file != null) return pw.MemoryImage(file);
    } catch (_) {}
    try {
      final asset = await rootBundle.load(path);
      return pw.MemoryImage(asset.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> build(Invoice inv, Company c) async {
    final reg = pw.Font.ttf(
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'));
    final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'));
    final logo = await _loadImage(c.logoAsset);
    final stamp = await _loadImage(c.stampAsset);
    final signature = await _loadImage(c.signatureAsset);
    final doc = pw.Document(title: 'Facture ${inv.number}', author: c.name);
    if (c.style == InvoiceStyle.classic) {
      _classic(doc, inv, c, reg, bold, logo, stamp, signature);
    } else {
      _modern(doc, inv, c, reg, bold, logo, stamp, signature);
    }
    return doc.save();
  }

  static pw.Widget _cell(String t,
          {pw.TextAlign align = pw.TextAlign.left,
          bool isBold = false,
          PdfColor? color,
          double size = 10}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(
                fontSize: size,
                color: color,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  static List<String> _companyDetails(Company company) => [
        if (company.taxId.isNotEmpty) '${company.taxIdLabel}: ${company.taxId}',
        if (company.rccm.isNotEmpty) 'RCCM: ${company.rccm}',
        if (company.address.isNotEmpty) company.address,
        if (company.phone.isNotEmpty) 'Tél. : ${company.phone}',
        if (company.email.isNotEmpty) 'E-mail : ${company.email}',
      ];

  // ---------- SAER DRAME : facture classique ----------
  static void _classic(
      pw.Document doc,
      Invoice inv,
      Company c,
      pw.Font reg,
      pw.Font bold,
      pw.MemoryImage? logo,
      pw.MemoryImage? stamp,
      pw.MemoryImage? signature) {
    final blue = PdfColor.fromInt(c.color);
    final cur = inv.currency;

    doc.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
        theme: pw.ThemeData.withFont(base: reg, bold: bold),
        buildBackground: (ctx) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: 0.6,
              child: pw.Text(c.name.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 80,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFFF1F4F9))),
            ),
          ),
        ),
      ),
      footer: (ctx) => pw.Column(children: [
        pw.Divider(color: blue, thickness: 1.5),
        ...c.footerLines.map((l) => pw.Text(l,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: blue))),
      ]),
      build: (ctx) => [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.SizedBox(
            width: 150,
            child: pw.Column(children: [
              if (logo != null)
                pw.Container(
                  width: 78,
                  height: 78,
                  decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: blue, width: 1.5)),
                  child:
                      pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover)),
                ),
              pw.SizedBox(height: 4),
              pw.Text(c.displayName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: blue)),
            ]),
          ),
          pw.Expanded(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                  color: blue, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(c.name,
                        style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 3),
                    ...c.bannerLines.map((l) => pw.Text(l,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.white))),
                    ...c.detailLines.map((detail) => pw.Text(detail,
                        softWrap: true,
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.white))),
                    ..._companyDetails(c).map((detail) => pw.Text(detail,
                        softWrap: true,
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.white))),
                  ]),
            ),
          ),
        ]),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Dakar, le ${dateLabel(inv.date)}',
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(children: [
            pw.Text('FACTURE',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 3),
            pw.Text('N° ${inv.number}',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          pw.Text('Client : ',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline)),
          pw.Expanded(
              child: pw.Text(inv.clientName,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold))),
        ]),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(width: 0.8),
          columnWidths: {
            0: const pw.FixedColumnWidth(42),
            1: const pw.FlexColumnWidth(),
            2: const pw.FixedColumnWidth(88),
            3: const pw.FixedColumnWidth(98),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Qté', align: pw.TextAlign.center, isBold: true),
                _cell('DESIGNATION', isBold: true),
                _cell('Prix Unitaire', align: pw.TextAlign.right, isBold: true),
                _cell('Prix Total', align: pw.TextAlign.right, isBold: true),
              ],
            ),
            ...inv.items.map((i) => pw.TableRow(children: [
                  _cell(fmtNum(i.qty), align: pw.TextAlign.center),
                  _cell(i.desc),
                  _cell(money(i.price, cur), align: pw.TextAlign.right),
                  _cell(money(i.total, cur),
                      align: pw.TextAlign.right, isBold: true),
                ])),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Text('TOTAL  =  ',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Container(
            width: 98,
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Text(money(inv.total, cur),
                textAlign: pw.TextAlign.right,
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
        ]),
        pw.SizedBox(height: 20),
        if (c.invoiceTerms.isNotEmpty) ...[
          pw.Text(c.invoiceTerms,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
        ],
        ...c.bankLines.map((b) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(
                    style: const pw.TextStyle(fontSize: 9.5),
                    children: [
                      pw.TextSpan(
                          text: '${b.$1} : ',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline)),
                      pw.TextSpan(text: b.$2),
                    ]),
              ),
            )),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(children: [
            pw.Text(c.name,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              if (signature != null)
                pw.Image(signature,
                    width: 90, height: 55, fit: pw.BoxFit.contain),
              if (stamp != null)
                pw.Image(stamp, width: 110, height: 70, fit: pw.BoxFit.contain),
            ]),
          ]),
        ),
      ],
    ));
  }

  // ---------- D-T-E : facture moderne ----------
  static void _modern(
      pw.Document doc,
      Invoice inv,
      Company c,
      pw.Font reg,
      pw.Font bold,
      pw.MemoryImage? logo,
      pw.MemoryImage? stamp,
      pw.MemoryImage? signature) {
    final blue = PdfColor.fromInt(c.color);
    final navy = PdfColor.fromInt(0xFF102B50);
    final gray = PdfColor.fromInt(0xFF526174);
    final line = PdfColor.fromInt(0xFFD9E1EA);
    final cur = inv.currency;
    final details = [inv.clientAddress, inv.clientPhone, inv.clientEmail]
        .where((e) => e.isNotEmpty)
        .join(' · ');

    doc.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 34, 40, 28),
        theme: pw.ThemeData.withFont(base: reg, bold: bold),
      ),
      footer: (ctx) => pw.Column(children: [
        pw.Divider(color: line),
        ...c.footerLines.map((l) => pw.Text(l,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: gray))),
      ]),
      build: (ctx) => [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logo != null)
            pw.Container(
              width: 78,
              height: 78,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: blue, width: 1.2)),
              child: pw.ClipRRect(
                  horizontalRadius: 12,
                  verticalRadius: 12,
                  child: pw.Image(logo, fit: pw.BoxFit.contain)),
            )
          else
            pw.Container(
              width: 78,
              height: 78,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  color: blue, borderRadius: pw.BorderRadius.circular(12)),
              child: pw.Text('DTE',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold)),
            ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(c.displayName,
                      softWrap: true,
                      style: pw.TextStyle(
                          fontSize: 13,
                          color: navy,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  ...c.bannerLines.map((l) => pw.Text(l,
                      softWrap: true,
                      style: pw.TextStyle(fontSize: 8.5, color: gray))),
                  ...c.detailLines.map((l) => pw.Text(l,
                      softWrap: true,
                      style: pw.TextStyle(fontSize: 8.5, color: gray))),
                  ..._companyDetails(c).map((detail) => pw.Text(detail,
                      softWrap: true,
                      style: pw.TextStyle(fontSize: 8.5, color: gray))),
                ]),
          ),
        ]),
        pw.SizedBox(height: 12),
        pw.Divider(color: blue, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Expanded(
            child: pw.Text('FACTURE',
                style: pw.TextStyle(
                    fontSize: 26, color: navy, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('N° ${inv.number}',
                style: pw.TextStyle(
                    fontSize: 11, color: navy, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text('Date : ${dateLabel(inv.date)}',
                style: const pw.TextStyle(fontSize: 10)),
          ]),
        ]),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3F8FC),
              borderRadius: pw.BorderRadius.circular(5)),
          child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLIENT',
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: blue,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(inv.clientName,
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        if (details.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 3),
                            child: pw.Text(details,
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                      ]),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RÈGLEMENT',
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: blue,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(
                            'Mode : ${inv.paymentMode.isEmpty ? 'À préciser' : inv.paymentMode}',
                            style: const pw.TextStyle(fontSize: 9.5)),
                        pw.Text('Devise : $cur',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ]),
                ),
              ]),
        ),
        pw.SizedBox(height: 18),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FixedColumnWidth(42),
            2: const pw.FixedColumnWidth(92),
            3: const pw.FixedColumnWidth(100),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: navy),
              children: [
                _cell('DÉSIGNATION',
                    isBold: true, color: PdfColors.white, size: 8.5),
                _cell('QTÉ',
                    align: pw.TextAlign.right,
                    isBold: true,
                    color: PdfColors.white,
                    size: 8.5),
                _cell('PRIX UNIT.',
                    align: pw.TextAlign.right,
                    isBold: true,
                    color: PdfColors.white,
                    size: 8.5),
                _cell('MONTANT',
                    align: pw.TextAlign.right,
                    isBold: true,
                    color: PdfColors.white,
                    size: 8.5),
              ],
            ),
            ...inv.items.map((i) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: line))),
                  children: [
                    _cell(i.desc.isEmpty ? '—' : i.desc, size: 9.5),
                    _cell(fmtNum(i.qty), align: pw.TextAlign.right, size: 9.5),
                    _cell(money(i.price, cur),
                        align: pw.TextAlign.right, size: 9.5),
                    _cell(money(i.total, cur),
                        align: pw.TextAlign.right, size: 9.5),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 270,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF0F7FF),
                borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Column(children: [
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sous-total',
                        style: pw.TextStyle(fontSize: 9.5, color: gray)),
                    pw.Text(money(inv.total, cur),
                        style: pw.TextStyle(fontSize: 9.5, color: navy)),
                  ]),
              pw.SizedBox(height: 8),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL À PAYER',
                        style: pw.TextStyle(
                            fontSize: 12,
                            color: navy,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(money(inv.total, cur),
                        style: pw.TextStyle(
                            fontSize: 12,
                            color: blue,
                            fontWeight: pw.FontWeight.bold)),
                  ]),
            ]),
          ),
        ),
        pw.SizedBox(height: 22),
        pw.Text('Note',
            style: pw.TextStyle(
                fontSize: 9, color: navy, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
            inv.notes.isEmpty
                ? (c.invoiceTerms.isEmpty
                    ? 'Merci pour votre confiance.'
                    : c.invoiceTerms)
                : inv.notes,
            style: pw.TextStyle(fontSize: 9, color: gray)),
        if (c.bankLines.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          ...c.bankLines.map((bank) => pw.Text('${bank.$1} : ${bank.$2}',
              style: pw.TextStyle(fontSize: 8.5, color: gray))),
        ],
        if (stamp != null || signature != null) ...[
          pw.SizedBox(height: 18),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (signature != null)
                  pw.Image(signature,
                      width: 120, height: 65, fit: pw.BoxFit.contain),
                if (stamp != null)
                  pw.Image(stamp,
                      width: 150, height: 75, fit: pw.BoxFit.contain),
              ]),
        ],
      ],
    ));
  }
}
