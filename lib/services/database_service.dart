import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Conexion principal con firebase
class DatabaseService {
  // Instancia de Firestore para interactuar con la base de datos.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------------------------------------------
  // Lógica Auxiliar y Validaciones
  // ------------------------------------------------------------------------

  /// Función auxiliar que verifica si un documento existe y lo crea si es necesario.
  Future<void> _createOrSkipDoc(DocumentReference ref, Map<String, dynamic> data, String docName) async {
    final docSnapshot = await ref.get();

    if (!docSnapshot.exists) {
      await ref.set(data);
      debugPrint('✅ $docName ${ref.id} creado.');
    } else {
      debugPrint('⏭️ $docName ${ref.id} ya existe. Saltando creación.');
    }
  }

  /// Verifica si ya existe un registro de Checklist para un piquete en una fecha y hora específicas.
  Future<bool> checkIfChecklistExists(String lineaId, String piqueteId, DateTime fechaHora) async {
    final checklistCollectionRef = _db
        .collection('LineasElectricas').doc(lineaId)
        .collection('piquetes').doc(piqueteId)
        .collection('Checklist');

    // Convertimos el DateTime a Timestamp para la consulta de Firestore
    final Timestamp timestamp = Timestamp.fromDate(fechaHora);

    final existingDocs = await checklistCollectionRef
        .where('FechaHora', isEqualTo: timestamp)
        .limit(1)
        .get();

    return existingDocs.docs.isNotEmpty;
  }

  // ------------------------------------------------------------------------
  // Funciones CRUD de CREACIÓN MANUAL (Con validación)
  // ------------------------------------------------------------------------

  /// Agrega una nueva Línea Eléctrica. Valida que el ID no exista.
  Future<void> addLineaElectrica(Map<String, dynamic> data) async {
    if (!data.containsKey('ID_legible')) {
      throw Exception('El campo ID_legible es obligatorio para crear una Línea Eléctrica.');
    }
    final String lineaId = data['ID_legible'] as String;
    final lineaRef = _db.collection('LineasElectricas').doc(lineaId);

    await _createOrSkipDoc(lineaRef, data, 'Línea Eléctrica Manual');
  }

  /// Agrega un nuevo Piquete bajo una Línea Eléctrica. Valida que el ID no exista.
  Future<void> addPiquete(String lineaId, Map<String, dynamic> data) async {
    if (!data.containsKey('ID_legible')) {
      throw Exception('El campo ID_legible es obligatorio para crear un Piquete.');
    }
    final String piqueteId = data['ID_legible'] as String;
    final piqueteRef = _db.collection('LineasElectricas').doc(lineaId).collection('piquetes').doc(piqueteId);

    await _createOrSkipDoc(piqueteRef, data, 'Piquete Manual');
  }


  /// Añade un nuevo documento a la subcolección Checklist.
  /// Lanza una excepción si ya existe un registro con la misma FechaHora en ese piquete.
  Future<void> addChecklist(String lineaId, String piqueteId, Map<String, dynamic> data) async {
    if (!data.containsKey('FechaHora') || data['FechaHora'] is! DateTime) {
      throw Exception('El campo FechaHora es requerido y debe ser de tipo DateTime.');
    }
    final DateTime fechaHora = data['FechaHora'] as DateTime;

    // VALIDACIÓN CLAVE: Usar la función de verificación de duplicados
    if (await checkIfChecklistExists(lineaId, piqueteId, fechaHora)) {
      debugPrint('❌ ERROR: Ya existe un Checklist para el piquete $piqueteId con la Fecha/Hora: $fechaHora');
      throw Exception('Registro duplicado: Ya existe una inspección en esa fecha y hora para este piquete.');
    }

    // Si no hay duplicados, se agrega el nuevo Checklist
    try {
      final checklistCollectionRef = _db
          .collection('LineasElectricas').doc(lineaId)
          .collection('piquetes').doc(piqueteId)
          .collection('Checklist');

      await checklistCollectionRef.add(data);
      debugPrint('Documento Checklist agregado con éxito para $piqueteId.');
    } catch (e) {
      debugPrint('Error al agregar Checklist: $e');
      throw Exception('Fallo al guardar el registro de Checklist: $e');
    }
  }

  // ------------------------------------------------------------------------
  // Funciones CRUD de LECTURA (Mostrar)
  // ------------------------------------------------------------------------

