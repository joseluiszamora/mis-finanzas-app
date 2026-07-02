import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/grupo.dart';
import '../providers/movimientos_provider.dart';

class GestionCatalogosScreen extends StatefulWidget {
  const GestionCatalogosScreen({super.key});

  @override
  State<GestionCatalogosScreen> createState() => _GestionCatalogosScreenState();
}

class _GestionCatalogosScreenState extends State<GestionCatalogosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovimientosProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorías y Grupos'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Categorías'), Tab(text: 'Grupos')],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _handleCreate(provider),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              _tabController.index == 0 ? 'Nueva categoría' : 'Nuevo grupo',
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _CatalogList<Categoria>(
                items: provider.categorias,
                emptyLabel: 'No hay categorías disponibles.',
                getTitle: (item) => item.nombre,
                onEdit:
                    (item) => _showEditDialog(provider, item.id, item.nombre),
                onDelete: (item) => _deleteCategory(provider, item),
              ),
              _CatalogList<Grupo>(
                items: provider.grupos,
                emptyLabel: 'No hay grupos disponibles.',
                getTitle: (item) => item.nombre,
                onEdit:
                    (item) => _showEditDialog(provider, item.id, item.nombre),
                onDelete: (item) => _deleteGroup(provider, item),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreate(MovimientosProvider provider) async {
    final name = await _promptForName(
      context,
      title: _tabController.index == 0 ? 'Nueva categoría' : 'Nuevo grupo',
      initialValue: '',
    );
    if (name == null) {
      return;
    }

    final success =
        _tabController.index == 0
            ? await provider.agregarCategoria(name)
            : await provider.agregarGrupo(name);

    if (!mounted) {
      return;
    }

    _showResultSnackBar(
      success: success,
      successText:
          _tabController.index == 0 ? 'Categoría creada' : 'Grupo creado',
      errorText: provider.error ?? 'No se pudo guardar el registro.',
    );
  }

  Future<void> _showEditDialog(
    MovimientosProvider provider,
    String id,
    String currentName,
  ) async {
    final name = await _promptForName(
      context,
      title: 'Editar nombre',
      initialValue: currentName,
    );
    if (name == null) {
      return;
    }

    final success =
        _tabController.index == 0
            ? await provider.editarCategoria(id, name)
            : await provider.editarGrupo(id, name);

    if (!mounted) {
      return;
    }

    _showResultSnackBar(
      success: success,
      successText: 'Registro actualizado',
      errorText: provider.error ?? 'No se pudo actualizar el registro.',
    );
  }

  Future<void> _deleteCategory(
    MovimientosProvider provider,
    Categoria categoria,
  ) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar categoría',
      description: '¿Deseas eliminar "${categoria.nombre}"?',
    );
    if (!confirmed) {
      return;
    }

    final success = await provider.eliminarCategoria(categoria.id);
    if (!mounted) {
      return;
    }

    _showResultSnackBar(
      success: success,
      successText: 'Categoría eliminada',
      errorText: provider.error ?? 'No se pudo eliminar la categoría.',
    );
  }

  Future<void> _deleteGroup(MovimientosProvider provider, Grupo grupo) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar grupo',
      description: '¿Deseas eliminar "${grupo.nombre}"?',
    );
    if (!confirmed) {
      return;
    }

    final success = await provider.eliminarGrupo(grupo.id);
    if (!mounted) {
      return;
    }

    _showResultSnackBar(
      success: success,
      successText: 'Grupo eliminado',
      errorText: provider.error ?? 'No se pudo eliminar el grupo.',
    );
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un nombre';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<bool> _confirmDelete({
    required String title,
    required String description,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
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
    return result ?? false;
  }

  void _showResultSnackBar({
    required bool success,
    required String successText,
    required String errorText,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? successText : errorText),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _CatalogList<T> extends StatelessWidget {
  const _CatalogList({
    required this.items,
    required this.emptyLabel,
    required this.getTitle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<T> items;
  final String emptyLabel;
  final String Function(T item) getTitle;
  final Future<void> Function(T item) onEdit;
  final Future<void> Function(T item) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(getTitle(item)),
            onTap: () => onEdit(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => onDelete(item),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}
