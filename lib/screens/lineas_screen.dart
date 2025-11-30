import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'piquetes_screen.dart';
import '../utils/constants.dart';

class LineasScreen extends StatefulWidget {
  const LineasScreen({super.key});

  @override
  State<LineasScreen> createState() => _LineasScreenState();
}

class _LineasScreenState extends State<LineasScreen> {
  final DatabaseService _dbService = DatabaseService();

  // --- ESTADO DE LOS FILTROS ---
  double? _selectedTension;
  String? _selectedMunicipio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas Eléctricas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BARRA DE FILTROS ---
          _buildFilterBar(),

          // --- LISTA DE LÍNEAS  ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.getLineasElectricas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar las líneas: ${snapshot.error}'));
                }

                final allLineas = snapshot.data ?? [];
                if (allLineas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hay líneas eléctricas. Presiona el "+" para agregar una.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                // --- LÓGICA DE FILTRADO  ---
                final filteredLineas = allLineas.where((linea) {
                  // Comprobar Tensión
                  final bool tensionMatch = _selectedTension == null ||
                      linea['Tension'] == _selectedTension;

                  // Comprobar Municipio
                  final municipiosList = (linea['Municipio'] as List<dynamic>?) ?? [];
                  final bool municipioMatch = _selectedMunicipio == null ||
                      municipiosList.contains(_selectedMunicipio);

                  return tensionMatch && municipioMatch;
                }).toList();

                if (filteredLineas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No se encontraron líneas que coincidan con los filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                // --- LISTVIEW USA LA LISTA FILTRADA ---
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredLineas.length,
                  itemBuilder: (context, index) {
                    final linea = filteredLineas[index];
                    final lineaId = linea['ID_legible'] ?? 'Sin ID';
                    final tension = linea['Tension']?.toString() ?? '?';
                    final municipiosList = (linea['Municipio'] as List<dynamic>?) ?? [];
                    final municipiosStr = municipiosList.join(' -> ');

                    return Card(
                      elevation: 3.0,
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: Text(tension, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(lineaId, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Tensión: $tension kV \nRecorrido: $municipiosStr'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PiquetesScreen(
                                lineaId: lineaId,
                                lineaNombre: lineaId,
                                municipios: municipiosList,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLineaDialog(context),
        tooltip: 'Agregar Línea',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[100],
      child: Row(
        children: [
          // --- FILTRO DE TENSIÓN ---
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                  value: _selectedTension,
                  hint: const Text('Tensión'),
                  isExpanded: true,
                  items: kAvailableTensions.map((tension) {
                    return DropdownMenuItem(
                      value: tension,
                      child: Text('$tension kV'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTension = newValue;
                    });
                  },
                  // Botón para limpiar el filtro de tensión
                  selectedItemBuilder: (context) {
                    return kAvailableTensions.map((tension) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$tension kV'),
                          if (_selectedTension == tension)
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.clear, size: 18, color: Colors.grey),
                              ),
                              onTap: () => setState(() => _selectedTension = null),
                            )
                        ],
                      );
                    }).toList();
                  }
              ),
            ),
          ),

          const SizedBox(width: 8),

          // --- FILTRO DE MUNICIPIO ---
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: _selectedMunicipio,
                  hint: const Text('Municipio'),
                  isExpanded: true,
                  items: kAvailableMunicipios.map((municipio) {
                    return DropdownMenuItem(
                      value: municipio,
                      child: Text(municipio, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedMunicipio = newValue;
                    });
                  },
                  // Botón para limpiar el filtro de municipio
                  selectedItemBuilder: (context) {
                    return kAvailableMunicipios.map((municipio) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(municipio, overflow: TextOverflow.ellipsis)),
                          if (_selectedMunicipio == municipio)
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.clear, size: 18, color: Colors.grey),
                              ),
                              onTap: () => setState(() => _selectedMunicipio = null),
                            )
                        ],
                      );
                    }).toList();
                  }
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- El formulario  ---
  void _showAddLineaDialog(BuildContext context) {
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Variables locales
    double? selectedTension;
    String? selectedMunicipioOrigen;
    String? selectedMunicipioDestino;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar Nueva Línea'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      TextFormField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID Legible (Ej. AA1234)'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El ID es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<double>(
                        value: selectedTension,
                        decoration: const InputDecoration(
                          labelText: 'Tensión (kV)',
                          border: OutlineInputBorder(),
                        ),
                        items: kAvailableTensions.map((tension) {
                          return DropdownMenuItem<double>(
                            value: tension,
                            child: Text(tension.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTension = value;
                          });
                        },
                        validator: (value) => (value == null) ? 'Seleccione una tensión' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMunicipioOrigen,
                        decoration: const InputDecoration(
                          labelText: 'Municipio Origen',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: kAvailableMunicipios.map((municipio) {
                          return DropdownMenuItem<String>(
                            value: municipio,
                            child: Text(municipio),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMunicipioOrigen = value;
                          });
                        },
                        validator: (value) => (value == null) ? 'Seleccione un origen' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMunicipioDestino,
                        decoration: const InputDecoration(
                          labelText: 'Municipio Destino',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: kAvailableMunicipios.map((municipio) {
                          return DropdownMenuItem<String>(
                            value: municipio,
                            child: Text(municipio),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMunicipioDestino = value;
                          });
                        },
                        validator: (value) => (value == null) ? 'Seleccione un destino' : null,
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
                    final id = idController.text.trim();
                    final tension = selectedTension!;
                    final municipios = [selectedMunicipioOrigen!, selectedMunicipioDestino!];

                    try {
                      final Map<String, dynamic> data = {
                        'ID_legible': id,
                        'Tension': tension,
                        'Municipio': municipios,
                        'Tramos': municipios,
                      };

                      if (!context.mounted) return;
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await _dbService.addLineaElectrica(data);

                      if (!ctx.mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('✅ Línea $id agregada exitosamente!')),
                      );
                      Navigator.of(ctx).pop();

                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
