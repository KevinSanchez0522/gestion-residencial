import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/apartment_model.dart';
import '../models/building_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

/// Repositorio local de datos.
///
/// Toda la persistencia de negocio (usuarios, edificios, apartamentos y tareas)
/// se guarda en SQLite. Los flujos de UI escuchan streams que se refrescan
/// automáticamente después de cada operación de escritura.
class DatabaseService {
  DatabaseService({AppDatabase? database})
      : _appDb = database ?? AppDatabase.instance;

  final AppDatabase _appDb;

  /// Compartido por todas las instancias de [DatabaseService] para que una
  /// escritura notifique a cualquier pantalla/ViewModel que esté escuchando,
  /// aunque cada uno haya creado su propio repositorio.
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  final Random _random = Random.secure();

  Future<Database> get _db => _appDb.database;

  void _notifyChange() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  String _newId(String prefix) {
    return '$prefix${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(9999)}';
  }

  Stream<List<T>> _watch<T>(Future<List<T>> Function() loader) {
    return Stream<List<T>>.multi(
      (controller) {
        var cancelled = false;

        Future<void> emit() async {
          if (cancelled) return;
          try {
            final data = await loader();
            if (!cancelled) controller.add(data);
          } catch (error, stackTrace) {
            if (!cancelled) controller.addError(error, stackTrace);
          }
        }

        emit();
        final subscription = _changes.stream.listen((_) => emit());

        controller.onCancel = () {
          cancelled = true;
          subscription.cancel();
        };
      },
      isBroadcast: true,
    );
  }

  // --- USUARIOS ---

