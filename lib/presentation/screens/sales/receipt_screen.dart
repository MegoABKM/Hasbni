// lib/presentation/screens/sales/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for loading assets
import 'package:hasbni/core/utils/app_constants.dart';
import 'package:hasbni/core/utils/extention_shortcut.dart';
import 'package:hasbni/data/models/profile_model.dart';
import 'package:hasbni/data/models/sale_detail_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptScreen extends StatelessWidget {
  final SaleDetail saleDetail;
  final Profile profile;

  const ReceiptScreen({
    super.key,
    required this.saleDetail,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'فاتورة #${saleDetail.id}',
          style: TextStyle(fontSize: scaleConfig.scaleText(20)),
        ),
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        allowSharing: true,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();

    // --- Load the logo image from assets ---
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdfTheme = pw.ThemeData.withFont(base: font, bold: font);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        theme: pdfTheme,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            // --- ADD PADDING TO THE ENTIRE PAGE ---
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _buildHeader(profile),
                  pw.SizedBox(height: 20),
                  _buildSaleInfo(saleDetail),
                  pw.Divider(height: 30, thickness: 1),
                  _buildItemsTable(saleDetail),
                  pw.Divider(height: 30, thickness: 1),
                  _buildTotal(saleDetail),
                  pw.Spacer(),
                  _buildFooter(logoImage), // Pass the logo image to the footer
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(Profile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          profile.shopName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        if (profile.address != null && profile.address!.isNotEmpty)
          pw.Text(profile.address!),
        if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
          pw.Text('الهاتف: ${profile.phoneNumber!}'),
      ],
    );
  }

  pw.Widget _buildSaleInfo(SaleDetail saleDetail) {
    final formattedDate = DateFormat(
      'yyyy-MM-dd – hh:mm a',
      'ar',
    ).format(saleDetail.createdAt);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('فاتورة رقم: #${saleDetail.id}'),
        pw.Text('التاريخ: $formattedDate'),
      ],
    );
  }

  pw.Widget _buildItemsTable(SaleDetail saleDetail) {
    final headers = ['الإجمالي', 'السعر', 'الكمية', 'الصنف'];
    final data = saleDetail.items
        .map((item) {
          final netQuantity = item.quantitySold - item.returnedQuantity;
          if (netQuantity <= 0) return null;
          final total = item.priceAtSale * netQuantity;
          return [
            '${total.toStringAsFixed(2)} ${saleDetail.currencyCode}',
            item.priceAtSale.toStringAsFixed(2),
            netQuantity.toString(),
            item.productName,
          ];
        })
        .where((item) => item != null)
        .cast<List<String>>()
        .toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildTotal(SaleDetail saleDetail) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            '${saleDetail.totalPrice.toStringAsFixed(2)} ${saleDetail.currencyCode}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            ':الإجمالي النهائي',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- UPDATED FOOTER TO ACCEPT THE LOGO IMAGE ---
  pw.Widget _buildFooter(pw.ImageProvider logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Text('شكراً لتعاملكم معنا'),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Powered by ${AppConstants.appName}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.SizedBox(width: 5),
            pw.SizedBox(height: 20, width: 20, child: pw.Image(logoImage)),
          ],
        ),
      ],
    );
  }
}
