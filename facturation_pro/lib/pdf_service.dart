import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

Future<Uint8List?> imgBytes(String p) async {
  if (p.isEmpty) return null;
  if (p.startsWith('asset:')) return (await rootBundle.load(p.substring(6))).buffer.asUint8List();
  final f = File(p);
  return await f.exists() ? f.readAsBytes() : null;
}

Future<Uint8List> buildPdf(Company c, Invoice v) async {
  final logo = await imgBytes(c.logo), stamp = await imgBytes(c.stamp);
  final blue = PdfColor.fromInt(0xFF0878CF);
  final doc = pw.Document();
  pw.Widget t(String s, {double size = 10, bool bold = false, PdfColor? color}) => pw.Text(s,
      style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color));
  final ids = [if (c.ninea.isNotEmpty) 'NINEA : ${c.ninea}', if (c.rc.isNotEmpty) 'RC : ${c.rc}'].join('  ·  ');
  final contact = [c.phone, c.address].where((e) => e.isNotEmpty).join('  ·  ');
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    build: (_) => [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (logo != null) pw.Image(pw.MemoryImage(logo), width: 70, height: 70),
        pw.SizedBox(width: 12),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          t(c.name, size: 20, bold: true), t(c.activity), if (ids.isNotEmpty) t(ids), if (contact.isNotEmpty) t(contact),
        ])),
      ]),
      pw.Divider(color: blue, thickness: 2),
      pw.SizedBox(height: 8),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        t('FACTURE', size: 26, bold: true, color: blue),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          t('N° ${v.number}', bold: true), t('Date : ${dateFr(v.date)}'),
        ]),
      ]),
      pw.SizedBox(height: 14),
      pw.Container(
        width: double.infinity, padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F6FC), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          t('CLIENT', size: 8, bold: true, color: blue), t(v.client, size: 12, bold: true),
          if (v.phone.isNotEmpty) t(v.phone), if (v.address.isNotEmpty) t(v.address),
        ]),
      ),
      pw.SizedBox(height: 14),
      pw.TableHelper.fromTextArray(
        headers: ['Désignation', 'Qté', 'Prix unitaire', 'Montant'],
        data: v.items.map((i) => [i.desc, i.qty.toString().replaceAll(RegExp(r'\.0$'), ''), money(i.price), money(i.total)]).toList(),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
        headerDecoration: pw.BoxDecoration(color: blue),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
        columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)},
      ),
      pw.SizedBox(height: 10),
      pw.Align(alignment: pw.Alignment.centerRight, child: t('TOTAL À PAYER : ${money(v.total)}', size: 14, bold: true, color: blue)),
      pw.SizedBox(height: 18),
      if (v.notes.isNotEmpty) t(v.notes),
      if (c.notes.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 6), child: t(c.notes, size: 9)),
      if (stamp != null) pw.Align(alignment: pw.Alignment.centerRight, child: pw.Image(pw.MemoryImage(stamp), width: 150)),
    ],
  ));
  return doc.save();
}
