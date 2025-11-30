import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- IDENTIDAD ---
  Future<String> _getAssesorLegibleId() async {
    final user = _auth.currentUser;
    if (user == null) return 'Desconocido';
    try {
      final querySnapshot = await _db.collection('Asesores').where('email', isEqualTo: user.email).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['ID_legible'] ?? user.email ?? 'Anonimo';
      }
    } catch (e) { debugPrint('Error: $e'); }
    return user.email ?? 'Anonimo';
  }

  Future<Map<String, dynamic>> _getUserAuditData() async {
    final user = _auth.currentUser;
    final asesorId = await _getAssesorLegibleId();
    return {
      'creado_por_uid': user?.uid ?? 'anonimo',
      'asesor_id': asesorId,
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
  }

  // --- BÚSQUEDA GLOBAL ---
  /// Busca un piquete por su ID legible en TODAS las líneas
  Future<Map<String, String>?> findPiqueteGlobal(String piqueteIdLegible) async {
    try {
      final querySnapshot = await _db
          .collectionGroup('piquetes')
          .where('ID_legible', isEqualTo: piqueteIdLegible)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final lineaRef = doc.reference.parent.parent;
        final lineaId = lineaRef?.id;

        if (lineaId != null) {
          return {
            'lineaId': lineaId,
            'piqueteId': piqueteIdLegible,
          };
        }
      }
    } catch (e) {
      debugPrint("Error en búsqueda global: $e");
    }
    return null; // No encontrado
  }

  // --- VALIDACIONES ---
  Future<void> _createOrSkipDoc(DocumentReference ref, Map<String, dynamic> data, String docName) async {
    final docSnapshot = await ref.get();
    if (!docSnapshot.exists) {
      await ref.set(data);
      debugPrint('✅ $docName ${ref.id} creado.');
    } else {
      debugPrint('⏭️ $docName ${ref.id} ya existe.');
    }
  }

  Future<bool> checkIfChecklistExists(String lineaId, String piqueteId, DateTime fechaHora) async {
    final existingDocs = await _db
        .collection('LineasElectricas').doc(lineaId).collection('piquetes').doc(piqueteId).collection('Checklist')
        .where('FechaHora', isEqualTo: Timestamp.fromDate(fechaHora)).limit(1).get();
    return existingDocs.docs.isNotEmpty;
  }

  // --- CREAR ---
  Future<void> addLineaElectrica(Map<String, dynamic> data) async {
    if (!data.containsKey('ID_legible')) throw Exception('Falta ID_legible');
    final audit = await _getUserAuditData();
    final String id = data['ID_legible'];
    await _createOrSkipDoc(_db.collection('LineasElectricas').doc(id), {...data, ...audit}, 'Línea');
  }

  Future<void> addPiquete(String lineaId, Map<String, dynamic> data) async {
    if (!data.containsKey('ID_legible')) throw Exception('Falta ID_legible');
    final audit = await _getUserAuditData();
    final String id = data['ID_legible'];
    await _createOrSkipDoc(
        _db.collection('LineasElectricas').doc(lineaId).collection('piquetes').doc(id),
        {...data, ...audit}, 'Piquete'
    );
  }

  Future<void> addChecklist(String lineaId, String piqueteId, Map<String, dynamic> data) async {
    if (!data.containsKey('FechaHora')) throw Exception('Falta FechaHora');
    if (await checkIfChecklistExists(lineaId, piqueteId, data['FechaHora'])) {
      throw Exception('Registro duplicado en esa fecha.');
    }
    final audit = await _getUserAuditData();
    await _db.collection('LineasElectricas').doc(lineaId).collection('piquetes').doc(piqueteId).collection('Checklist')
        .add({...data, ...audit});
  }

  // --- LEER ---
  Stream<List<Map<String, dynamic>>> getLineasElectricas() {
    return _db.collection('LineasElectricas').snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getPiquetes(String lineaId) {
    return _db.collection('LineasElectricas').doc(lineaId).collection('piquetes').snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getChecklists(String lineaId, String piqueteId) {
    return _db.collection('LineasElectricas').doc(lineaId).collection('piquetes').doc(piqueteId).collection('Checklist')
        .orderBy('FechaHora', descending: true).snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}