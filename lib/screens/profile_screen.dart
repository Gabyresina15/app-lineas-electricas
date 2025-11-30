import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<QuerySnapshot>(
        // Busca al asesor por su email
        future: FirebaseFirestore.instance
            .collection('Asesores')
            .where('email', isEqualTo: user?.email)
            .get(),
        builder: (context, snapshot) {

          // Datos
          String nombre = 'Usuario';
          String apellido = '';
          String idLegible = 'Sin ID asignado';

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            nombre = data['Nombre'] ?? 'Usuario';
            apellido = data['Apellido'] ?? '';
            idLegible = data['ID_legible'] ?? '---';
          } else if (snapshot.hasError) {
            debugPrint("Error cargando perfil: ${snapshot.error}");
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar con la inicial
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : 'U',
                      style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre Completo
                  Text(
                    '$nombre $apellido',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Text(
                    user?.email ?? 'No autenticado',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Chip con el ID de Asesor
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'ID Asesor: $idLegible',
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ),

                  const Spacer(),

                  // Botón de Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('CERRAR SESIÓN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await AuthService().signOut();
                        // Verificamos si el widget sigue montado antes de navegar
                        if (context.mounted) {
                          // Vuelve al inicio (main.dart redirigirá al Login automáticamente)
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}