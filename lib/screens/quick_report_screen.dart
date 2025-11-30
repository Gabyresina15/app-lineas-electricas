import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'checklist_form_screen.dart';

class QuickReportScreen extends StatefulWidget {
  const QuickReportScreen({super.key});

  @override
  State<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends State<QuickReportScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _searchPiquete() async {
    final query = _searchController.text.trim().toUpperCase();

    if (query.isEmpty) {
      setState(() => _errorMessage = 'Ingrese un ID para buscar');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Llamar a la búsqueda global
    final result = await _dbService.findPiqueteGlobal(query);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChecklistFormScreen(
            lineaId: result['lineaId']!,
            piqueteId: result['piqueteId']!,
          ),
        ),
      );
    } else {
      // No encontrado
      setState(() {
        _errorMessage = 'No se encontró ningún piquete con el ID "$query". Verifique la escritura.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Rápido'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.search, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Buscar Piquete por ID',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingrese el código único del piquete (Ej: CAFTOL001) para iniciar un reporte inmediatamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Campo de Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ID del Piquete',
                hintText: 'Ej. CAFTOL001',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.qr_code),
                errorText: _errorMessage,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchPiquete(),
            ),

            const SizedBox(height: 24),

            // Botón Buscar
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchPiquete,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_forward),
                label: Text(_isLoading ? 'BUSCANDO...' : 'BUSCAR E INICIAR REPORTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}