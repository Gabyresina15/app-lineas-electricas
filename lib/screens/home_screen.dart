import 'package:flutter/material.dart';
import 'lineas_screen.dart'; // Importa la pantalla de líneas

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Control'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navegar a la pantalla de Perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pantalla de Perfil (próximamente)')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Bienvenido, Gabriel', // TODO: Cargar nombre del asesor
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // --- Tarjeta de Navegación 1: Ver Líneas ---
            _MenuCard(
              context: context,
              icon: Icons.electric_bolt,
              title: 'Gestionar Líneas',
              subtitle: 'Ver, agregar o editar líneas y piquetes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LineasScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- Tarjeta de Navegación 2: Reporte Rápido ---
            _MenuCard(
              context: context,
              icon: Icons.camera_alt,
              title: 'Nuevo Reporte Rápido',
              subtitle: 'Escanear código de piquete o buscar',
              onTap: () {
                // TODO: Implementar flujo de reporte rápido
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flujo de Reporte Rápido (próximamente)')),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- Tarjeta de Navegación 3: Mapa ---
            _MenuCard(
              context: context,
              icon: Icons.map,
              title: 'Mapa de Piquetes',
              subtitle: 'Ver piquetes con fallas en el mapa',
              onTap: () {
                // TODO: Implementar Google Maps
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mapa (próximamente)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para las tarjetas del menú
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
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Icon(icon, size: 40, color: colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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