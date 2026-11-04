import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/building_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/buildings_viewmodel.dart';
import 'building_detail_screen.dart';
import 'building_tasks_screen.dart';
import 'create_building_screen.dart';
import 'edit_building_screen.dart';

class DelegateHomeScreen extends StatefulWidget {
  const DelegateHomeScreen({super.key});

  @override
  State<DelegateHomeScreen> createState() => _DelegateHomeScreenState();
}

class _DelegateHomeScreenState extends State<DelegateHomeScreen> {
  static const String _standardManagerCode = 'GERENCIA2026';

  late final BuildingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user?.uid ?? '';
    _viewModel = BuildingsViewModel(delegateUid: uid)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorizationAndNavigate() async {
    final codeController = TextEditingController();

    final bool? isAuthorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.indigo),
            SizedBox(width: 8),
            Expanded(child: Text('Autorización de Gerencia')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para registrar una nueva copropiedad debes ingresar el código de autorización emitido por la Gerencia:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              obscureText: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código del Gerente',
                prefixIcon: Icon(Icons.key, color: Colors.indigo),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final enteredCode = codeController.text.trim();
              if (enteredCode == _standardManagerCode) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código de autorización incorrecto o vencido.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Validar y Continuar'),
          ),
        ],
      ),
    );

    if (isAuthorized == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateBuildingScreen()),
      );
    }
  }

  Future<void> _confirmDeleteBuilding(BuildingModel building) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(child: Text('Eliminar copropiedad')),
          ],
        ),
        content: Text(
          '¿Seguro que deseas eliminar "${building.name}"?\n\n'
          'También se eliminarán sus apartamentos y tareas asociadas. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _viewModel.deleteBuilding(building);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${building.name}" eliminado correctamente'
              : _viewModel.error ?? 'No se pudo eliminar la copropiedad',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _toggleFavorite(BuildingModel building) async {
    final success = await _viewModel.toggleFavorite(building);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (building.isFavorite
                  ? '"${building.name}" quitado de favoritos'
                  : '"${building.name}" marcado como favorito')
              : _viewModel.error ?? 'No se pudo actualizar el favorito',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  void _openActions(String value, BuildingModel building) {
    switch (value) {
      case 'favorite':
        _toggleFavorite(building);
        break;
      case 'tasks':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuildingTasksScreen(building: building),
          ),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditBuildingScreen(building: building),
          ),
        );
        break;
      case 'delete':
        _confirmDeleteBuilding(building);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edificios a Cargo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checkAuthorizationAndNavigate,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text(
          'Nuevo Edificio',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.error != null && _viewModel.buildings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _viewModel.load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final buildings = _viewModel.buildings;
          if (buildings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No tienes edificios asignados actualmente.\n\n'
                  'Solicita el código a tu Gerente y pulsa el botón '
                  '"Nuevo Edificio" para darlo de alta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _viewModel.load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: buildings.length,
              itemBuilder: (context, index) {
                final building = buildings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          building.isFavorite ? Colors.amber : Colors.indigo,
                      child: Icon(
                        building.isFavorite ? Icons.star : Icons.apartment,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      building.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('${building.address}\nNIT: ${building.nit}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones de ${building.name}',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _openActions(value, building),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                building.isFavorite
                                    ? Icons.star_outline
                                    : Icons.star,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                building.isFavorite
                                    ? 'Quitar de favoritos'
                                    : 'Marcar favorito',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'tasks',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: Colors.indigo),
                              SizedBox(width: 12),
                              Text('Tareas y calendario'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.indigo),
                              SizedBox(width: 12),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              SizedBox(width: 12),
                              Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuildingDetailScreen(
                            building: building,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
