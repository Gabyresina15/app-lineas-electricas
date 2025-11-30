import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/database_service.dart';
import 'checklist_form_screen.dart';

// --- PANTALLA DE DETALLE ---
import 'checklist_detail_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final String lineaId;
  final String piqueteId;
  const ChecklistScreen({
    super.key,
    required this.lineaId,
    required this.piqueteId,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final DatabaseService _dbService = DatabaseService();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklists de: ${widget.piqueteId}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _dbService.getChecklists(widget.lineaId, widget.piqueteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar checklists: ${snapshot.error}'));
          }
          final checklists = snapshot.data ?? [];
          if (checklists.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay checklists para este piquete. Presiona el "+" para agregar uno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: checklists.length,
            itemBuilder: (context, index) {
              final checklist = checklists[index];

              final fechaHora = (checklist['FechaHora'] as Timestamp?)?.toDate();
              final fechaFormateada = fechaHora != null
                  ? _dateFormatter.format(fechaHora)
                  : 'Fecha inválida';

              final notas = checklist['notas'] ?? 'Sin notas';

              return Card(
                elevation: 3.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.checklist_rtl, color: Colors.white),
                  ),
                  title: Text('Inspección: $fechaFormateada', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notas, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios),

                  // --- ACTUALIZAR NAVEGACIÓN ---
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChecklistDetailScreen(
                          // Pasa el mapa de datos completo a la pantalla de detalle
                          checklistData: checklist,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar Checklist',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChecklistFormScreen(
                lineaId: widget.lineaId,
                piqueteId: widget.piqueteId,
              ),
            ),
          );
        },
      ),
    );
  }
}