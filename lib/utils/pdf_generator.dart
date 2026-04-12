import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/worker_model.dart';
import '../models/lot_model.dart';
import '../utils/constants.dart';

/// Generates and exports PDF reports for the garments business.
///
/// Supports:
/// - Worker salary report
/// - Lot/stock balance report
/// - Production summary report
class PdfGenerator {
  // ─── Worker Salary Report ─────────────────────────────────
  /// Generates a PDF listing all workers with their salary details.
  static Future<void> generateWorkerReport(List<WorkerModel> workers) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader('Worker Salary Report', dateStr),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.indigo100),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(8),
            headers: [
              'Name',
              'Role',
              'Rate/Pc',
              'Total Pieces',
              'Salary (${AppConstants.currencySymbol})'
            ],
            data: workers
                .map((w) => [
                      w.name,
                      w.role,
                      '${AppConstants.currencySymbol}${w.ratePerPiece.toStringAsFixed(1)}',
                      w.totalPieces.toString(),
                      '${AppConstants.currencySymbol}${w.salary.toStringAsFixed(0)}',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total Salary: ${AppConstants.currencySymbol}${workers.fold<double>(0, (sum, w) => sum + w.salary).toStringAsFixed(0)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Worker_Report_$dateStr',
    );
  }

  // ─── Lot Balance Report ───────────────────────────────────
  /// Generates a PDF listing all lots with stock in/out/remaining.
  static Future<void> generateLotReport(List<LotModel> lots) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader('Lot Balance Report', dateStr),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.green100),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['Lot Name', 'Date', 'Pieces In', 'Pieces Out', 'Remaining'],
            data: lots
                .map((l) => [
                      l.lotName,
                      DateFormat('dd/MM/yyyy').format(l.date),
                      l.piecesIn.toString(),
                      l.piecesOut.toString(),
                      l.remaining.toString(),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total Stock Balance: ${lots.fold<int>(0, (sum, l) => sum + l.remaining)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Lot_Report_$dateStr',
    );
  }

  // ─── Production Summary Report ────────────────────────────
  /// Generates a PDF with production summary data.
  static Future<void> generateProductionReport({
    required Map<String, int> dailyData,
    required int monthlyTotal,
    required String monthName,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader('Production Summary Report', dateStr),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Text('Daily Production (Last 7 Days)',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.amber100),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(8),
            headers: ['Date', 'Pieces Produced'],
            data: dailyData.entries
                .map((e) => [e.key, e.value.toString()])
                .toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Monthly Total ($monthName): $monthlyTotal pieces',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Production_Report_$dateStr',
    );
  }

  // ─── Shared Header Widget ────────────────────────────────
  static pw.Widget _buildHeader(String title, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          AppConstants.appName,
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
        pw.Text('Generated on: $date',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey600)),
        pw.Divider(thickness: 2, color: PdfColors.indigo800),
      ],
    );
  }
}
