import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ir_command.dart';

/// Service for exporting IR command mappings to PDF
class PDFExportService {
  static const String _title = 'SMASNUG Decoded System Layout Map';
  static const String _subtitle =
      'Address Context Matrix: 0x01 (NEC Standard Timing Framework)';

  /// Exports labeled commands to a PDF document and displays print dialog
  ///
  /// [commands] - List of labeled IR commands to export
  /// Throws [PdfExportException] if export fails
  static Future<void> exportToPDF(List<IRCommand> commands) async {
    if (commands.isEmpty) {
      throw PdfExportException(
        'No commands to export. Label some commands first.',
      );
    }

    try {
      final pdf = _generatePDF(commands);
      final Uint8List bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      throw PdfExportException('Failed to export PDF: $e', e);
    }
  }

  /// Generates PDF document from commands
  static pw.Document _generatePDF(List<IRCommand> commands) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            _title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _subtitle,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          _buildCommandsTable(commands),
        ],
      ),
    );

    return pdf;
  }

  /// Builds the commands table widget for PDF
  static pw.Widget _buildCommandsTable(List<IRCommand> commands) {
    return pw.TableHelper.fromTextArray(
      headers: ['Register Address (Hex)', 'Mapped System Function'],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
      cellStyle: const pw.TextStyle(fontSize: 11),
      data: commands
          .map((cmd) => [cmd.hex, cmd.controller.text.trim()])
          .toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }
}

/// Exception thrown when PDF export fails
class PdfExportException implements Exception {
  final String message;
  final dynamic originalError;

  PdfExportException(this.message, [this.originalError]);

  @override
  String toString() => 'PdfExportException: $message';
}
