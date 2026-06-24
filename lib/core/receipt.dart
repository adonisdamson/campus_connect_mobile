import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

typedef ReceiptRow = ({String label, String value});

/// Build a branded PDF receipt and open the share sheet.
Future<void> shareReceipt({
  required String title,
  required String reference,
  required List<ReceiptRow> rows,
  required double total,
}) async {
  final doc = pw.Document();
  const lime = PdfColor.fromInt(0xFFCBFF3C);
  const ink = PdfColor.fromInt(0xFF0E0F12);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    build: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.all(28),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(color: lime, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Text('CAMPUS CONNECT', style: pw.TextStyle(color: ink, fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ),
        pw.SizedBox(height: 20),
        pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Ref: $reference', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 18),
        pw.Divider(),
        ...rows.map((r) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text(r.label, style: const pw.TextStyle(color: PdfColors.grey700)),
                pw.Text(r.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]),
            )),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('GHC ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.Spacer(),
        pw.Text('Thank you for riding & ordering on campus 💚', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ]),
    ),
  ));

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/receipt_$reference.pdf');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: 'Campus Connect receipt');
}
