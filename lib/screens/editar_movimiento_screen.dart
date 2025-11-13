import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/movimientos_provider.dart';
import '../models/movimiento.dart';

class EditarMovimientoScreen extends StatefulWidget {
  final Movimiento movimiento;
  final int index;

  const EditarMovimientoScreen({
    super.key,
    required this.movimiento,
    required this.index,
  });

  @override
  State<EditarMovimientoScreen> createState() => _EditarMovimientoScreenState();
}

class _EditarMovimientoScreenState extends State<EditarMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _conceptoController;
  late TextEditingController _montoController;

  late DateTime _selectedDate;
  late String _tipoSeleccionado;
  String? _categoriaSeleccionada;
  String? _grupoSeleccionado;
  bool _isLoading = false;
  bool _isLoadingConfig = true;

  // Listas dinámicas desde Google Sheets
  List<String> _categorias = [];
  List<String> _grupos = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con los valores del movimiento actual
    _conceptoController = TextEditingController(
      text: widget.movimiento.concepto,
    );
    _montoController = TextEditingController(
      text: widget.movimiento.monto.toString(),
    );
    _tipoSeleccionado = widget.movimiento.tipo;
    _categoriaSeleccionada = widget.movimiento.categoria;
    _grupoSeleccionado =
        widget.movimiento.grupo.isEmpty ? null : widget.movimiento.grupo;

    // Parsear la fecha
    try {
      _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.movimiento.fecha);
    } catch (e) {
      _selectedDate = DateTime.now();
    }

    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isLoadingConfig = true;
    });

    try {
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final categorias = await provider.obtenerCategorias();
      final grupos = await provider.obtenerGrupos();

      setState(() {
        _categorias = categorias;
        _grupos = grupos;
        _isLoadingConfig = false;

        // Validar que la categoría y grupo actuales existen en las listas
        if (_categoriaSeleccionada != null &&
            !_categorias.contains(_categoriaSeleccionada)) {
          _categoriaSeleccionada = null;
        }
        if (_grupoSeleccionado != null &&
            !_grupos.contains(_grupoSeleccionado)) {
          _grupoSeleccionado = null;
        }
      });
    } catch (e) {
      print('Error al cargar configuración: $e');
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Editar Movimiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmarEliminar,
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de tipo (Ingreso/Egreso)
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
                      Text(
                        'Tipo de movimiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTipoButton(
                              'Ingreso',
                              Icons.arrow_upward,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTipoButton(
                              'Egreso',
                              Icons.arrow_downward,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Concepto
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _conceptoController,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      hintText: 'Ej: Compra en supermercado',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un concepto';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Monto
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un monto';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingresa un monto válido';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Categoría
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _isLoadingConfig
                            ? []
                            : _categorias
                                .map(
                                  (categoria) => DropdownMenuItem(
                                    value: categoria,
                                    child: Text(categoria),
                                  ),
                                )
                                .toList(),
                    onChanged:
                        _isLoadingConfig
                            ? null
                            : (value) {
                              setState(() {
                                _categoriaSeleccionada = value;
                              });
                            },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fecha
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.teal),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Grupo
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _grupoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Grupo (opcional)',
                      hintText: 'Selecciona un grupo',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _isLoadingConfig
                            ? []
                            : _grupos
                                .map(
                                  (grupo) => DropdownMenuItem(
                                    value: grupo,
                                    child: Text(grupo),
                                  ),
                                )
                                .toList(),
                    onChanged:
                        _isLoadingConfig
                            ? null
                            : (value) {
                              setState(() {
                                _grupoSeleccionado = value;
                              });
                            },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de guardar cambios
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoButton(String tipo, IconData icon, Color color) {
    final isSelected = _tipoSeleccionado == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoSeleccionado = tipo;
          // La categoría ya no depende del tipo, así que no necesitamos resetearla
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              tipo,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear el movimiento editado
      final movimientoEditado = Movimiento(
        fecha: DateFormat('dd/MM/yyyy').format(_selectedDate),
        mes: DateFormat('MMMM', 'es').format(_selectedDate),
        tipo: _tipoSeleccionado,
        categoria: _categoriaSeleccionada!,
        concepto: _conceptoController.text,
        monto: double.parse(_montoController.text),
        grupo: _grupoSeleccionado ?? '',
      );

      // Guardar en Google Sheets
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final success = await provider.editarMovimiento(
        widget.index,
        movimientoEditado,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        if (!mounted) return;

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Movimiento actualizado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;

        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Error al actualizar el movimiento'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este movimiento? Esta acción no se puede deshacer.',
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

    if (confirmed == true) {
      await _eliminarMovimiento();
    }
  }

  Future<void> _eliminarMovimiento() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final success = await provider.eliminarMovimiento(widget.index);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        if (!mounted) return;

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Movimiento eliminado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;

        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Error al eliminar el movimiento'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
