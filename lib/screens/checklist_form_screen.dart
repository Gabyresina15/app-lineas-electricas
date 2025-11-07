import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

// --- 1. IMPORTAR LAS CONSTANTES ---
import '../utils/constants.dart';

class ChecklistFormScreen extends StatefulWidget {
  // ... (Constructor igual)
  final String lineaId;
  final String piqueteId;
  const ChecklistFormScreen({
    super.key,
    required this.lineaId,
    required this.piqueteId,
  });

  @override
  State<ChecklistFormScreen> createState() => _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends State<ChecklistFormScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // --- 2. ELIMINAR EL MAPA LOCAL DE CÓDIGOS ---
  // final Map<int, String> _availableCodes = { ... }; // (ELIMINADO)

  // ... (El resto de los estados y controladores siguen igual) ...
  String _selectedPhase = 'R';
  final _notasController = TextEditingController();
  final Set<int> _selectedCodesR = {};
  final Set<int> _selectedCodesS = {};
  final Set<int> _selectedCodesT = {};
  double _severidadR = 0.0;
  double _severidadS = 0.0;
  double _severidadT = 0.0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // ... (El build() y el formulario principal siguen igual) ...
    // ... (El SegmentedButton sigue igual) ...

    // (Solo necesitas asegurarte de que _buildFaseInput() usa K_AVAILABLE_CODES)

    // ... (El resto del build sigue igual) ...
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Reporte: ${widget.piqueteId}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Línea: ${widget.lineaId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha/Hora: (Se guardará la actual)',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),

            const Divider(height: 30, thickness: 1),

            Center(
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                segments: const [
                  ButtonSegment(value: 'R', label: Text('Fase R'), icon: Icon(Icons.bolt)),
                  ButtonSegment(value: 'S', label: Text('Fase S'), icon: Icon(Icons.bolt)),
                  ButtonSegment(value: 'T', label: Text('Fase T'), icon: Icon(Icons.bolt)),
                ],
                selected: {_selectedPhase},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPhase = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildFaseInput(),

            const Divider(height: 30, thickness: 1),

            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas Generales',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Las notas son obligatorias' : null,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Reporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _isLoading ? null : _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaseInput() {
    Set<int> currentSelectedCodes;
    double currentSeverity;
    ValueChanged<double> onSliderChanged;

    switch (_selectedPhase) {
      case 'S':
        currentSelectedCodes = _selectedCodesS;
        currentSeverity = _severidadS;
        onSliderChanged = (newValue) => setState(() => _severidadS = newValue);
        break;
      case 'T':
        currentSelectedCodes = _selectedCodesT;
        currentSeverity = _severidadT;
        onSliderChanged = (newValue) => setState(() => _severidadT = newValue);
        break;
      case 'R':
      default:
        currentSelectedCodes = _selectedCodesR;
        currentSeverity = _severidadR;
        onSliderChanged = (newValue) => setState(() => _severidadR = newValue);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Editando Fase: $_selectedPhase', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Text('Seleccione Códigos de Falla:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableCodes.entries.map((entry) {
            final int code = entry.key;
            final String description = entry.value;

            return FilterChip(
              label: Text('$code $description'),
              selected: currentSelectedCodes.contains(code),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    currentSelectedCodes.add(code);
                  } else {
                    currentSelectedCodes.remove(code);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text('Severidad: ${currentSeverity.toInt()}', style: const TextStyle(fontSize: 16)),
        Slider(
          value: currentSeverity,
          onChanged: onSliderChanged,
          min: 0,
          max: 5,
          divisions: 5,
          label: currentSeverity.toInt().toString(),
        ),
      ],
    );
  }

  // ... (El método _submitForm() sigue igual) ...
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final now = DateTime.now();
      Map<String, dynamic> parseFase(Set<int> codes, double severidad, String faseNombre) {
        return {
          'fase': faseNombre,
          'severidad_fase': severidad.toInt(),
          'codigos_encontrados': codes.toList(),
        };
      }
      final List<Map<String, dynamic>> reporteFases = [
        parseFase(_selectedCodesR, _severidadR, 'R'),
        parseFase(_selectedCodesS, _severidadS, 'S'),
        parseFase(_selectedCodesT, _severidadT, 'T'),
      ];
      final Map<String, dynamic> data = {
        'FechaHora': now,
        'asesor_id': 'RESG001',
        'lineaE_id': widget.lineaId,
        'piquete_id': widget.piqueteId,
        'notas': _notasController.text.trim(),
        'reporte_fases': reporteFases,
      };

      await _dbService.addChecklist(widget.lineaId, widget.piqueteId, data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Checklist guardado exitosamente!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
}