import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/building_model.dart';
import '../../models/apartment_model.dart';
import '../../viewmodels/building_detail_viewmodel.dart';
import 'edit_building_screen.dart';
import 'apartment_detail_screen.dart';
import 'building_tasks_screen.dart';

class BuildingDetailScreen extends StatefulWidget {
  final BuildingModel building;

  const BuildingDetailScreen({super.key, required this.building});

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final BuildingDetailViewModel _viewModel;
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel = BuildingDetailViewModel(
      buildingId: widget.building.id,
      initialBuilding: widget.building,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _showAddApartmentDialog() {
    final nameCtrl = TextEditingController();
    int childrenCount = 0;
    bool hasChildren = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Apartamento / Nomenclatura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomenclatura (ej: Apto 101, Torre 1 - 202)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Viven niños?'),
                value: hasChildren,
                onChanged: (val) {
                  setDlgState(() {
                    hasChildren = val;
                    if (!val) childrenCount = 0;
                  });
                },
              ),
              if (hasChildren)
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de niños',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => childrenCount = int.tryParse(v) ?? 0,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nom = nameCtrl.text.trim();
                if (nom.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa la nomenclatura del apartamento'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

                final newApt = ApartmentModel(
                  id: nom,
                  nomenclature: nom,
                  hasChildren: hasChildren,
                  childrenCount: childrenCount,
                  occupants: [],
                );
                final success = await _viewModel.addApartment(newApt);
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage(
                  success
                      ? 'Apartamento "$nom" agregado correctamente'
                      : _viewModel.error ?? 'No se pudo guardar el apartamento',
                  isError: !success,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNomenclatureDialog(ApartmentModel apt) {
    final nameCtrl = TextEditingController(text: apt.nomenclature);
    bool hasChildren = apt.hasChildren;
    final childrenCtrl = TextEditingController(text: apt.childrenCount.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Renombrar Apartamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomenclatura real',
                  hintText: 'Ej: Apto 201, PH 1, Int 2 - 304',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note, color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('¿Viven menores de edad?'),
                value: hasChildren,
                activeThumbColor: Colors.indigo,
                onChanged: (val) {
                  setDlgState(() {
                    hasChildren = val;
                  });
                },
              ),
              if (hasChildren)
                TextField(
                  controller: childrenCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de niños',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La nomenclatura no puede estar vacía'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

                final parsedChildren =
                    int.tryParse(childrenCtrl.text.trim()) ?? 0;
                if (hasChildren && parsedChildren < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La cantidad de niños no puede ser negativa'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }

                final updatedApt = ApartmentModel(
                  id: newName,
                  nomenclature: newName,
                  hasChildren: hasChildren,
                  childrenCount: hasChildren ? parsedChildren : 0,
                  occupants: apt.occupants,
                );

                final success = await _viewModel.renameApartment(
                  oldApartmentId: apt.id,
                  updatedApartment: updatedApt,
                );
                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage(
                  success
                      ? 'Apartamento actualizado correctamente'
                      : _viewModel.error ??
                          'No se pudo actualizar el apartamento',
                  isError: !success,
                );
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBuilding() async {
    final buildingName = _viewModel.building?.name ?? widget.building.name;
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
          '¿Seguro que deseas eliminar "$buildingName"?\n\n'
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

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await _viewModel.deleteBuilding();
    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"$buildingName" eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.error ?? 'No se pudo eliminar la copropiedad',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDeleteApartment(ApartmentModel apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar apartamento'),
        content: Text(
          '¿Seguro que deseas eliminar "${apt.nomenclature}"?\n\n'
          'También se perderá la información de sus ocupantes. '
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

    final success = await _viewModel.deleteApartment(apt);
    if (!mounted) return;

    _showMessage(
      success
          ? '"${apt.nomenclature}" eliminado correctamente'
          : _viewModel.error ?? 'No se pudo eliminar el apartamento',
      isError: !success,
    );
  }

  Future<void> _toggleFavorite() async {
    final success = await _viewModel.toggleFavorite();
    if (!mounted) return;

    final isFavorite = _viewModel.building?.isFavorite ?? false;
    _showMessage(
      success
          ? (isFavorite
              ? 'Copropiedad marcada como favorita'
              : 'Copropiedad quitada de favoritos')
          : _viewModel.error ?? 'No se pudo actualizar el favorito',
      isError: !success,
    );
  }

  Future<void> _shareBuilding() async {
    final b = _viewModel.building;
    if (b == null) return;

    final text = 'Copropiedad: ${b.name}\n'
        'NIT: ${b.nit}\n'
        'Dirección: ${b.address}\n'
        'Apartamentos configurados: ${b.apartmentsCount}';

    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (error) {
      if (!mounted) return;
      _showMessage('No se pudo compartir la información: $error',
          isError: true);
    }
  }

  Future<void> _openEdit() async {
    final building = _viewModel.building ?? widget.building;
    await Navigator.push<BuildingModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditBuildingScreen(building: building),
      ),
    );
  }

  void _openTasks() {
    final building = _viewModel.building ?? widget.building;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuildingTasksScreen(building: building),
      ),
    );
  }

  void _openBuildingAction(String value) {
    switch (value) {
      case 'tasks':
        _openTasks();
        break;
      case 'edit':
        _openEdit();
        break;
      case 'delete':
        _confirmDeleteBuilding();
        break;
    }
  }

  Widget _dateTile(String title, IconData icon, Color color, DateTime? date) {
    final isExpired = date != null && date.isBefore(DateTime.now());
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        date == null ? 'Sin registrar' : _df.format(date),
        style: TextStyle(
          color: date == null
              ? Colors.grey
              : isExpired
                  ? Colors.red.shade700
                  : Colors.black87,
          fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isExpired
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text('Vencido',
                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final b = _viewModel.building;
        if (b == null) {
          if (_viewModel.error != null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Copropiedad'),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _viewModel.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(b.name),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(b.isFavorite ? Icons.star : Icons.star_border),
                tooltip: b.isFavorite
                    ? 'Quitar de favoritos'
                    : 'Marcar como favorito',
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartir información',
                onPressed: _shareBuilding,
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones',
                icon: const Icon(Icons.more_vert),
                onSelected: _openBuildingAction,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'tasks',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.indigo),
                        SizedBox(width: 12),
                        Text('Tareas y calendario'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.indigo),
                        SizedBox(width: 12),
                        Text('Editar datos'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text(
                          'Eliminar copropiedad',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Ficha Técnica'),
                Tab(icon: Icon(Icons.door_front_door), text: 'Apartamentos'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(b),
              _buildApartmentsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(BuildingModel b) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 6),
                Text('NIT: ${b.nit}', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Dirección: ${b.address}'),
                Text('Cuenta Bancaria: ${b.bankAccount.isEmpty ? 'No registrada' : b.bankAccount}'),
                Text('Total Apartamentos Configurados: ${b.apartmentsCount}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Equipos y Sistemas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('Automatizado', b.isAutomated),
            _buildChip('${b.elevatorsCount} Ascensores', b.elevatorsCount > 0),
            _buildChip('Puertas Eléctricas', b.hasElectricDoors),
            _buildChip('Planta Eléctrica', b.hasGenerator),
            _buildChip('Bombas de Presión', b.hasPressurePumps),
            _buildChip('Conserjería', b.hasJanitor),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Certificaciones y Mantenimientos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _dateTile('Certificación de Ascensores', Icons.elevator, Colors.indigo, b.elevatorCertificationDate),
              const Divider(height: 1),
              _dateTile('Recarga de Extintores', Icons.fire_extinguisher, Colors.red, b.fireExtinguisherRefillDate),
              const Divider(height: 1),
              _dateTile('Mantenimiento de Bombas', Icons.water_drop, Colors.blue, b.pumpMaintenanceDate),
              const Divider(height: 1),
              _dateTile('Mantenimiento Planta Eléctrica', Icons.bolt, Colors.amber, b.generatorMaintenanceDate),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Contactos y Emergencias',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8EAF6), child: Icon(Icons.security, color: Colors.indigo)),
                title: const Text('Vigilancia'),
                subtitle: Text(b.securityCompany.isEmpty ? 'Sin asignar' : b.securityCompany),
                trailing: b.securityCompany.isNotEmpty ? const Icon(Icons.phone, color: Colors.indigo) : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE0F7FA), child: Icon(Icons.cleaning_services, color: Colors.teal)),
                title: const Text('Aseo'),
                subtitle: Text(b.cleaningCompany.isEmpty ? 'Sin asignar' : b.cleaningCompany),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.elevator, color: Colors.blue)),
                title: const Text('Mantenimiento Ascensores'),
                subtitle: Text(b.elevatorMaintenanceCompany.isEmpty ? 'Sin asignar' : b.elevatorMaintenanceCompany),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF3E5F5), child: Icon(Icons.verified, color: Colors.purple)),
                title: const Text('Certificadora'),
                subtitle: Text(b.certificationCompany.isEmpty ? 'Sin asignar' : b.certificationCompany),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF1F8E9), child: Icon(Icons.garage, color: Colors.green)),
                title: const Text('Puertas Eléctricas'),
                subtitle: Text(b.electricDoorsCompany.isEmpty ? 'Sin asignar' : b.electricDoorsCompany),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.local_florist, color: Colors.orange)),
                title: const Text('Jardinería'),
                subtitle: Text(b.gardeningCompany.isEmpty ? 'Sin asignar' : b.gardeningCompany),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool active) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: active ? Colors.green : Colors.grey,
        size: 18,
      ),
      label: Text(label),
      backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade100,
    );
  }

  Widget _buildApartmentsTab() {
    if (_viewModel.isLoadingApartments) {
      return const Center(child: CircularProgressIndicator());
    }

    final apartments = _viewModel.apartments;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddApartmentDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Apartamento',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: apartments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.apartment, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Aún no hay apartamentos registrados en este edificio.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddApartmentDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Primer Apartamento'),
                    )
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: apartments.length,
              itemBuilder: (context, index) {
                final apt = apartments[index];
                final residentsCount = apt.occupants.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: const Icon(Icons.meeting_room,
                          color: Colors.indigo),
                    ),
                    title: Text(
                      apt.nomenclature,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '$residentsCount residente(s) registrado(s)'
                      '${apt.hasChildren ? " • Niños: ${apt.childrenCount}" : ""}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones del apartamento',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditNomenclatureDialog(apt);
                            break;
                          case 'delete':
                            _confirmDeleteApartment(apt);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.indigo),
                              SizedBox(width: 12),
                              Text('Renombrar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
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
                          builder: (_) => ApartmentDetailScreen(
                            buildingId: _viewModel.buildingId,
                            apartment: apt,
                          ),
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