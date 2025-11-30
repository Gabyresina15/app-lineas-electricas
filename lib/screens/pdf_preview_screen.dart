import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> checklistData;

  const PdfPreviewScreen({super.key, required this.checklistData});

  @override
  Widget build(BuildContext context) {
    // Generar nombre de archivo
    final piqueteId = checklistData['piquete_id'] ?? 'Reporte';
    final fecha = (checklistData['FechaHora'] as Timestamp?)?.toDate() ?? DateTime.now();
    final fileName = 'Reporte_${piqueteId}_${DateFormat('yyyyMMdd').format(fecha)}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa de Comprobante'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfService().generatePdfBytes(format, checklistData),

        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canDebug: false,

        // Nombre del archivo al compartir
        pdfFileName: fileName,
      ),
    );
  }
}