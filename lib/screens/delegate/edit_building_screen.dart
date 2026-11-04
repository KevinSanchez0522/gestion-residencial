import 'package:flutter/material.dart';
import '../../models/building_model.dart';
import '../../viewmodels/building_form_viewmodel.dart';

class EditBuildingScreen extends StatefulWidget {
  final BuildingModel building;

  const EditBuildingScreen({super.key, required this.building});

  @override
  State<EditBuildingScreen> createState() => _EditBuildingScreenState();
}

class _EditBuildingScreenState extends State<EditBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formViewModel = BuildingFormViewModel();
  bool _isSaving = false;

  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _nitController;
  late TextEditingController _addressController;
  late TextEditingController _bankAccountController;
  late TextEditingController _elevatorsCountController;
  late TextEditingController _apartmentsCountController;

  // Proveedores
  late TextEditingController _elevatorCompanyController;
  late TextEditingController _certCompanyController;
  late TextEditingController _doorsCompanyController;
  late TextEditingController _cleaningCompanyController;
  late TextEditingController _securityCompanyController;
  late TextEditingController _gardeningCompanyController;

  // Switches de equipamiento técnico
  late bool _isAutomated;
  late bool _hasElectricDoors;
  late bool _hasGenerator;
  late bool _hasPressurePumps;
  late bool _hasJanitor;

  @override
  void initState() {
    super.initState();
    final b = widget.building;

    // Inicialización de textos
    _nameController = TextEditingController(text: b.name);
    _nitController = TextEditingController(text: b.nit);
    _addressController = TextEditingController(text: b.address);
    _bankAccountController = TextEditingController(text: b.bankAccount);
    _elevatorsCountController = TextEditingController(text: b.elevatorsCount.toString());
    _apartmentsCountController = TextEditingController(text: b.apartmentsCount.toString());

    // Inicialización de proveedores
    _elevatorCompanyController = TextEditingController(text: b.elevatorMaintenanceCompany);
    _certCompanyController = TextEditingController(text: b.certificationCompany);
    _doorsCompanyController = TextEditingController(text: b.electricDoorsCompany);
    _cleaningCompanyController = TextEditingController(text: b.cleaningCompany);
    _securityCompanyController = TextEditingController(text: b.securityCompany);
    _gardeningCompanyController = TextEditingController(text: b.gardeningCompany);

    // Inicialización de estados booleanos
    _isAutomated = b.isAutomated;
    _hasElectricDoors = b.hasElectricDoors;
    _hasGenerator = b.hasGenerator;
    _hasPressurePumps = b.hasPressurePumps;
    _hasJanitor = b.hasJanitor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nitController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _elevatorsCountController.dispose();
    _apartmentsCountController.dispose();
    _elevatorCompanyController.dispose();
    _certCompanyController.dispose();
    _doorsCompanyController.dispose();
    _cleaningCompanyController.dispose();
    _securityCompanyController.dispose();
    _gardeningCompanyController.dispose();
    _formViewModel.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isSaving = true);

    try {
      final updatedBuilding = BuildingModel(
        id: widget.building.id,
        name: _nameController.text.trim(),
        nit: _nitController.text.trim(),
        address: _addressController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        delegateUid: widget.building.delegateUid,
        isAutomated: _isAutomated,
        elevatorsCount:
            int.tryParse(_elevatorsCountController.text.trim()) ?? 0,
        hasElectricDoors: _hasElectricDoors,
        hasGenerator: _hasGenerator,
        hasPressurePumps: _hasPressurePumps,
        hasJanitor: _hasJanitor,
        elevatorCertificationDate: widget.building.elevatorCertificationDate,
        fireExtinguisherRefillDate:
            widget.building.fireExtinguisherRefillDate,
        pumpMaintenanceDate: widget.building.pumpMaintenanceDate,
        generatorMaintenanceDate: widget.building.generatorMaintenanceDate,
        elevatorMaintenanceCompany: _elevatorCompanyController.text.trim(),
        certificationCompany: _certCompanyController.text.trim(),
        electricDoorsCompany: _doorsCompanyController.text.trim(),
        cleaningCompany: _cleaningCompanyController.text.trim(),
        securityCompany: _securityCompanyController.text.trim(),
        gardeningCompany: _gardeningCompanyController.text.trim(),
        staff: widget.building.staff,
        councilMembers: widget.building.councilMembers,
        apartmentsCount:
            int.tryParse(_apartmentsCountController.text.trim()) ?? 0,
        isFavorite: widget.building.isFavorite,
      );

      final success = await _formViewModel.updateBuilding(updatedBuilding);
      if (!success) {
        throw _formViewModel.error ?? 'No se pudo actualizar la copropiedad.';
      }

      if (!mounted) return;
      navigator.pop(updatedBuilding);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Información del edificio actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar cambios: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.building.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Información General'),
            _buildTextField(_nameController, 'Nombre de la Copropiedad', isRequired: true),
            _buildTextField(_nitController, 'NIT', isRequired: true),
            _buildTextField(_addressController, 'Dirección', isRequired: true),
            _buildTextField(_bankAccountController, 'Cuenta Bancaria / Recaudo'),
            _buildTextField(_apartmentsCountController, 'Cantidad de Apartamentos', isNumeric: true),

            const SizedBox(height: 16),
            _buildSectionHeader('Equipamiento e Infraestructura'),
            SwitchListTile(
              title: const Text('¿Es Automatizado?'),
              value: _isAutomated,
              activeThumbColor: Colors.indigo,
              onChanged: (val) => setState(() => _isAutomated = val),
            ),
            _buildTextField(_elevatorsCountController, 'Número de Ascensores', isNumeric: true),
            SwitchListTile(
              title: const Text('¿Tiene Puertas Eléctricas?'),
              value: _hasElectricDoors,
              activeThumbColor: Colors.indigo,
              onChanged: (val) => setState(() => _hasElectricDoors = val),
            ),
            SwitchListTile(
              title: const Text('¿Cuenta con Planta Eléctrica?'),
              value: _hasGenerator,
              activeThumbColor: Colors.indigo,
              onChanged: (val) => setState(() => _hasGenerator = val),
            ),
            SwitchListTile(
              title: const Text('¿Tiene Bombas de Presión?'),
              value: _hasPressurePumps,
              activeThumbColor: Colors.indigo,
              onChanged: (val) => setState(() => _hasPressurePumps = val),
            ),
            SwitchListTile(
              title: const Text('¿Tiene Conserjería / Conserjes?'),
              value: _hasJanitor,
              activeThumbColor: Colors.indigo,
              onChanged: (val) => setState(() => _hasJanitor = val),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('Empresas y Proveedores'),
            _buildTextField(_securityCompanyController, 'Empresa de Vigilancia'),
            _buildTextField(_cleaningCompanyController, 'Empresa de Aseo'),
            _buildTextField(_elevatorCompanyController, 'Mantenimiento de Ascensores'),
            _buildTextField(_certCompanyController, 'Empresa Certificadora'),
            _buildTextField(_doorsCompanyController, 'Mantenimiento Puertas Eléctricas'),
            _buildTextField(_gardeningCompanyController, 'Empresa de Jardinería'),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving ? 'Guardando...' : 'Guardar Cambios',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (isRequired && text.isEmpty) {
            return 'Este campo es obligatorio';
          }
          if (isNumeric && text.isNotEmpty) {
            final number = int.tryParse(text);
            if (number == null || number < 0) {
              return 'Ingresa un número entero mayor o igual a 0';
            }
          }
          return null;
        },
      ),
    );
  }
}