import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/building_model.dart';
import '../../models/apartment_model.dart';
import '../../services/database_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/building_form_viewmodel.dart';

class CreateBuildingScreen extends StatefulWidget {
  const CreateBuildingScreen({super.key});

  @override
  State<CreateBuildingScreen> createState() => _CreateBuildingScreenState();
}

class _CreateBuildingScreenState extends State<CreateBuildingScreen> {
  final _dbService = DatabaseService();
  final _formViewModel = BuildingFormViewModel();
  final _basicsFormKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  // Paso 1: Datos Básicos
  final _nameCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _apartmentsCountCtrl = TextEditingController();

  // Paso 2: Equipos e Infraestructura
  bool _isAutomated = false;
  final _elevatorsCountCtrl = TextEditingController(text: '0');
  bool _hasElectricDoors = false;
  bool _hasGenerator = false;
  bool _hasPressurePumps = false;
  bool _hasJanitor = false;

  // Fechas Clave
  DateTime? _elevatorCertDate;
  DateTime? _fireExtinguisherDate;
  DateTime? _pumpMaintenanceDate;
  DateTime? _generatorMaintenanceDate;

  // Paso 3: Proveedores y Contratos
  final _securityCompanyCtrl = TextEditingController();
  final _cleaningCompanyCtrl = TextEditingController();
  final _elevatorCompanyCtrl = TextEditingController();
  final _certCompanyCtrl = TextEditingController();
  final _doorsCompanyCtrl = TextEditingController();
  final _gardeningCompanyCtrl = TextEditingController();

  // Paso 4: Listas dinámicas de Personal y Consejo
  final List<StaffMember> _staffList = [];
  final List<CouncilMember> _councilList = [];

