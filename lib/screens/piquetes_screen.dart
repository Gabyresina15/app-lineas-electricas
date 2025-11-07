import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'checklist_screen.dart';
import '../utils/constants.dart';
import 'package:geolocator/geolocator.dart';

class PiquetesScreen extends StatefulWidget {
  final String lineaId;
  final String lineaNombre;
  final List<dynamic> municipios;

  const PiquetesScreen({
    super.key,
    required this.lineaId,
    required this.lineaNombre,
    required this.municipios,
  });

  @override
  State<PiquetesScreen> createState() => _PiquetesScreenState();
}

class _PiquetesScreenState extends State<PiquetesScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool? _filtroTransformador;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Piquetes de: ${widget.lineaNombre}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.getPiquetes(widget.lineaId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar los piquetes: ${snapshot.error}'));
                }

                final allPiquetes = snapshot.data ?? [];

                final filteredPiquetes = allPiquetes.where((piquete) {
                  final tieneTransformador = piquete['tieneTransformador'] ?? false;
                  if (_filtroTransformador == null) return true;
                  return tieneTransformador == _filtroTransformador;
                }).toList();

                return Stack(
                  children: [
                    if (filteredPiquetes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay piquetes que coincidan con los filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredPiquetes.length,
                        itemBuilder: (context, index) {
                          final piquete = filteredPiquetes[index];
                          final piqueteId = piquete['ID_legible'] ?? 'Sin ID';
                          final numero = piquete['Numero']?.toString() ?? 'N/A';
                          final tipo = piquete['Tipo'] ?? 'Sin tipo';

                          final bool tieneTransformador = piquete['tieneTransformador'] ?? false;
                          String subtitulo = tipo;
                          if (tieneTransformador) {
                            subtitulo += '\nID Transformador: ${piquete['transformadorId'] ?? 'S/ID'}';
                          }

                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                child: Text(numero, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(piqueteId),
                              subtitle: Text(subtitulo),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tieneTransformador)
                                    Tooltip(
                                      message: 'Tiene Transformador',
                                      child: Icon(Icons.offline_bolt, color: Colors.amber[700]),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                              isThreeLine: tieneTransformador,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChecklistScreen(
                                      lineaId: widget.lineaId,
                                      piqueteId: piqueteId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                    Positioned(
                      bottom: 16.0,
                      right: 16.0,
                      child: FloatingActionButton(
                        onPressed: () => _showAddPiqueteDialog(context, allPiquetes),
                        tooltip: 'Agregar Piquete',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[100],
      child: SegmentedButton<bool?>(
        segments: const [
          ButtonSegment(value: null, label: Text('Todos')),
          ButtonSegment(value: true, label: Text('Con Transf.'), icon: Icon(Icons.offline_bolt)),
          ButtonSegment(value: false, label: Text('Sin Transf.')),
        ],
        selected: {_filtroTransformador},
        onSelectionChanged: (Set<bool?> newSelection) {
          setState(() {
            _filtroTransformador = newSelection.first;
          });
        },
      ),
    );
  }

  void _showAddPiqueteDialog(BuildContext context, List<Map<String, dynamic>> currentPiquetes) {

    final coordsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final idTransformadorController = TextEditingController();
    bool tieneTransformador = false;
    String? selectedTipo;
    bool _isGettingLocation = false;
    String prefix = 'PIQ';
    try {
      if (widget.municipios.length >= 2) {
        String m1 = widget.municipios[0].toString().toUpperCase();
        String m2 = widget.municipios[1].toString().toUpperCase();
        if (m1.length >= 3 && m2.length >= 3) {
          prefix = m1.substring(0, 3) + m2.substring(0, 3);
        }
      }
    } catch (e) {
      debugPrint("Error generando prefijo: $e");
    }
    int highestNum = 0;
    for (var piquete in currentPiquetes) {
      final id = piquete['ID_legible']?.toString() ?? '';
      if (id.startsWith(prefix)) {
        final numStr = id.substring(prefix.length);
        final num = int.tryParse(numStr) ?? 0;
        if (num > highestNum) {
          highestNum = num;
        }
      }
    }
    final newNum = highestNum + 1;
    final newIdNum = newNum.toString().padLeft(3, '0');
    final newGeneratedId = '$prefix$newIdNum';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Agregar Nuevo Piquete'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text('ID Generado: $newGeneratedId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Número de Piquete: $newNum', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedTipo,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Estructura',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: kAvailablePiqueteTypes.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(tipo),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTipo = value;
                            });
                          },
                          validator: (value) => (value == null) ? 'Seleccione un tipo' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: coordsController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Coordenadas',
                            hintText: 'Toca el botón para obtener GPS',
                            border: const OutlineInputBorder(),
                            suffixIcon: _isGettingLocation
                                ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator())
                                : IconButton(
                              icon: const Icon(Icons.location_searching),
                              onPressed: () async {

                                setDialogState(() { _isGettingLocation = true; });

                                try {
                                  LocationPermission permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission = await Geolocator.requestPermission();
                                    if (permission == LocationPermission.denied) {
                                      throw Exception('Permiso de ubicación denegado.');
                                    }
                                  }

                                  Position position = await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high
                                  );

                                  coordsController.text = '${position.latitude}, ${position.longitude}';

                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text('Error al obtener GPS: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                  coordsController.text = '';
                                } finally {
                                  setDialogState(() { _isGettingLocation = false; });
                                }
                              },
                            ),
                          ),
                        ),

                        const Divider(height: 20),

                        CheckboxListTile(
                          title: const Text('Tiene Transformador?', style: TextStyle(fontWeight: FontWeight.bold)),
                          value: tieneTransformador,
                          onChanged: (newValue) {
                            setDialogState(() {
                              tieneTransformador = newValue ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),

                        if (tieneTransformador)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextFormField(
                              controller: idTransformadorController,
                              decoration: const InputDecoration(
                                labelText: 'ID Transformador (Ej. SA1957)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (tieneTransformador && (value == null || value.trim().isEmpty)) {
                                  return 'El ID del transformador es obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Guardar'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final id = newGeneratedId;
                      final numero = newNum;
                      final tipo = selectedTipo!;

                      try {
                        final Map<String, dynamic> data = {
                          'ID_legible': id,
                          'Numero': numero,
                          'Tipo': tipo,
                          'Coordenadas': coordsController.text.trim(),
                          'tieneTransformador': tieneTransformador,
                          'transformadorId': tieneTransformador ? idTransformadorController.text.trim() : null,
                        };

                        if (!mounted || !ctx.mounted) return;
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await _dbService.addPiquete(widget.lineaId, data);

                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('✅ Piquete $id agregado exitosamente!')),
                        );
                        Navigator.of(ctx).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Error: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }
}