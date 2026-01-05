import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/movimientos_provider.dart';
import '../models/movimiento.dart';
import 'agregar_movimiento_screen.dart';
import 'editar_movimiento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _categoriaFiltro; // null = Todas las categorías
  List<String> _categorias = [];
  bool _isLoadingCategorias = true;

  // Filtro por fecha
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    // Inicializar el provider al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovimientosProvider>(context, listen: false).init();
      _cargarCategorias();
    });
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoadingCategorias = true;
    });

    try {
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final categorias = await provider.obtenerCategorias();

      setState(() {
        _categorias = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      print('Error al cargar categorías: $e');
      setState(() {
        _isLoadingCategorias = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mis Finanzas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MovimientosProvider>(
                context,
                listen: false,
              ).cargarMovimientos();
            },
          ),
        ],
      ),
      body: Consumer<MovimientosProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized && provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Conectando con Google Sheets...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.init(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.cargarMovimientos(),
            child: Column(
              children: [
                // Tarjeta de resumen
                _buildResumenCard(provider),

                // Filtros
                _buildFiltros(),

                // Lista de movimientos
                Expanded(
                  child:
                      provider.movimientos.isEmpty
                          ? _buildEmptyState()
                          : _buildMovimientosList(provider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarMovimientoScreen(),
            ),
          );

          if (result == true) {
            // Recargar la lista si se agregó un movimiento
            if (context.mounted) {
              Provider.of<MovimientosProvider>(
                context,
                listen: false,
              ).cargarMovimientos();
            }
          }
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildResumenCard(MovimientosProvider provider) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResumenItem(
                'Ingresos',
                currencyFormat.format(provider.totalIngresos),
                Icons.arrow_upward,
                Colors.green[100]!,
              ),
              _buildResumenItem(
                'Egresos',
                currencyFormat.format(provider.totalEgresos),
                Icons.arrow_downward,
                Colors.red[100]!,
              ),
            ],
          ),
          const Divider(color: Colors.white54, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Balance: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currencyFormat.format(provider.balance),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    final dateFormat = DateFormat('dd/MM/yy');
    final hayFiltroFecha = _fechaInicio != null || _fechaFin != null;
    final hayFiltroCategoria = _categoriaFiltro != null;
    final hayAlgunFiltro = hayFiltroFecha || hayFiltroCategoria;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Fila de filtros
          Row(
            children: [
              // Filtro por categoría
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: Colors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _isLoadingCategorias
                                ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : DropdownButton<String?>(
                                  value: _categoriaFiltro,
                                  isExpanded: true,
                                  underline: Container(),
                                  isDense: true,
                                  hint: const Text(
                                    'Categoría',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Todas'),
                                    ),
                                    ..._categorias.map(
                                      (categoria) => DropdownMenuItem<String?>(
                                        value: categoria,
                                        child: Text(
                                          categoria,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _categoriaFiltro = value;
                                    });
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Filtro por fecha
              Expanded(
                child: InkWell(
                  onTap: _seleccionarRangoFechas,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          color: hayFiltroFecha ? Colors.teal : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hayFiltroFecha
                                ? '${_fechaInicio != null ? dateFormat.format(_fechaInicio!) : '...'} - ${_fechaFin != null ? dateFormat.format(_fechaFin!) : '...'}'
                                : 'Todas las fechas',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  hayFiltroFecha
                                      ? Colors.black87
                                      : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hayFiltroFecha)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _fechaInicio = null;
                                _fechaFin = null;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Botón limpiar todos los filtros
          if (hayAlgunFiltro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _categoriaFiltro = null;
                    _fechaInicio = null;
                    _fechaFin = null;
                  });
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text(
                  'Limpiar filtros',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange:
          _fechaInicio != null && _fechaFin != null
              ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
              : null,
      locale: const Locale('es', 'ES'),
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

    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay movimientos registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer movimiento',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientosList(MovimientosProvider provider) {
    // Filtrar movimientos según los filtros seleccionados
    var movimientosFiltrados = provider.movimientos.toList();

    // Filtro por categoría
    if (_categoriaFiltro != null) {
      movimientosFiltrados =
          movimientosFiltrados
              .where((m) => m.categoria == _categoriaFiltro)
              .toList();
    }

    // Filtro por fecha
    if (_fechaInicio != null || _fechaFin != null) {
      movimientosFiltrados =
          movimientosFiltrados.where((m) {
            try {
              final fechaMovimiento = DateFormat('dd/MM/yyyy').parse(m.fecha);

              if (_fechaInicio != null && _fechaFin != null) {
                return (fechaMovimiento.isAtSameMomentAs(_fechaInicio!) ||
                        fechaMovimiento.isAfter(_fechaInicio!)) &&
                    (fechaMovimiento.isAtSameMomentAs(_fechaFin!) ||
                        fechaMovimiento.isBefore(
                          _fechaFin!.add(const Duration(days: 1)),
                        ));
              } else if (_fechaInicio != null) {
                return fechaMovimiento.isAtSameMomentAs(_fechaInicio!) ||
                    fechaMovimiento.isAfter(_fechaInicio!);
              } else if (_fechaFin != null) {
                return fechaMovimiento.isAtSameMomentAs(_fechaFin!) ||
                    fechaMovimiento.isBefore(
                      _fechaFin!.add(const Duration(days: 1)),
                    );
              }
              return true;
            } catch (e) {
              return true; // Si no se puede parsear la fecha, incluir el movimiento
            }
          }).toList();
    }

    // Si no hay movimientos después del filtro
    if (movimientosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay movimientos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _buildMensajeFiltro(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _categoriaFiltro = null;
                  _fechaInicio = null;
                  _fechaFin = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: movimientosFiltrados.length,
      itemBuilder: (context, index) {
        final movimiento = movimientosFiltrados[index];
        // Obtener el índice real del movimiento en la lista completa
        final realIndex = provider.movimientos.indexOf(movimiento);
        return _buildMovimientoCard(movimiento, realIndex);
      },
    );
  }

  String _buildMensajeFiltro() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    List<String> filtros = [];

    if (_categoriaFiltro != null) {
      filtros.add('categoría "$_categoriaFiltro"');
    }

    if (_fechaInicio != null && _fechaFin != null) {
      filtros.add(
        'fechas ${dateFormat.format(_fechaInicio!)} - ${dateFormat.format(_fechaFin!)}',
      );
    } else if (_fechaInicio != null) {
      filtros.add('desde ${dateFormat.format(_fechaInicio!)}');
    } else if (_fechaFin != null) {
      filtros.add('hasta ${dateFormat.format(_fechaFin!)}');
    }

    return 'para ${filtros.join(' y ')}';
  }

  Widget _buildMovimientoCard(Movimiento movimiento, int index) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final isIngreso = movimiento.tipo.toLowerCase() == 'ingreso';

    return Dismissible(
      key: Key('${movimiento.fecha}_${movimiento.concepto}_$index'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Editar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Deslizar de izquierda a derecha: Editar
          await _editarMovimiento(movimiento, index);
          return false; // No eliminar el item
        } else {
          // Deslizar de derecha a izquierda: Eliminar
          return await _confirmarEliminar(movimiento, index);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Mostrar detalles completos
            _mostrarDetalles(movimiento);
          },
          onLongPress: () {
            // Long press para editar
            _editarMovimiento(movimiento, index);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícono según el tipo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isIngreso ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIngreso ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del movimiento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movimiento.concepto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              movimiento.categoria,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            movimiento.fecha,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Monto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(movimiento.monto),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isIngreso ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    if (movimiento.grupo.isNotEmpty)
                      Text(
                        movimiento.grupo,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editarMovimiento(Movimiento movimiento, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditarMovimientoScreen(movimiento: movimiento, index: index),
      ),
    );

    if (result == true) {
      // Recargar la lista si se editó o eliminó el movimiento
      if (mounted) {
        Provider.of<MovimientosProvider>(
          context,
          listen: false,
        ).cargarMovimientos();
      }
    }
  }

  Future<bool> _confirmarEliminar(Movimiento movimiento, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar "${movimiento.concepto}"?\n\nEsta acción no se puede deshacer.',
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
      final provider = Provider.of<MovimientosProvider>(context, listen: false);
      final success = await provider.eliminarMovimiento(index);

      if (mounted) {
        if (success) {
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
        } else {
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
      }

      return success;
    }

    return false;
  }

  void _mostrarDetalles(Movimiento movimiento) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalles del Movimiento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetalleRow('Concepto', movimiento.concepto),
                _buildDetalleRow(
                  'Monto',
                  currencyFormat.format(movimiento.monto),
                ),
                _buildDetalleRow('Tipo', movimiento.tipo),
                _buildDetalleRow('Categoría', movimiento.categoria),
                _buildDetalleRow('Fecha', movimiento.fecha),
                _buildDetalleRow('Mes', movimiento.mes),
                _buildDetalleRow('Grupo', movimiento.grupo),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
