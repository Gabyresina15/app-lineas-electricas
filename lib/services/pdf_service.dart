import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class PdfService {

  Future<Uint8List> generatePdfBytes(PdfPageFormat format, Map<String, dynamic> data) async {
    final doc = pw.Document();

    // Preparar Datos
    final fecha = (data['FechaHora'] as Timestamp?)?.toDate() ?? DateTime.now();
    final fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    final piqueteId = data['piquete_id'] ?? 'N/A';
    final lineaId = data['lineaE_id'] ?? 'N/A';
    final asesor = data['asesor_id'] ?? 'N/A';
    final notas = data['notas'] ?? 'Sin notas adicionales.';
    final fases = (data['reporte_fases'] as List<dynamic>?) ?? [];

    // Construir el PDF
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ENCABEZADO
            pw.Header(
                level: 0,
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Reporte de Inspección', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Líneas Eléctricas DL', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]
                )
            ),
            pw.SizedBox(height: 20),

            // INFORMACIÓN GENERAL
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                ['Campo', 'Detalle'],
                ['ID Piquete', piqueteId],
                ['Línea', lineaId],
                ['Fecha y Hora', fechaStr],
                ['Inspector', asesor],
              ],
            ),
            pw.SizedBox(height: 20),

            // DETALLE DE FASES
            pw.Text('Detalle de Inspección por Fase', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),

            ...fases.map((fase) {
              final f = fase as Map<String, dynamic>;
              final nombre = f['fase'] ?? '?';
              final severidad = f['severidad_fase'] ?? 0;
              final codigos = (f['codigos_encontrados'] as List<dynamic>?) ?? [];

              return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 5),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
                  ),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Fase $nombre', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                              pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: pw.BoxDecoration(
                                      color: severidad > 0 ? PdfColors.orange100 : PdfColors.green100,
                                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))
                                  ),
                                  child: pw.Text('Severidad: $severidad/5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
                              ),
                            ]
                        ),
                        pw.SizedBox(height: 5),
                        if (codigos.isEmpty)
                          pw.Text('Sin novedades reportadas.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
                        else
                          ...codigos.map((c) {
                            final desc = availableCodes[c] ?? '(Código desconocido)';
                            return pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 10, top: 2),
                                child: pw.Bullet(text: '$c $desc', style: const pw.TextStyle(fontSize: 10))
                            );
                          }),
                      ]
                  )
              );
            }).toList(),

            pw.SizedBox(height: 20),

            // NOTAS
            pw.Text('Notas del Inspector', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Text(notas, style: const pw.TextStyle(fontSize: 12)),
            ),

            pw.SizedBox(height: 40),

            // PIE
            pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generado automáticamente por App Líneas Eléctricas', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8))
            ),
          ];
        },
      ),
    );
    return doc.save();
  }
}