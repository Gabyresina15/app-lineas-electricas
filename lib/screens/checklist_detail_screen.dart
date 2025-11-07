import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class ChecklistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> checklistData;

  const ChecklistDetailScreen({super.key, required this.checklistData});

  @override
  Widget build(BuildContext context) {
    final notas = checklistData['notas'] ?? 'Sin notas';
    final asesorId = checklistData['asesor_id'] ?? 'N/A';
    final fechaHora = (checklistData['FechaHora'] as Timestamp?)?.toDate();
    final fechaFormateada = fechaHora != null
        ? DateFormat('dd/MM/yyyy \'a las\' HH:mm \'hs\'').format(fechaHora)
        : 'Fecha inválida';
    final reporteFases = (checklistData['reporte_fases'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Reporte'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Tarjeta 1: Información General ---
          Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Generales',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(fechaFormateada),
                    subtitle: const Text('Fecha y Hora'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(asesorId),
                    subtitle: const Text('Asesor'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Notas:'),
                    subtitle: Text(notas),
                    isThreeLine: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- Tarjeta 2: Detalle de Fases ---
          Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalle de Fases',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary
                    ),
                  ),
                  const Divider(),
                  ...reporteFases.map((fase) {
                    final faseData = fase as Map<String, dynamic>;
                    return _buildPhaseDetail(
                      faseNombre: faseData['fase'] ?? 'N/A',
                      severidad: faseData['severidad_fase'] ?? 0,
                      codigos: (faseData['codigos_encontrados'] as List<dynamic>?) ?? [],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para mostrar el detalle de una fase
  Widget _buildPhaseDetail({required String faseNombre, required int severidad, required List<dynamic> codigos}) {

    // Busca las descripciones de los códigos
    final codigosString = codigos.isEmpty
        ? 'Sin códigos reportados.'
        : codigos.map((code) {
      // --- 2. USAR EL NUEVO NOMBRE 'availableCodes' ---
      final description = availableCodes[code] ?? '(Código desconocido)';
      return '• $code $description';
    }).join('\n'); // Un código por línea

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fase $faseNombre',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Severidad: $severidad / 5',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Códigos Reportados:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
            child: Text(
              codigosString,
              style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}