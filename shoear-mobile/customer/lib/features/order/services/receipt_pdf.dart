import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:customer/features/order/models/order.dart';

/// Renders a [Receipt] to a PDF and shows the OS sheet to save / share / print
/// (and email-it-yourself). Used by the receipt screen's "Download / Share"
/// button — fully on-device, no backend.

String _money(double n) => 'RM ${n.toStringAsFixed(2)}';

String _fmt(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day}/${d.month}/${d.year}  $h:$mm $ampm';
}

Future<Uint8List> buildReceiptPdf(Receipt r) async {
  final doc = pw.Document();
  const accent = PdfColor.fromInt(0xFF4F46E5);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // ── Header ───────────────────────────────────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('ShoeAR', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 13)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Order ${r.orderId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (r.paymentDate != null)
                pw.Text(_fmt(r.paymentDate), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (r.receiptId.isNotEmpty)
                pw.Text('Receipt ${r.receiptId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ]),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),

        // ── Billed to / Sold by ──────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Billed to', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text(r.customerName ?? '-', style: const pw.TextStyle(fontSize: 11)),
              ]),
            ),
            if (r.sellers.isNotEmpty)
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Sold by', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(r.sellers.join(', '), style: const pw.TextStyle(fontSize: 11)),
                ]),
              ),
          ],
        ),
        pw.SizedBox(height: 14),

        // ── Items ────────────────────────────────────────────────────────
        pw.Text('Order Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Product', 'Size', 'Qty', 'Unit price', 'Subtotal'],
          data: r.items
              .map((i) => [i.brand.isEmpty ? i.productName : '${i.brand} ${i.productName}',
                  i.size, '${i.qty}', _money(i.unitPrice), _money(i.subtotal)])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: accent),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignments: {
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total paid: ${_money(r.total)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accent)),
        ),
        pw.SizedBox(height: 16),

        // ── Payment ──────────────────────────────────────────────────────
        pw.Text('Payment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 4),
        pw.Text('Method: ${r.paymentMethod ?? '-'}', style: const pw.TextStyle(fontSize: 11)),
        if ((r.transactionId ?? '').isNotEmpty)
          pw.Text('Reference: ${r.transactionId}', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 16),

        // ── Delivery address ─────────────────────────────────────────────
        pw.Text('Delivery Address', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 4),
        pw.Text(r.deliveryAddress, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 24),

        pw.Divider(color: PdfColors.grey400),
        pw.Text('This is a system-generated receipt from ShoeAR. Thank you for your purchase.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    ),
  );
  return doc.save();
}

/// Render + open the native save / share / print sheet.
Future<void> shareReceiptPdf(Receipt r) async {
  final bytes = await buildReceiptPdf(r);
  await Printing.sharePdf(bytes: bytes, filename: 'Receipt_${r.orderId}.pdf');
}
