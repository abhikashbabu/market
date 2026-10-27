// lib/screens/report_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import 'item_list_screen.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<ShoppingList>> _lists;
  final Color themeColor = Colors.green;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  void _loadLists() {
    setState(() {
      _lists = dbHelper.getAllLists(
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FB);
    final Color glassColor = isDark ? Colors.black : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.grey.shade900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGlassHeaderTitle(themeColor, glassColor, textColor),
            const SizedBox(height: 20),
            _buildDateFilterBar(glassColor, textColor, isDark),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<ShoppingList>>(
                future: _lists,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'इस तारीख के लिए कोई लिस्ट नहीं है।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      // --- FIX: यहाँ isDark पास किया गया है ---
                      return _buildReportListCard(
                          snapshot.data![index],
                          themeColor,
                          glassColor,
                          textColor,
                          isDark
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeaderTitle(Color themeColor, Color glassColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                        colors: [glassColor.withOpacity(0.45), glassColor.withOpacity(0.15)]
                    ),
                    border: Border.all(color: glassColor.withOpacity(0.40), width: 1.2),
                  ),
                  child: Icon(Icons.arrow_back, size: 22, color: textColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [glassColor.withOpacity(0.32), glassColor.withOpacity(0.18)]
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: glassColor.withOpacity(0.45), width: 1.4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Text("All Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 46),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(Color glassColor, Color textColor, bool isDark) {
    final DateFormat formatter = DateFormat('dd MMM, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDateChip(
              label: _startDate == null ? "Start Date" : formatter.format(_startDate!),
              onTap: () => _selectDate(true),
              isActive: _startDate != null,
              glassColor: glassColor,
              textColor: textColor,
              isDark: isDark
          ),
          _buildDateChip(
              label: _endDate == null ? "End Date" : formatter.format(_endDate!),
              onTap: () => _selectDate(false),
              isActive: _endDate != null,
              glassColor: glassColor,
              textColor: textColor,
              isDark: isDark
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _loadLists();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required Color glassColor,
    required Color textColor,
    required bool isDark
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isActive
                  ? themeColor.withOpacity(0.2)
                  : glassColor.withOpacity(isDark ? 0.2 : 0.3),
              border: Border.all(color: isActive ? themeColor : glassColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: isActive ? (isDark ? Colors.greenAccent : ColorDarken(themeColor).darken(0.2)) : textColor
                ),
                const SizedBox(width: 8),
                Text(
                    label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isActive ? (isDark ? Colors.greenAccent : ColorDarken(themeColor).darken(0.2)) : textColor
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
      _loadLists();
    }
  }

  Future<Uint8List> _generatePdfBill(ShoppingList list, List<ShoppingItem> items) async {
    final doc = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSansDevanagari-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final hindiTheme = pw.ThemeData.withFont(base: ttf, bold: ttf);

    double totalEstimatedPrice = 0.0;
    double totalMarketPrice = 0.0;
    for (var item in items) {
      totalEstimatedPrice += item.estimatedPrice;
      totalMarketPrice += item.marketPrice;
    }
    double totalDifference = totalMarketPrice - totalEstimatedPrice;

    doc.addPage(
      pw.Page(
        theme: hindiTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text("रसीद (RECEIPT)", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.SizedBox(height: 8),
                    pw.Text("शॉपिंग लिस्ट: ${list.name}", style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text("तारीख: ${DateFormat('dd-MM-yyyy HH:mm').format(list.createdAt ?? DateTime.now())}", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerRight,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                headers: ['आइटम', 'अनुमानित कीमत', 'बाज़ार कीमत', 'अंतर'],
                data: [
                  for (var item in items)
                    [
                      pw.Container(alignment: pw.Alignment.centerLeft, child: pw.Text(item.itemName)),
                      "Rs ${item.estimatedPrice.toStringAsFixed(0)}",
                      "Rs ${item.marketPrice.toStringAsFixed(0)}",
                      pw.Text(
                        "Rs ${(item.marketPrice - item.estimatedPrice).toStringAsFixed(0)}",
                        style: pw.TextStyle(color: (item.marketPrice - item.estimatedPrice) > 0 ? PdfColors.red : PdfColors.green),
                      ),
                    ],
                ],
              ),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              _buildPdfTotalRow("कुल अनुमानित:", totalEstimatedPrice, PdfColors.blue800),
              _buildPdfTotalRow("कुल बाज़ार भाव:", totalMarketPrice, PdfColors.green800),
              pw.Divider(color: PdfColors.grey400, height: 10),
              _buildPdfTotalRow("कुल अंतर:", totalDifference, totalDifference > 0 ? PdfColors.red800 : PdfColors.green800, isBold: true),
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text("*** धन्यवाद ***", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  pw.Widget _buildPdfTotalRow(String label, double amount, PdfColor color, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 12, color: isBold ? color : PdfColors.black)),
          pw.Text("Rs ${amount.toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: isBold ? 14 : 12, color: color)),
        ],
      ),
    );
  }

  void _showPrintReportDialog(ShoppingList list) async {
    List<ShoppingItem> items = await dbHelper.getItemsForList(list.id!);
    double totalEstimatedPrice = 0.0;
    double totalMarketPrice = 0.0;
    for (var item in items) {
      totalEstimatedPrice += item.estimatedPrice;
      totalMarketPrice += item.marketPrice;
    }
    double totalDifference = totalMarketPrice - totalEstimatedPrice;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // --- DIALOG COLORS FIXED ---
    final Color dialogBg = Colors.white; // डायलॉग हमेशा वाइट चाहिए (जैसा आपने माँगा था)
    final Color textColor = Colors.black87; // टेक्स्ट हमेशा ब्लैक
    // --------------------------

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: BorderSide(color: Colors.grey.shade300, width: 2)),
          insetPadding: const EdgeInsets.all(12),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Text("RECEIPT", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorDarken(themeColor).darken(0.3))),
                const SizedBox(height: 8),
                Text("Shopping List: ${list.name}", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text("Date: ${DateFormat('dd-MM-yyyy HH:mm').format(list.createdAt ?? DateTime.now())}", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          content: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800))),
                      Expanded(flex: 2, child: Text("EST. PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800))),
                      Expanded(flex: 2, child: Text("MKT. PRICE", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800))),
                      Expanded(flex: 2, child: Text("DIFF.", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800))),
                    ],
                  ),
                ),
                const Divider(),
                ...items.map((item) {
                  double itemDifference = item.marketPrice - item.estimatedPrice;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(item.itemName, style: TextStyle(color: textColor))),
                        Expanded(flex: 2, child: Text("₹${item.estimatedPrice.toStringAsFixed(0)}", textAlign: TextAlign.right, style: TextStyle(color: textColor))),
                        Expanded(flex: 2, child: Text("₹${item.marketPrice.toStringAsFixed(0)}", textAlign: TextAlign.right, style: TextStyle(color: textColor))),
                        Expanded(flex: 2, child: Text("₹${itemDifference.toStringAsFixed(0)}", textAlign: TextAlign.right, style: TextStyle(color: itemDifference > 0 ? Colors.redAccent : Colors.green))),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(),
                const SizedBox(height: 10),
                _buildTotalRow("TOTAL ESTIMATED:", totalEstimatedPrice, Colors.blue.shade800),
                const SizedBox(height: 5),
                _buildTotalRow("TOTAL MARKET:", totalMarketPrice, Colors.green.shade800),
                const Divider(),
                _buildTotalRow("TOTAL DIFFERENCE:", totalDifference, totalDifference > 0 ? Colors.red.shade800 : Colors.green.shade800, isBold: true),
                const SizedBox(height: 10),
                Text("**************** THANK YOU ****************", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("CLOSE", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF बना रहा है...")));
                final Uint8List pdfData = await _generatePdfBill(list, items);
                await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
              },
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
              child: const Text("PRINT"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14, color: isBold ? color : Colors.grey.shade800)),
        Text("₹${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14, color: isBold ? color : Colors.black87)),
      ],
    );
  }

  // --- 5. (FIXED) रिपोर्ट लिस्ट कार्ड (Missing isDark param fixed) ---
  Widget _buildReportListCard(ShoppingList list, Color themeColor, Color glassColor, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                  colors: [glassColor.withOpacity(0.35), glassColor.withOpacity(0.15)]
              ),
              border: Border.all(color: glassColor.withOpacity(0.50)),
              boxShadow: [BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.75)])),
                  child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
                      if (list.createdAt != null)
                        Text(DateFormat('MMM dd, yyyy').format(list.createdAt!), style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6))),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.print_outlined, color: isDark ? Colors.white70 : ColorDarken(themeColor).darken(0.2)),
                  onPressed: () => _showPrintReportDialog(list),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: textColor.withOpacity(0.6), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}