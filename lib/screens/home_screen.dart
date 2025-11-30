import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lineas_screen.dart';
import 'profile_screen.dart';
import 'quick_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Control'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            tooltip: 'Mi Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Bienvenido,',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            // --- BUSCAR Y MOSTRAR NOMBRE DEL ASESOR ---
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Asesores')
                  .where('email', isEqualTo: user?.email)
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                String displayName = user?.email ?? 'Usuario';

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final nombre = data['Nombre'] ?? '';
                  final apellido = data['Apellido'] ?? '';
                  if (nombre.isNotEmpty || apellido.isNotEmpty) {
                    displayName = '$nombre $apellido'.trim();
                  }
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 30);
                }

                return Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- GESTIONAR LÍNEAS ---
            _MenuCard(
              context: context,
              icon: Icons.electric_bolt,
              title: 'Gestionar Líneas',
              subtitle: 'Ver, agregar o editar líneas y piquetes',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LineasScreen()));
              },
            ),

            const SizedBox(height: 16),

            // --- REPORTE RÁPIDO ---
            _MenuCard(
              context: context,
              icon: Icons.camera_alt,
              title: 'Nuevo Reporte Rápido',
              subtitle: 'Buscar código de piquete e iniciar',
              onTap: () {
                // Navega a la pantalla de búsqueda global
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuickReportScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- MAPA (PROXIMAMENTE ) ---
            _MenuCard(
              context: context,
              icon: Icons.map,
              title: 'Mapa de Piquetes',
              subtitle: 'Ver piquetes con fallas en el mapa',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget reutilizable para las tarjetas del menú
class _MenuCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.context,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}