  Future<UserModel?> getUserData(String uid) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  UserModel _userFromRow(Map<String, Object?> row) {
    return UserModel(
      uid: row['uid'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      role: row['role'] as String,
      buildingId: row['building_id'] as String?,
      apartment: row['apartment'] as String?,
    );
  }

  // --- EDIFICIOS ---

  Stream<List<BuildingModel>> getDelegateBuildings(String delegateUid) {
    return _watch(
      () => _fetchBuildings(delegateUid: delegateUid),
    );
  }

  Stream<List<BuildingModel>> getAllBuildings() {
    return _watch(_fetchBuildings);
  }

  Stream<BuildingModel?> getBuildingStream(String buildingId) {
    return _watch<BuildingModel?>(() async {
      final building = await getBuilding(buildingId);
      return building == null ? <BuildingModel?>[] : <BuildingModel?>[building];
    }).map((buildings) => buildings.isEmpty ? null : buildings.first);
  }

  Future<BuildingModel?> getBuilding(String buildingId) async {
    final db = await _db;
    final rows = await db.query(
      'buildings',
      where: 'id = ?',
      whereArgs: [buildingId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _buildingFromRow(rows.first);
  }

  Future<List<BuildingModel>> _fetchBuildings({String? delegateUid}) async {
    final db = await _db;
    final rows = await db.query(
      'buildings',
      where: delegateUid == null ? null : 'delegate_uid = ?',
      whereArgs: delegateUid == null ? null : [delegateUid],
      orderBy: 'is_favorite DESC, name COLLATE NOCASE ASC',
    );

    return rows.map(_buildingFromRow).toList();
  }

  Future<String> createBuilding(BuildingModel building) async {
    final db = await _db;
    final id = building.id.trim().isEmpty ? _newId('bld_') : building.id;
    final row = _buildingToRow(building)
      ..['id'] = id
      ..['created_at'] = DateTime.now().toIso8601String();

    await db.insert('buildings', row);
    _notifyChange();
    return id;
  }

  Future<void> updateBuilding(BuildingModel building) async {
    final db = await _db;
    await db.update(
      'buildings',
      _buildingToRow(building),
      where: 'id = ?',
      whereArgs: [building.id],
    );
    _notifyChange();
  }

  Future<void> setBuildingFavorite(String buildingId, bool isFavorite) async {
    final db = await _db;
    await db.update(
      'buildings',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [buildingId],
    );
    _notifyChange();
  }

  Future<void> deleteBuilding(String buildingId) async {
    final db = await _db;
    // Las tablas apartments y tasks tienen ON DELETE CASCADE.
    await db.delete(
      'buildings',
      where: 'id = ?',
      whereArgs: [buildingId],
    );
    _notifyChange();
  }

  Map<String, Object?> _buildingToRow(BuildingModel building) {
    return {
      'id': building.id,
      'name': building.name,
      'address': building.address,
      'nit': building.nit,
      'bank_account': building.bankAccount,
      'delegate_uid': building.delegateUid,
      'is_automated': building.isAutomated ? 1 : 0,
      'elevators_count': building.elevatorsCount,
      'has_electric_doors': building.hasElectricDoors ? 1 : 0,
      'has_generator': building.hasGenerator ? 1 : 0,
      'has_pressure_pumps': building.hasPressurePumps ? 1 : 0,
      'has_janitor': building.hasJanitor ? 1 : 0,
      'elevator_certification_date':
          building.elevatorCertificationDate?.toIso8601String(),
      'fire_extinguisher_refill_date':
          building.fireExtinguisherRefillDate?.toIso8601String(),
      'pump_maintenance_date':
          building.pumpMaintenanceDate?.toIso8601String(),
      'generator_maintenance_date':
          building.generatorMaintenanceDate?.toIso8601String(),
      'elevator_maintenance_company': building.elevatorMaintenanceCompany,
      'certification_company': building.certificationCompany,
      'electric_doors_company': building.electricDoorsCompany,
      'cleaning_company': building.cleaningCompany,
      'security_company': building.securityCompany,
      'gardening_company': building.gardeningCompany,
      'staff_json': jsonEncode(
        building.staff.map((member) => member.toMap()).toList(),
      ),
      'council_json': jsonEncode(
        building.councilMembers.map((member) => member.toMap()).toList(),
      ),
      'apartments_count': building.apartmentsCount,
      'is_favorite': building.isFavorite ? 1 : 0,
    };
  }

  BuildingModel _buildingFromRow(Map<String, Object?> row) {
    final map = <String, dynamic>{
      'name': row['name'],
      'address': row['address'],
      'nit': row['nit'],
      'bankAccount': row['bank_account'],
      'delegateUid': row['delegate_uid'],
      'isAutomated': (row['is_automated'] as int? ?? 0) == 1,
      'elevatorsCount': row['elevators_count'] as int? ?? 0,
      'hasElectricDoors': (row['has_electric_doors'] as int? ?? 0) == 1,
      'hasGenerator': (row['has_generator'] as int? ?? 0) == 1,
      'hasPressurePumps': (row['has_pressure_pumps'] as int? ?? 0) == 1,
      'hasJanitor': (row['has_janitor'] as int? ?? 0) == 1,
      'elevatorCertificationDate': row['elevator_certification_date'],
      'fireExtinguisherRefillDate': row['fire_extinguisher_refill_date'],
      'pumpMaintenanceDate': row['pump_maintenance_date'],
      'generatorMaintenanceDate': row['generator_maintenance_date'],
      'elevatorMaintenanceCompany': row['elevator_maintenance_company'],
      'certificationCompany': row['certification_company'],
      'electricDoorsCompany': row['electric_doors_company'],
      'cleaningCompany': row['cleaning_company'],
      'securityCompany': row['security_company'],
      'gardeningCompany': row['gardening_company'],
      'staff': jsonDecode((row['staff_json'] as String?) ?? '[]'),
      'councilMembers': jsonDecode((row['council_json'] as String?) ?? '[]'),
      'apartmentsCount': row['apartments_count'] as int? ?? 0,
      'isFavorite': (row['is_favorite'] as int? ?? 0) == 1,
    };

    return BuildingModel.fromMap(map, row['id'] as String);
  }

  // --- APARTAMENTOS ---

  Stream<List<ApartmentModel>> getBuildingApartments(String buildingId) {
    return _watch(() => _fetchApartments(buildingId));
  }

  Future<List<ApartmentModel>> _fetchApartments(String buildingId) async {
    final db = await _db;
    final rows = await db.query(
      'apartments',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'nomenclature COLLATE NOCASE ASC',
    );

    return rows.map(_apartmentFromRow).toList();
  }

  Future<void> saveApartment(
    String buildingId,
    ApartmentModel apartment,
  ) async {
    final db = await _db;
    final id = apartment.id.trim().isEmpty
        ? apartment.nomenclature.trim()
        : apartment.id;

    await db.insert(
      'apartments',
      _apartmentToRow(buildingId, apartment, id),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyChange();
  }

  Future<void> renameApartment({
    required String buildingId,
    required String oldApartmentId,
    required ApartmentModel newApartment,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'apartments',
        _apartmentToRow(buildingId, newApartment, newApartment.id),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (oldApartmentId != newApartment.id) {
        await txn.delete(
          'apartments',
          where: 'building_id = ? AND id = ?',
          whereArgs: [buildingId, oldApartmentId],
        );
      }
    });
    _notifyChange();
  }

  Future<void> deleteApartment(
    String buildingId,
    String apartmentId,
  ) async {
    final db = await _db;
    await db.delete(
      'apartments',
      where: 'building_id = ? AND id = ?',
      whereArgs: [buildingId, apartmentId],
    );
    _notifyChange();
  }

  Map<String, Object?> _apartmentToRow(
    String buildingId,
    ApartmentModel apartment,
    String id,
  ) {
    return {
      'id': id,
      'building_id': buildingId,
      'nomenclature': apartment.nomenclature,
      'has_children': apartment.hasChildren ? 1 : 0,
      'children_count': apartment.childrenCount,
      'occupants_json': jsonEncode(
        apartment.occupants.map((person) => person.toMap()).toList(),
      ),
    };
  }

  ApartmentModel _apartmentFromRow(Map<String, Object?> row) {
    final map = <String, dynamic>{
      'nomenclature': row['nomenclature'],
      'hasChildren': (row['has_children'] as int? ?? 0) == 1,
      'childrenCount': row['children_count'] as int? ?? 0,
      'occupants': jsonDecode((row['occupants_json'] as String?) ?? '[]'),
    };

    return ApartmentModel.fromMap(map, row['id'] as String);
  }

  // --- TAREAS ---

  Stream<List<TaskModel>> getBuildingTasks(String buildingId) {
    return _watch(() => _fetchTasks(buildingId));
  }

  Future<List<TaskModel>> _fetchTasks(String buildingId) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'due_date ASC',
    );

    return rows.map(_taskFromRow).toList();
  }

  Future<String> createTask(TaskModel task) async {
    final db = await _db;
    final id = task.id.trim().isEmpty ? _newId('tsk_') : task.id;
    final row = _taskToRow(task)
      ..['id'] = id
      ..['created_at'] = DateTime.now().toIso8601String();

    await db.insert('tasks', row);
    _notifyChange();
    return id;
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    final db = await _db;
    await db.update(
      'tasks',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [taskId],
    );
    _notifyChange();
  }

  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
    _notifyChange();
  }

  Map<String, Object?> _taskToRow(TaskModel task) {
    return {
      'id': task.id,
      'building_id': task.buildingId,
      'title': task.title,
      'description': task.description,
      'due_date': task.dueDate.toIso8601String(),
      'status': task.status,
      'reminder_minutes_before': task.reminderMinutesBefore,
      'type': task.type,
      'reported_by_uid': task.reportedByUid,
      'reported_by_name': task.reportedByName,
      'reported_by_apartment': task.reportedByApartment,
    };
  }

  TaskModel _taskFromRow(Map<String, Object?> row) {
    final map = <String, dynamic>{
      'buildingId': row['building_id'],
      'title': row['title'],
      'description': row['description'],
      'dueDate': row['due_date'],
      'status': row['status'],
      'reminderMinutesBefore': row['reminder_minutes_before'],
      'type': row['type'],
      'reportedByUid': row['reported_by_uid'],
      'reportedByName': row['reported_by_name'],
      'reportedByApartment': row['reported_by_apartment'],
    };

    return TaskModel.fromMap(map, row['id'] as String);
  }
}
