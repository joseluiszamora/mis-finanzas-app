import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movimientos_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  List<String> _worksheets = [];
  List<String> _worksheetsDisponibles = [];
  String _worksheetActiva = '';
  bool _isLoading = true;
  bool _isChanging = false;

  @override
  void initState() {
    super.initState();
    _cargarWorksheets();
  }

  Future<void> _cargarWorksheets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MovimientosProvider>(context, listen: false);

      // Cargar worksheets guardadas localmente
      final worksheets = await provider.obtenerWorksheetsGuardadas();

      // Cargar worksheets disponibles en Google Sheets
      final disponibles = await provider.obtenerTodasLasWorksheets();

      setState(() {
        _worksheets = worksheets;
        _worksheetsDisponibles = disponibles;
        _worksheetActiva = provider.currentWorksheet;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar worksheets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _agregarWorksheet() async {
    final controller = TextEditingController();

    final resultado = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Agregar Worksheet'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa el nombre exacto de la hoja en Google Sheets:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la hoja',
                    hintText: 'Ej: Enero2026',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.table_chart),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                if (_worksheetsDisponibles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Hojas disponibles en Google Sheets:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _worksheetsDisponibles
                            .where((w) => !_worksheets.contains(w))
                            .map(
                              (w) => ActionChip(
                                label: Text(
                                  w,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  controller.text = w;
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      // Verificar si ya existe localmente
      if (_worksheets.contains(resultado)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta hoja ya está en tu lista'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verificar si existe en Google Sheets
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final existe = await provider.verificarWorksheetExiste(resultado);

      if (!existe) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('La hoja "$resultado" no existe en Google Sheets'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Agregar a la lista local
      final agregado = await provider.agregarWorksheetLocal(resultado);

      if (agregado) {
        await _cargarWorksheets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hoja "$resultado" agregada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarWorksheet(String title) async {
    if (title == _worksheetActiva) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar la hoja activa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Worksheet'),
            content: Text(
              '¿Deseas eliminar "$title" de tu lista?\n\nEsto no eliminará la hoja de Google Sheets, solo la quitará de tu lista de hojas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final eliminado = await provider.eliminarWorksheetLocal(title);

      if (eliminado) {
        await _cargarWorksheets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hoja "$title" eliminada de la lista'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _cambiarWorksheetActiva(String title) async {
    if (title == _worksheetActiva) return;

    setState(() {
      _isChanging = true;
    });

    final provider = Provider.of<MovimientosProvider>(context, listen: false);
    final success = await provider.cambiarWorksheet(title);

    setState(() {
      _isChanging = false;
      if (success) {
        _worksheetActiva = title;
      }
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Cambiado a "$title"'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar a "$title"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _cargarWorksheets,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Sección de Worksheets
                    _buildSectionHeader(
                      'Hojas de Cálculo',
                      Icons.table_chart_outlined,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Info de la hoja activa
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hoja activa',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _worksheetActiva,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isChanging)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Lista de worksheets
                          if (_worksheets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No hay hojas configuradas',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._worksheets.map(
                              (worksheet) => _buildWorksheetTile(worksheet),
                            ),
                          // Botón agregar
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.teal,
                            ),
                            title: const Text(
                              'Agregar hoja',
                              style: TextStyle(color: Colors.teal),
                            ),
                            onTap: _agregarWorksheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección de información
                    _buildSectionHeader('Información', Icons.info_outline),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Hojas en Google Sheets',
                              '${_worksheetsDisponibles.length}',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Hojas configuradas',
                              '${_worksheets.length}',
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Tip: Puedes agregar múltiples hojas para manejar tus finanzas por mes (Enero2026, Febrero2026, etc.)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetTile(String worksheet) {
    final isActiva = worksheet == _worksheetActiva;

    return ListTile(
      leading: Icon(
        isActiva ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActiva ? Colors.teal : Colors.grey,
      ),
      title: Text(
        worksheet,
        style: TextStyle(
          fontWeight: isActiva ? FontWeight.bold : FontWeight.normal,
          color: isActiva ? Colors.teal : Colors.black87,
        ),
      ),
      trailing:
          isActiva
              ? const Chip(
                label: Text(
                  'Activa',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: Colors.teal,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
              : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _eliminarWorksheet(worksheet),
              ),
      onTap: _isChanging ? null : () => _cambiarWorksheetActiva(worksheet),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