  // Paso 5: Opciones para generar apartamentos
  bool _autoGenerateApartments = true;
  final _prefixApartmentCtrl = TextEditingController(text: 'Torre 1 - Apt ');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nitCtrl.dispose();
    _addressCtrl.dispose();
    _bankAccountCtrl.dispose();
    _apartmentsCountCtrl.dispose();
    _elevatorsCountCtrl.dispose();
    _securityCompanyCtrl.dispose();
    _cleaningCompanyCtrl.dispose();
    _elevatorCompanyCtrl.dispose();
    _certCompanyCtrl.dispose();
    _doorsCompanyCtrl.dispose();
    _gardeningCompanyCtrl.dispose();
    _prefixApartmentCtrl.dispose();
    _formViewModel.dispose();
    super.dispose();
  }

  // Selector de fecha reutilizable
  Future<void> _selectDate(BuildContext context, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  // Diálogo para agregar personal
  void _addStaffDialog() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Vigilante');
    final scheduleCtrl = TextEditingController(text: 'Turno 12h (6am - 6pm)');
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Trabajador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Cargo (ej. Vigilante, Aseo, Conserje)')),
              TextField(controller: scheduleCtrl, decoration: const InputDecoration(labelText: 'Horario Asignado')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono Contacto')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _staffList.add(StaffMember(
                    name: nameCtrl.text.trim(),
                    role: roleCtrl.text.trim(),
                    schedule: scheduleCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para agregar miembro del consejo
  void _addCouncilDialog() {
    final nameCtrl = TextEditingController();
    final posCtrl = TextEditingController(text: 'Presidente');
    final aptCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Miembro del Consejo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Cargo (Presidente, Secretario, Vocal)')),
              TextField(controller: aptCtrl, decoration: const InputDecoration(labelText: 'Apartamento')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _councilList.add(CouncilMember(
                    name: nameCtrl.text.trim(),
                    position: posCtrl.text.trim(),
                    apartment: aptCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  String? _validateBasics() {
    if (_nameCtrl.text.trim().isEmpty) {
      return 'El nombre de la copropiedad es obligatorio.';
    }
    if (_nameCtrl.text.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }
    if (_nitCtrl.text.trim().isEmpty) {
      return 'El NIT es obligatorio.';
    }
    if (_addressCtrl.text.trim().isEmpty) {
      return 'La dirección es obligatoria.';
    }
    final aptText = _apartmentsCountCtrl.text.trim();
    if (aptText.isNotEmpty) {
      final aptCount = int.tryParse(aptText);
      if (aptCount == null || aptCount < 0) {
        return 'La cantidad de apartamentos debe ser un entero mayor o igual a 0.';
      }
    }
    return null;
  }

  // Guardar en la base de datos local.
  Future<void> _saveBuilding() async {
    final basicsError = _validateBasics();
    if (basicsError != null) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(basicsError),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final elevatorsCount = int.tryParse(_elevatorsCountCtrl.text.trim()) ?? 0;
    if (elevatorsCount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El número de ascensores no puede ser negativo.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final currentUid = context.read<AuthViewModel>().user?.uid;

    setState(() => _isSaving = true);

    try {
      final int aptCount = int.tryParse(_apartmentsCountCtrl.text.trim()) ?? 0;

      final newBuilding = BuildingModel(
        id: '',
        name: _nameCtrl.text.trim(),
        nit: _nitCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
        delegateUid: currentUid,
        isAutomated: _isAutomated,
        elevatorsCount: elevatorsCount,
        hasElectricDoors: _hasElectricDoors,
        hasGenerator: _hasGenerator,
        hasPressurePumps: _hasPressurePumps,
        hasJanitor: _hasJanitor,
        elevatorCertificationDate: _elevatorCertDate,
        fireExtinguisherRefillDate: _fireExtinguisherDate,
        pumpMaintenanceDate: _pumpMaintenanceDate,
        generatorMaintenanceDate: _generatorMaintenanceDate,
        elevatorMaintenanceCompany: _elevatorCompanyCtrl.text.trim(),
        certificationCompany: _certCompanyCtrl.text.trim(),
        electricDoorsCompany: _doorsCompanyCtrl.text.trim(),
        cleaningCompany: _cleaningCompanyCtrl.text.trim(),
        securityCompany: _securityCompanyCtrl.text.trim(),
        gardeningCompany: _gardeningCompanyCtrl.text.trim(),
        staff: _staffList,
        councilMembers: _councilList,
        apartmentsCount: aptCount,
      );

      final buildingId = await _formViewModel.createBuilding(newBuilding);
      if (buildingId == null) {
        throw _formViewModel.error ?? 'No se pudo crear la copropiedad.';
      }

      if (_autoGenerateApartments && aptCount > 0) {
        final prefix = _prefixApartmentCtrl.text.trim();
        for (int i = 1; i <= aptCount; i++) {
          final aptId = '$prefix$i';
          final apt = ApartmentModel(
            id: aptId,
            nomenclature: aptId,
            hasChildren: false,
            childrenCount: 0,
            occupants: [],
          );
          await _dbService.saveApartment(buildingId, apt);
        }
      }

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Copropiedad creada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
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
        title: const Text('Nuevo Edificio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 16),
                  Text('Guardando edificio y configurando unidades...'),
                ],
              ),
            )
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0 &&
                    !(_basicsFormKey.currentState?.validate() ?? false)) {
                  return;
                }
                if (_currentStep < 4) {
                  setState(() => _currentStep++);
                } else {
                  _saveBuilding();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 4;
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(isLastStep ? 'Crear Copropiedad' : 'Siguiente'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Atrás'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                // 1. Datos Generales
                Step(
                  isActive: _currentStep >= 0,
                  title: const Text('General'),
                  content: Form(
                    key: _basicsFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Copropiedad *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            if (value.trim().length < 3) {
                              return 'Escribe al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nitCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'NIT *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El NIT es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Dirección *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La dirección es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _bankAccountCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Cuenta Bancaria de Recaudo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _apartmentsCountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad Total de Apartamentos',
                            helperText: 'Puede dejarse en 0 si aún no se conoce.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final count = int.tryParse(text);
                            if (count == null || count < 0) {
                              return 'Ingresa un número entero mayor o igual a 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Equipamiento y Fechas
                Step(
                  isActive: _currentStep >= 1,
                  title: const Text('Equipos'),
                  content: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('¿Es automatizado?'),
                        value: _isAutomated,
                        onChanged: (v) => setState(() => _isAutomated = v),
                      ),
                      SwitchListTile(
                        title: const Text('¿Tiene puertas eléctricas?'),
                        value: _hasElectricDoors,
                        onChanged: (v) => setState(() => _hasElectricDoors = v),
                      ),
                      SwitchListTile(
                        title: const Text('¿Tiene planta eléctrica?'),
                        value: _hasGenerator,
                        onChanged: (v) => setState(() => _hasGenerator = v),
                      ),
                      SwitchListTile(
                        title: const Text('¿Tiene bombas de presión?'),
                        value: _hasPressurePumps,
                        onChanged: (v) => setState(() => _hasPressurePumps = v),
                      ),
                      SwitchListTile(
                        title: const Text('¿Cuenta con conserjes?'),
                        value: _hasJanitor,
                        onChanged: (v) => setState(() => _hasJanitor = v),
                      ),
                      TextField(
                        controller: _elevatorsCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cantidad de Ascensores', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fechas Críticas de Mantenimiento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ListTile(
                        leading: const Icon(Icons.elevator, color: Colors.indigo),
                        title: Text(_elevatorCertDate == null ? 'Certificación de Ascensores' : 'Cert. Ascensores: ${_elevatorCertDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _selectDate(context, (d) => _elevatorCertDate = d),
                      ),
                      ListTile(
                        leading: const Icon(Icons.fire_extinguisher, color: Colors.red),
                        title: Text(_fireExtinguisherDate == null ? 'Recarga de Extintores' : 'Extintores: ${_fireExtinguisherDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _selectDate(context, (d) => _fireExtinguisherDate = d),
                      ),
                      ListTile(
                        leading: const Icon(Icons.water_drop, color: Colors.blue),
                        title: Text(_pumpMaintenanceDate == null ? 'Mantenimiento de Bombas' : 'Bombas: ${_pumpMaintenanceDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _selectDate(context, (d) => _pumpMaintenanceDate = d),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bolt, color: Colors.amber),
                        title: Text(_generatorMaintenanceDate == null ? 'Mantenimiento Planta Eléctrica' : 'Planta: ${_generatorMaintenanceDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _selectDate(context, (d) => _generatorMaintenanceDate = d),
                      ),
                    ],
                  ),
                ),

                // 3. Proveedores
                Step(
                  isActive: _currentStep >= 2,
                  title: const Text('Contratos'),
                  content: Column(
                    children: [
                      TextField(controller: _securityCompanyCtrl, decoration: const InputDecoration(labelText: 'Empresa de Vigilancia', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _cleaningCompanyCtrl, decoration: const InputDecoration(labelText: 'Empresa de Aseo', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _elevatorCompanyCtrl, decoration: const InputDecoration(labelText: 'Mantenimiento de Ascensores', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _certCompanyCtrl, decoration: const InputDecoration(labelText: 'Empresa Certificadora Ascensores', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _doorsCompanyCtrl, decoration: const InputDecoration(labelText: 'Mantenimiento Puertas Eléctricas', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _gardeningCompanyCtrl, decoration: const InputDecoration(labelText: 'Empresa de Jardinería', border: OutlineInputBorder())),
                    ],
                  ),
                ),

                // 4. Personal y Consejo
                Step(
                  isActive: _currentStep >= 3,
                  title: const Text('Equipo'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Personal Asignado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(onPressed: _addStaffDialog, icon: const Icon(Icons.person_add, color: Colors.indigo)),
                        ],
                      ),
                      if (_staffList.isEmpty) const Text('No has agregado personal aún.', style: TextStyle(color: Colors.grey)),
                      ..._staffList.map((s) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.badge, color: Colors.indigo),
                              title: Text(s.name),
                              subtitle: Text('${s.role} - ${s.schedule}\nTel: ${s.phone}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => setState(() => _staffList.remove(s)),
                              ),
                            ),
                          )),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Miembros del Consejo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(onPressed: _addCouncilDialog, icon: const Icon(Icons.group_add, color: Colors.indigo)),
                        ],
                      ),
                      if (_councilList.isEmpty) const Text('No has agregado miembros del consejo.', style: TextStyle(color: Colors.grey)),
                      ..._councilList.map((c) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.assignment_ind, color: Colors.indigo),
                              title: Text(c.name),
                              subtitle: Text('${c.position} - Apt: ${c.apartment}\nTel: ${c.phone}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => setState(() => _councilList.remove(c)),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                // 5. Generación de Apartamentos
                Step(
                  isActive: _currentStep >= 4,
                  title: const Text('Unidades'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('¿Generar nomenclatura automáticamente?'),
                        subtitle: const Text('Crea las unidades vacías para luego registrar propietarios e inquilinos.'),
                        value: _autoGenerateApartments,
                        onChanged: (v) => setState(() => _autoGenerateApartments = v),
                      ),
                      if (_autoGenerateApartments) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _prefixApartmentCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Prefijo de Nomenclatura',
                            helperText: 'Ejemplo: "Apto " generará Apto 1, Apto 2, etc.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}