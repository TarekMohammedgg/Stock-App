import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gdrive_tutorial/core/utils.dart';
import 'package:gdrive_tutorial/features/invoice/data/api/pdf_api.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/customer.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/invoice.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/supplier.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

/// Invoice labels - used for localization
class InvoiceLabels {
  final String invoiceTitle;
  final String invoiceNumber;
  final String invoiceDate;
  final String transactionDate;
  final String description;
  final String date;
  final String quantity;
  final String unitPrice;
  final String total;
  final String netTotal;
  final String totalAmountDue;
  final String address;
  final bool isRtl;

  const InvoiceLabels({
    required this.invoiceTitle,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.transactionDate,
    required this.description,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.netTotal,
    required this.totalAmountDue,
    required this.address,
    required this.isRtl,
  });

  /// Default English labels
  factory InvoiceLabels.english() => const InvoiceLabels(
    invoiceTitle: 'INVOICE',
    invoiceNumber: 'Invoice Number:',
    invoiceDate: 'Invoice Date:',
    transactionDate: 'Transaction Date:',
    description: 'Description',
    date: 'Date',
    quantity: 'Quantity',
    unitPrice: 'Unit Price',
    total: 'Total',
    netTotal: 'Net total',
    totalAmountDue: 'Total amount due',
    address: 'Address',
    isRtl: false,
  );

  /// Arabic labels
  factory InvoiceLabels.arabic() => const InvoiceLabels(
    invoiceTitle: 'فاتورة',
    invoiceNumber: 'رقم الفاتورة:',
    invoiceDate: 'تاريخ الفاتورة:',
    transactionDate: 'تاريخ المعاملة:',
    description: 'الوصف',
    date: 'التاريخ',
    quantity: 'الكمية',
    unitPrice: 'سعر الوحدة',
    total: 'الإجمالي',
    netTotal: 'المجموع الصافي',
    totalAmountDue: 'المبلغ الإجمالي المستحق',
    address: 'العنوان',
    isRtl: true,
  );
}

class PdfInvoiceApi {
  static pw.Font? _arabicFont;

  /// Load Arabic-supporting font
  static Future<pw.Font> _loadArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;