  /// [MOSTRAR LÍNEAS ELÉCTRICAS]
  Stream<List<Map<String, dynamic>>> getLineasElectricas() {
    return _db.collection('LineasElectricas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  /// [MOSTRAR PIQUETES]
  Stream<List<Map<String, dynamic>>> getPiquetes(String lineaId) {
    return _db
        .collection('LineasElectricas').doc(lineaId)
        .collection('piquetes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  /// [MOSTRAR CHECKLISTS]
  Stream<List<Map<String, dynamic>>> getChecklists(String lineaId, String piqueteId) {
    return _db
        .collection('LineasElectricas').doc(lineaId)
        .collection('piquetes').doc(piqueteId)
        .collection('Checklist')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // ------------------------------------------------------------------------
  // Lógica de Seeding (Pruebas)
  // ------------------------------------------------------------------------

  /// Función para crear la estructura inicial de la base de datos.
  /// Utiliza _createOrSkipDoc para evitar duplicados en Asesores, Líneas y Piquetes.
  Future<void> seedDatabase() async {
    debugPrint('==================================================');
    debugPrint('INICIANDO SIEMBRA DE DATOS DE PRUEBA (con validación)');
    debugPrint('==================================================');

    // --- 1. Crear Asesor de Ejemplo Único ---
    const asesorId = 'RESG001';
    final asesorRef = _db.collection('Asesores').doc(asesorId);
    final asesorData = {
      'Activo': true,
      'Apellido': 'Resina',
      'Nombre': 'Gabriel',
      'ID_legible': asesorId,
    };
    await _createOrSkipDoc(asesorRef, asesorData, 'Asesor');

    // --- LÍNEA ELÉCTRICA A: AA1234 (Carril - Rosario de Lerma) ---

    const lineaAId = 'AA1234';
    final lineaARef = _db.collection('LineasElectricas').doc(lineaAId);
    final lineaAData = {
      'ID_legible': lineaAId,
      'Municipio': ['Carril', 'Rosario de lerma'],
      'Tension': 66,
      'Tramos': ['Carril', 'Rosario de lerma'],
    };
    await _createOrSkipDoc(lineaARef, lineaAData, 'Línea');

    // Crear Piquete A
    const piqueteAId = 'CARROS001';
    final piqueteARef = lineaARef.collection('piquetes').doc(piqueteAId);
    final piqueteAData = {
      'Coordenadas': ' { lat: -25.6037, lng: -65.3816 }',
      'ID_legible': piqueteAId,
      'Numero': 1,
      'Tipo': 'columna de hormigon',
    };
    await _createOrSkipDoc(piqueteARef, piqueteAData, 'Piquete');


    // Crear Checklist A
    final DateTime fechaA = DateTime(2025, 10, 15, 10, 0, 0);
    if (!(await checkIfChecklistExists(lineaAId, piqueteAId, fechaA))) {
      await piqueteARef.collection('Checklist').add({
        'FechaHora': fechaA,
        'asesor_id': asesorId,
        'lineaE_id': lineaAId,
        'notas': 'Checklist Línea A: Cambio aislador de apoyo y suspencion',
        'piquete_id': piqueteAId,
        'reporte_fases': [
          {'fase': 'R', 'severidad_fase': 1, 'codigos_encontrados': [521, 525]},
          {'fase': 'S', 'severidad_fase': 0, 'codigos_encontrados': []},
          {'fase': 'T', 'severidad_fase': 0, 'codigos_encontrados': []},
        ],
      });
      debugPrint('✅ Checklist A creado.');
    } else {
      debugPrint('⏭️ Checklist A ya existe. Saltando creación.');
    }

    // -------------------------------------------------------------------
    // --- LÍNEA ELÉCTRICA B: BB5678 (Cafayate - Animana) ---
    // -------------------------------------------------------------------
    const lineaBId = 'BB5678';
    final lineaBRef = _db.collection('LineasElectricas').doc(lineaBId);
    final lineaBData = {
      'ID_legible': lineaBId,
      'Municipio': ['Cafayate', 'Animana'],
      'Tension': 132,
      'Tramos': [' Cafayate ', ' Animana '],
    };

    await _createOrSkipDoc(lineaBRef, lineaBData, 'Línea');

    // Crear Piquete B
    const piqueteBId = 'CAFANI001';
    final piqueteBRef = lineaBRef.collection('piquetes').doc(piqueteBId);
    final piqueteBData = {
      'Coordenadas': ' { lat: -24.1837, lng: -65.3316 }',
      'ID_legible': piqueteBId,
      'Numero': 1,
      'Tipo': 'torre metálica',
    };
    await _createOrSkipDoc(piqueteBRef, piqueteBData, 'Piquete');

    // Crear Checklist B
    final DateTime fechaB = DateTime(2025, 10, 16, 14, 30, 0);
    if (!(await checkIfChecklistExists(lineaBId, piqueteBId, fechaB))) {
      await piqueteBRef.collection('Checklist').add({
        'FechaHora': fechaB,
        'asesor_id': asesorId,
        'lineaE_id': lineaBId,
        'notas': 'Checklist Línea B: Cambio de cruceta en fase T.',
        'piquete_id': piqueteBId,
        'reporte_fases': [
          {'fase': 'R', 'severidad_fase': 0, 'codigos_encontrados': []},
          {'fase': 'S', 'severidad_fase': 0, 'codigos_encontrados': []},
          {'fase': 'T', 'severidad_fase': 4, 'codigos_encontrados': [527]},
        ],
      });
      debugPrint('✅ Checklist B creado.');
    } else {
      debugPrint('⏭️ Checklist B ya existe.');
    }

    debugPrint('==================================================');
    debugPrint('✅ Estructura de prueba poblada exitosamente.');
    debugPrint('==================================================');
  }
}

// ------------------------------------------------------------------------
// WIDGET DE PRUEBA - Necesario para que main.dart lo use.
// ------------------------------------------------------------------------

class DatabaseSeederButton extends StatelessWidget {
  const DatabaseSeederButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Presiona para cargar datos de prueba en Firestore (Seeder):',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.build),
          label: const Text('Ejecutar Seeder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await DatabaseService().seedDatabase();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✅ Base de Datos de prueba poblada correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('❌ Error al poblar la DB: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}