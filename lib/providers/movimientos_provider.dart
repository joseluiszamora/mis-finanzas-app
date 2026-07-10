import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/catalogos_repository.dart';
import '../data/repositories/movimientos_repository.dart';
import '../data/sync/sync_coordinator.dart';
import '../data/sync/sync_state.dart';
import '../models/categoria.dart';
import '../models/grupo.dart';
import '../models/movimiento.dart';
import '../models/resumen_financiero.dart';
import '../models/tipo_movimiento.dart';

class MovimientosProvider extends ChangeNotifier {
  MovimientosProvider({
    required MovimientosRepository movimientosRepository,
    required CatalogosRepository catalogosRepository,
    required SyncCoordinator syncCoordinator,
    Uuid? uuid,
  }) : _movimientosRepository = movimientosRepository,
       _catalogosRepository = catalogosRepository,
       _syncCoordinator = syncCoordinator,
       _uuid = uuid ?? const Uuid() {
    _syncCoordinator.addListener(notifyListeners);
  }

  final MovimientosRepository _movimientosRepository;
  final CatalogosRepository _catalogosRepository;
  final SyncCoordinator _syncCoordinator;
  final Uuid _uuid;

  List<Movimiento> _movimientos = const [];
  List<Categoria> _categorias = const [];
  List<Grupo> _grupos = const [];
  ResumenFinanciero _resumen = const ResumenFinanciero(
    totalIngresosCents: 0,
    totalEgresosCents: 0,
  );
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  List<Movimiento> get movimientos => _movimientos;
  List<Categoria> get categorias => _categorias;
  List<Grupo> get grupos => _grupos;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String get syncModeLabel => _syncCoordinator.syncModeLabel;
  bool get isRemoteSyncEnabled => _syncCoordinator.isRemoteSyncEnabled;
  SyncSnapshot get syncSnapshot => _syncCoordinator.snapshot;

  double get totalIngresos => _resumen.totalIngresos;
  double get totalEgresos => _resumen.totalEgresos;
  double get balance => _resumen.balance;

  Future<void> init() async {
    if (_isInitialized) {
      await recargarDesdeBase();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      await _recargarTodo();
      _isInitialized = true;
    } catch (e) {
      _error = 'Error al inicializar la base local: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recargarDesdeBase() async {
    _setLoading(true);
    _error = null;

    try {
      await _recargarTodo();
      await _syncCoordinator.attemptSync();
      await _recargarTodo();
    } catch (e) {
      _error = 'Error al recargar datos locales: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> agregarMovimiento({
    required TipoMovimiento tipo,
    required String categoriaId,
    required String? grupoId,
    required String concepto,
    required int amountCents,
    required DateTime occurredAt,
  }) async {
    return _runMutation(() async {
      await _movimientosRepository.crearMovimiento(
        MovimientoDraft(
          tipo: tipo,
          categoriaId: categoriaId,
          grupoId: grupoId,
          concepto: concepto,
          amountCents: amountCents,
          occurredAt: occurredAt,
        ),
      );
      await _recargarTodo();
    }, fallbackError: 'No se pudo guardar el movimiento.');
  }

  Future<bool> editarMovimiento({
    required String id,
    required TipoMovimiento tipo,
    required String categoriaId,
    required String? grupoId,
    required String concepto,
    required int amountCents,
    required DateTime occurredAt,
  }) async {
    return _runMutation(() async {
      await _movimientosRepository.actualizarMovimiento(
        id,
        MovimientoDraft(
          tipo: tipo,
          categoriaId: categoriaId,
          grupoId: grupoId,
          concepto: concepto,
          amountCents: amountCents,
          occurredAt: occurredAt,
        ),
      );
      await _recargarTodo();
    }, fallbackError: 'No se pudo actualizar el movimiento.');
  }

  Future<bool> eliminarMovimiento(String id) async {
    return _runMutation(() async {
      await _movimientosRepository.eliminarMovimiento(id);
      await _recargarTodo();
    }, fallbackError: 'No se pudo eliminar el movimiento.');
  }

  Future<bool> agregarCategoria(String nombre) async {
    return _runMutation(() async {
      await _catalogosRepository.crearCategoria(nombre);
      await _recargarCatalogos();
    }, fallbackError: 'No se pudo agregar la categoría.');
  }

  Future<bool> editarCategoria(String id, String nombre) async {
    return _runMutation(() async {
      await _catalogosRepository.actualizarCategoria(id, nombre);
      await _recargarTodo();
    }, fallbackError: 'No se pudo actualizar la categoría.');
  }

  Future<bool> eliminarCategoria(String id) async {
    return _runMutation(() async {
      await _catalogosRepository.eliminarCategoria(id);
      await _recargarTodo();
    }, fallbackError: 'No se pudo eliminar la categoría.');
  }

  Future<bool> agregarGrupo(String nombre) async {
    return _runMutation(() async {
      await _catalogosRepository.crearGrupo(nombre);
      await _recargarCatalogos();
    }, fallbackError: 'No se pudo agregar el grupo.');
  }

  Future<bool> editarGrupo(String id, String nombre) async {
    return _runMutation(() async {
      await _catalogosRepository.actualizarGrupo(id, nombre);
      await _recargarTodo();
    }, fallbackError: 'No se pudo actualizar el grupo.');
  }

  Future<bool> eliminarGrupo(String id) async {
    return _runMutation(() async {
      await _catalogosRepository.eliminarGrupo(id);
      await _recargarTodo();
    }, fallbackError: 'No se pudo eliminar el grupo.');
  }

  Categoria? buscarCategoriaPorId(String id) {
    for (final categoria in _categorias) {
      if (categoria.id == id) {
        return categoria;
      }
    }
    return null;
  }

  Grupo? buscarGrupoPorId(String id) {
    for (final grupo in _grupos) {
      if (grupo.id == id) {
        return grupo;
      }
    }
    return null;
  }

  String generarIdTemporal() => _uuid.v4();

  Future<void> sincronizarAhora() async {
    _setLoading(true);
    _error = null;

    try {
      await _syncCoordinator.synchronizeNow();
      await _recargarTodo();
    } catch (e) {
      _error = 'Error al sincronizar: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _recargarTodo() async {
    await Future.wait([_recargarMovimientos(), _recargarCatalogos()]);
    _resumen = await _movimientosRepository.obtenerResumen();
    notifyListeners();
  }

  Future<void> _recargarMovimientos() async {
    _movimientos = await _movimientosRepository.obtenerMovimientos();
  }

  Future<void> _recargarCatalogos() async {
    final categorias = await _catalogosRepository.obtenerCategorias();
    final grupos = await _catalogosRepository.obtenerGrupos();
    _categorias = categorias;
    _grupos = grupos;
  }

  Future<bool> _runMutation(
    Future<void> Function() action, {
    required String fallbackError,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await action();
      return true;
    } catch (e) {
      _error = e is StateError ? e.message : fallbackError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncCoordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