    // Try to load Noto Naskh Arabic font from assets
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      _arabicFont = pw.Font.ttf(fontData);
      return _arabicFont!;
    } catch (e) {
      // Fallback to default font
      return pw.Font.helvetica();
    }
  }

  static Future<File> generate(
    Invoice invoice, {
    String languageCode = 'en',
  }) async {
    final pdf = Document();

    // Determine labels based on language
    final labels = languageCode == 'ar'
        ? InvoiceLabels.arabic()
        : InvoiceLabels.english();

    // Load Arabic font if needed
    pw.Font? font;
    if (labels.isRtl) {
      font = await _loadArabicFont();
    }

    pdf.addPage(
      MultiPage(
        textDirection: labels.isRtl
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        theme: labels.isRtl && font != null
            ? ThemeData.withFont(base: font, bold: font)
            : null,
        build: (context) => [
          buildHeader(invoice, labels),
          SizedBox(height: 3 * PdfPageFormat.cm),
          buildTitle(invoice, labels),
          buildInvoice(invoice, labels),
          Divider(),
          buildTotal(invoice, labels),
        ],
        footer: (context) => buildFooter(invoice, labels),
      ),
    );

    return PdfApi.saveDocument(name: 'my_invoice.pdf', pdf: pdf);
  }

  static Widget buildHeader(Invoice invoice, InvoiceLabels labels) => Column(
    crossAxisAlignment: labels.isRtl
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.isRtl
            ? [
                Container(
                  height: 50,
                  width: 50,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: invoice.info.number,
                  ),
                ),
                buildSupplierAddress(invoice.supplier, labels),
              ]
            : [
                buildSupplierAddress(invoice.supplier, labels),
                Container(
                  height: 50,
                  width: 50,
                  child: BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: invoice.info.number,
                  ),
                ),
              ],
      ),
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.isRtl
            ? [
                buildInvoiceInfo(invoice.info, labels),
                buildCustomerAddress(invoice.customer, labels),
              ]
            : [
                buildCustomerAddress(invoice.customer, labels),
                buildInvoiceInfo(invoice.info, labels),
              ],
      ),
    ],
  );

  static Widget buildCustomerAddress(Customer customer, InvoiceLabels labels) =>
      Column(
        crossAxisAlignment: labels.isRtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(customer.name, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(customer.address),
        ],
      );

  static Widget buildInvoiceInfo(InvoiceInfo info, InvoiceLabels labels) {
    final titles = <String>[
      labels.invoiceNumber,
      labels.invoiceDate,
      labels.transactionDate,
    ];
    final data = <String>[
      info.number,
      Utils.formatDate(info.date),
      Utils.formatDate(info.date),
    ];

    return Column(
      crossAxisAlignment: labels.isRtl
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: List.generate(titles.length, (index) {
        final title = titles[index];
        final value = data[index];

        return buildText(
          title: title,
          value: value,
          width: 200,
          isRtl: labels.isRtl,
        );
      }),
    );
  }

  static Widget buildSupplierAddress(Supplier supplier, InvoiceLabels labels) =>
      Column(
        crossAxisAlignment: labels.isRtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 1 * PdfPageFormat.mm),
          Text(supplier.address),
        ],
      );

  static Widget buildTitle(Invoice invoice, InvoiceLabels labels) => Column(
    crossAxisAlignment: labels.isRtl
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        labels.invoiceTitle,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
      Text(invoice.info.description),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
    ],
  );

  static Widget buildInvoice(Invoice invoice, InvoiceLabels labels) {
    final headers = [
      labels.description,
      labels.date,
      labels.quantity,
      labels.unitPrice,
      labels.total,
    ];

    final data = invoice.items.map((item) {
      final total = item.unitPrice * item.quantity;

      return [
        item.description,
        Utils.formatDate(item.date),
        '${item.quantity}',
        '\$ ${item.unitPrice}',
        '\$ ${total.toStringAsFixed(2)}',
      ];
    }).toList();

    return Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: labels.isRtl
          ? {
              0: Alignment.centerRight,
              1: Alignment.centerLeft,
              2: Alignment.centerLeft,
              3: Alignment.centerLeft,
              4: Alignment.centerLeft,
            }
          : {
              0: Alignment.centerLeft,
              1: Alignment.centerRight,
              2: Alignment.centerRight,
              3: Alignment.centerRight,
              4: Alignment.centerRight,
            },
    );
  }

  static Widget buildTotal(Invoice invoice, InvoiceLabels labels) {
    final total = invoice.items
        .map((item) => item.unitPrice * item.quantity)
        .reduce((item1, item2) => item1 + item2);

    return Container(
      alignment: labels.isRtl ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: labels.isRtl
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                buildText(
                  title: labels.netTotal,
                  value: Utils.formatPrice(total),
                  unite: true,
                  isRtl: labels.isRtl,
                ),
                Divider(),
                buildText(
                  title: labels.totalAmountDue,
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  value: Utils.formatPrice(total),
                  unite: true,
                  isRtl: labels.isRtl,
                ),
                SizedBox(height: 2 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
                SizedBox(height: 0.5 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(Invoice invoice, InvoiceLabels labels) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Divider(),
      SizedBox(height: 2 * PdfPageFormat.mm),
      buildSimpleText(
        title: labels.address,
        value: invoice.supplier.address,
        isRtl: labels.isRtl,
      ),
      // PayPal section removed as requested
    ],
  );

  static buildSimpleText({
    required String title,
    required String value,
    bool isRtl = false,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: isRtl
          ? [
              Text(value),
              SizedBox(width: 2 * PdfPageFormat.mm),
              Text(title, style: style),
            ]
          : [
              Text(title, style: style),
              SizedBox(width: 2 * PdfPageFormat.mm),
              Text(value),
            ],
    );
  }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
    bool isRtl = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: isRtl
            ? [
                Text(value, style: unite ? style : null),
                Expanded(
                  child: Text(title, style: style, textAlign: TextAlign.right),
                ),
              ]
            : [
                Expanded(child: Text(title, style: style)),
                Text(value, style: unite ? style : null),
              ],
      ),
    );
  }
}
