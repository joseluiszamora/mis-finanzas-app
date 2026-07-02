import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/grupo.dart';
import '../models/movimiento.dart';
import '../models/tipo_movimiento.dart';
import '../providers/movimientos_provider.dart';
import '../utils/money_utils.dart';
import 'gestion_catalogos_screen.dart';

class EditarMovimientoScreen extends StatefulWidget {
  const EditarMovimientoScreen({super.key, required this.movimiento});

  final Movimiento movimiento;

  @override
  State<EditarMovimientoScreen> createState() => _EditarMovimientoScreenState();
}

class _EditarMovimientoScreenState extends State<EditarMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _conceptoController;
  late final TextEditingController _montoController;

  late DateTime _selectedDate;
  late TipoMovimiento _tipoSeleccionado;
  String? _categoriaSeleccionadaId;
  String? _grupoSeleccionadoId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _conceptoController = TextEditingController(
      text: widget.movimiento.concepto,
    );
    _montoController = TextEditingController(
      text: widget.movimiento.monto.toStringAsFixed(2),
    );
    _selectedDate = widget.movimiento.occurredAt;
    _tipoSeleccionado = widget.movimiento.tipo;
    _categoriaSeleccionadaId = widget.movimiento.categoriaId;
    _grupoSeleccionadoId = widget.movimiento.grupoId;
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovimientosProvider>(
      builder: (context, provider, child) {
        final categorias = provider.categorias;
        final grupos = provider.grupos;

        if (!categorias.any((item) => item.id == _categoriaSeleccionadaId)) {
          _categoriaSeleccionadaId =
              categorias.isNotEmpty ? categorias.first.id : null;
        }
        if (!grupos.any((item) => item.id == _grupoSeleccionadoId)) {
          _grupoSeleccionadoId = null;
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              'Editar Movimiento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Administrar categorías y grupos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionCatalogosScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed:
                    _isSaving ? null : () => _confirmarEliminar(provider),
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
                  _buildTipoCard(),
                  const SizedBox(height: 16),
                  _buildConceptoCard(),
                  const SizedBox(height: 16),
                  _buildMontoCard(),
                  const SizedBox(height: 16),
                  _buildCategoriaCard(provider),
                  const SizedBox(height: 16),
                  _buildFechaCard(),
                  const SizedBox(height: 16),
                  _buildGrupoCard(grupos),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        _isSaving ? null : () => _guardarCambios(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSaving
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    TipoMovimiento.ingreso,
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTipoButton(
                    TipoMovimiento.egreso,
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un concepto';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildMontoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto',
            hintText: '0.00',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un monto';
            }
            try {
              final cents = parseAmountToCents(value);
              if (cents <= 0) {
                return 'Ingresa un monto mayor a cero';
              }
            } catch (_) {
              return 'Ingresa un monto válido';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCategoriaCard(MovimientosProvider provider) {
    final categorias = provider.categorias;
    if (categorias.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No hay categorías disponibles',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una categoría para poder volver a guardar este movimiento.',
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionCatalogosScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Administrar categorías'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          key: ValueKey('categoria-${_categoriaSeleccionadaId ?? 'none'}'),
          initialValue: _categoriaSeleccionadaId,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items:
              categorias
                  .map(
                    (categoria) => DropdownMenuItem<String>(
                      value: categoria.id,
                      child: Text(categoria.nombre),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _categoriaSeleccionadaId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Selecciona una categoría';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildFechaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    );
  }

  Widget _buildGrupoCard(List<Grupo> grupos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String?>(
          key: ValueKey('grupo-${_grupoSeleccionadoId ?? 'none'}'),
          initialValue: _grupoSeleccionadoId,
          decoration: const InputDecoration(
            labelText: 'Grupo (opcional)',
            hintText: 'Selecciona un grupo',
            prefixIcon: Icon(Icons.group),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sin grupo'),
            ),
            ...grupos.map(
              (grupo) => DropdownMenuItem<String?>(
                value: grupo.id,
                child: Text(grupo.nombre),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _grupoSeleccionadoId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTipoButton(TipoMovimiento tipo, IconData icon, Color color) {
    final isSelected = _tipoSeleccionado == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoSeleccionado = tipo;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
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
              tipo.label,
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
    final picked = await showDatePicker(
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

  Future<void> _guardarCambios(MovimientosProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await provider.editarMovimiento(
      id: widget.movimiento.id,
      tipo: _tipoSeleccionado,
      categoriaId: _categoriaSeleccionadaId!,
      grupoId: _grupoSeleccionadoId,
      concepto: _conceptoController.text.trim(),
      amountCents: parseAmountToCents(_montoController.text),
      occurredAt: _selectedDate,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Movimiento actualizado exitosamente'
              : (provider.error ?? 'Error al actualizar el movimiento'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmarEliminar(MovimientosProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await provider.eliminarMovimiento(widget.movimiento.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Movimiento eliminado exitosamente'
              : (provider.error ?? 'Error al eliminar el movimiento'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }
}
