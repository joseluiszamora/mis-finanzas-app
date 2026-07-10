import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/movimiento.dart';
import '../providers/movimientos_provider.dart';
import 'agregar_movimiento_screen.dart';
import 'editar_movimiento_screen.dart';
import 'gestion_catalogos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _categoriaFiltroId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovimientosProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovimientosProvider>(
      builder: (context, provider, child) {
        final categoriaFiltroId = _validCategoriaFiltroId(provider.categorias);
        final movimientosFiltrados = _filterMovimientos(
          provider.movimientos,
          categoriaFiltroId,
        );

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              'Mis Finanzas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Administrar categorías y grupos',
                icon: const Icon(Icons.tune),
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
                tooltip: 'Recargar base local',
                icon: const Icon(Icons.refresh),
                onPressed: provider.recargarDesdeBase,
              ),
            ],
          ),
          body: _buildBody(provider, movimientosFiltrados, categoriaFiltroId),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgregarMovimientoScreen(),
                ),
              );

              if (result == true && context.mounted) {
                await context.read<MovimientosProvider>().recargarDesdeBase();
              }
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    MovimientosProvider provider,
    List<Movimiento> movimientosFiltrados,
    String? categoriaFiltroId,
  ) {
    if (!provider.isInitialized && provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando base local...'),
          ],
        ),
      );
    }

    if (!provider.isInitialized && provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'No se pudo iniciar la app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: provider.init,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.recargarDesdeBase,
      child: Column(
        children: [
          _buildSyncBanner(provider),
          _buildResumenCard(provider),
          _buildFiltroCategoria(provider.categorias, categoriaFiltroId),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MaterialBanner(
                content: Text(provider.error!),
                actions: [
                  TextButton(
                    onPressed: () {
                      provider.recargarDesdeBase();
                    },
                    child: const Text('Recargar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                movimientosFiltrados.isEmpty
                    ? _buildEmptyState(provider.movimientos.isEmpty)
                    : _buildMovimientosList(movimientosFiltrados),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(MovimientosProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            provider.isRemoteSyncEnabled
                ? Colors.blue.shade50
                : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              provider.isRemoteSyncEnabled
                  ? Colors.blue.shade200
                  : Colors.amber.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.isRemoteSyncEnabled
                ? Icons.cloud_queue
                : Icons.phone_iphone,
            color:
                provider.isRemoteSyncEnabled
                    ? Colors.blue.shade700
                    : Colors.amber.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.isRemoteSyncEnabled
                  ? 'Sync remoto preparado. La autenticación aún no está activa.'
                  : 'Modo local activo. Todo se guarda en SQLite del dispositivo.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(MovimientosProvider provider) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                Colors.green.shade100,
              ),
              _buildResumenItem(
                'Egresos',
                currencyFormat.format(provider.totalEgresos),
                Icons.arrow_downward,
                Colors.red.shade100,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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

  Widget _buildFiltroCategoria(
    List<Categoria> categorias,
    String? categoriaFiltroId,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Filtrar por:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String?>(
              value: categoriaFiltroId,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('Todas las categorías'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las categorías'),
                ),
                ...categorias.map(
                  (categoria) => DropdownMenuItem<String?>(
                    value: categoria.id,
                    child: Text(categoria.nombre),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _categoriaFiltroId = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noHayMovimientos) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noHayMovimientos
                ? Icons.account_balance_wallet_outlined
                : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            noHayMovimientos
                ? 'No hay movimientos registrados'
                : 'No hay movimientos para este filtro',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noHayMovimientos
                ? 'Agrega tu primer movimiento'
                : 'Prueba con otra categoría',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientosList(List<Movimiento> movimientos) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final movimiento = movimientos[index];
        return _buildMovimientoCard(movimiento);
      },
    );
  }

  Widget _buildMovimientoCard(Movimiento movimiento) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Dismissible(
      key: Key(movimiento.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        label: 'Editar',
        padding: const EdgeInsets.only(left: 20),
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        label: 'Eliminar',
        padding: const EdgeInsets.only(right: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _editarMovimiento(movimiento);
          return false;
        }
        return _confirmarEliminar(movimiento);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarDetalles(movimiento),
          onLongPress: () => _editarMovimiento(movimiento),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        movimiento.isIngreso
                            ? Colors.green[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    movimiento.isIngreso
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: movimiento.isIngreso ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label:
                                movimiento.categoriaNombre ?? 'Sin categoría',
                          ),
                          _InfoChip(label: movimiento.fecha),
                          if ((movimiento.grupoNombre ?? '').isNotEmpty)
                            _InfoChip(label: movimiento.grupoNombre!),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(movimiento.monto),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            movimiento.isIngreso
                                ? Colors.green[700]
                                : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movimiento.syncStatus.label,
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

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    required EdgeInsets padding,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMovimiento(Movimiento movimiento) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarMovimientoScreen(movimiento: movimiento),
      ),
    );

    if (result == true && mounted) {
      await context.read<MovimientosProvider>().recargarDesdeBase();
    }
  }

  Future<bool> _confirmarEliminar(Movimiento movimiento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    if (!mounted) {
      return false;
    }

    final provider = context.read<MovimientosProvider>();
    final success = await provider.eliminarMovimiento(movimiento.id);

    if (!mounted) {
      return success;
    }

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

    return success;
  }

  void _mostrarDetalles(Movimiento movimiento) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: '\$',
      decimalDigits: 2,
    );

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              _buildDetalleRow('Tipo', movimiento.tipo.label),
              _buildDetalleRow(
                'Categoría',
                movimiento.categoriaNombre ?? 'Sin categoría',
              ),
              _buildDetalleRow('Fecha', movimiento.fecha),
              _buildDetalleRow('Mes', movimiento.mes),
              _buildDetalleRow('Grupo', movimiento.grupoNombre ?? 'Sin grupo'),
              _buildDetalleRow('Sync', movimiento.syncStatus.label),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  List<Movimiento> _filterMovimientos(
    List<Movimiento> movimientos,
    String? categoriaId,
  ) {
    if (categoriaId == null) {
      return movimientos;
    }
    return movimientos
        .where((movimiento) => movimiento.categoriaId == categoriaId)
        .toList();
  }

  String? _validCategoriaFiltroId(List<Categoria> categorias) {
    final current = _categoriaFiltroId;
    if (current == null) {
      return null;
    }

    return categorias.any((categoria) => categoria.id == current)
        ? current
        : null;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
