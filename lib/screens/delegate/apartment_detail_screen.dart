import 'package:flutter/material.dart';
import '../../models/apartment_model.dart';
import '../../services/database_service.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final String buildingId;
  final ApartmentModel apartment;

  const ApartmentDetailScreen({
    super.key,
    required this.buildingId,
    required this.apartment,
  });

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  late ApartmentModel _currentApt;

  @override
  void initState() {
    super.initState();
    _currentApt = widget.apartment;
  }

  // Diálogo para registrar una persona (propietario, residente o inquilino)
  void _showAddPersonDialog() {
    final nameCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String personType = 'propietario';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Registrar en ${_currentApt.nomenclature}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: personType,
                  decoration: const InputDecoration(labelText: 'Tipo de Ocupante', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'propietario', child: Text('Propietario')),
                    DropdownMenuItem(value: 'residente', child: Text('Residente')),
                    DropdownMenuItem(value: 'inquilino', child: Text('Inquilino / Arrendatario')),
                  ],
                  onChanged: (val) => setDlgState(() => personType = val ?? 'residente'),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Documento de Identidad', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final newPerson = ResidentPerson(
                  fullName: nameCtrl.text.trim(),
                  documentId: docCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  type: personType,
                );

                final updatedList = List<ResidentPerson>.from(_currentApt.occupants)..add(newPerson);

                final updatedApt = ApartmentModel(
                  id: _currentApt.id,
                  nomenclature: _currentApt.nomenclature,
                  hasChildren: _currentApt.hasChildren,
                  childrenCount: _currentApt.childrenCount,
                  occupants: updatedList,
                );

                await _dbService.saveApartment(widget.buildingId, updatedApt);
                setState(() => _currentApt = updatedApt);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Eliminar el apartamento completo (y sus ocupantes)
  Future<void> _confirmDeleteApartment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar apartamento'),
        content: Text(
          '¿Seguro que deseas eliminar "${_currentApt.nomenclature}"?\n\n'
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

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _dbService.deleteApartment(widget.buildingId, _currentApt.id);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${_currentApt.nomenclature}" eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el apartamento: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Eliminar un residente
  Future<void> _removePerson(int index) async {
    final updatedList = List<ResidentPerson>.from(_currentApt.occupants)..removeAt(index);
    final updatedApt = ApartmentModel(
      id: _currentApt.id,
      nomenclature: _currentApt.nomenclature,
      hasChildren: _currentApt.hasChildren,
      childrenCount: _currentApt.childrenCount,
      occupants: updatedList,
    );
    await _dbService.saveApartment(widget.buildingId, updatedApt);
    setState(() => _currentApt = updatedApt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentApt.nomenclature),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar apartamento',
            onPressed: _confirmDeleteApartment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPersonDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Agregar Residente', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.indigo, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentApt.hasChildren
                              ? 'Habitan niños: ${_currentApt.childrenCount}'
                              : 'No habitan menores de edad',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text('Información relevante para emergencias y evacuación'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Personas Vinculadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 8),
          if (_currentApt.occupants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No hay personas registradas en este apartamento.\nToca "+ Agregar Residente" para empezar.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            ),
          ..._currentApt.occupants.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;

            Color badgeColor;
            switch (p.type.toLowerCase()) {
              case 'propietario':
                badgeColor = Colors.green;
                break;
              case 'inquilino':
                badgeColor = Colors.orange;
                break;
              default:
                badgeColor = Colors.blue;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: badgeColor),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.type.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('Doc: ${p.documentId.isEmpty ? "N/A" : p.documentId}\nTel: ${p.phone.isEmpty ? "N/A" : p.phone} | Correo: ${p.email.isEmpty ? "N/A" : p.email}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removePerson(idx),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}