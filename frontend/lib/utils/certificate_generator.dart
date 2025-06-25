import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateCertificatePdf({
  required String name,
  required int eventsJoined,
  required double hoursVolunteered,
  required double averageRating,
  required List<String> joinedEvents,
}) async {
  final pdf = pw.Document();
  final now = DateTime.now();

  final logoData = await rootBundle.load('assets/images/logo.png');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

  final signatureData = await rootBundle.load('assets/images/signature.png');
  final signatureImage = pw.MemoryImage(signatureData.buffer.asUint8List());

  final fontData = await rootBundle.load('assets/fonts/GreatVibes-Regular.ttf');
  final customFont = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Watermark-style logo
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.08,
                  child: pw.Image(logoImage, width: 300),
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Text(
                  "Volunsphere Community",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "\"Empowering Change through Action\"",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Title
                pw.Text(
                  'Certificate of Volunteer Appreciation',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange800,
                  ),
                ),
                pw.Divider(thickness: 2, color: PdfColors.amber),

                // Certificate Body
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.amber700),
                    borderRadius: pw.BorderRadius.circular(12),
                    color: PdfColors.white,
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey300,
                        blurRadius: 4,
                        offset: const PdfPoint(2, 2),
                      )
                    ],
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "This certificate is proudly presented to",
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontFallback: [customFont],
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'In recognition of his/her outstanding contribution through:',
                        style: pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 12),
                      _statRow("Total Events", "$eventsJoined"),
                      _statRow("Hours Volunteered", "${hoursVolunteered.toStringAsFixed(1)} hrs"),
                      _statRow("Average Rating", "$averageRating / 5"),

                      pw.SizedBox(height: 18),
                      pw.Text(
                        'Events Participated:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      ...joinedEvents.take(5).map((e) => pw.Bullet(text: e, style: const pw.TextStyle(fontSize: 11))),
                      if (joinedEvents.length > 5)
                        pw.Text("+${joinedEvents.length - 5} more...", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Signature Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.Image(signatureImage, width: 100),
                        pw.Text("Director of Programs", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("Volunsphere Community", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    )
                  ],
                ),

                // Footer
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.Text(
                  'Generated on ${now.toLocal().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _statRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
      ],
    ),
  );
}
