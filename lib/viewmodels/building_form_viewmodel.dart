import 'package:flutter/foundation.dart';

import '../models/building_model.dart';
import '../services/database_service.dart';

/// ViewModel compartido por los formularios de creación y edición.
class BuildingFormViewModel extends ChangeNotifier {
  BuildingFormViewModel({DatabaseService? database})
      : _database = database ?? DatabaseService();

  final DatabaseService _database;

  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<String?> createBuilding(BuildingModel building) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      return await _database.createBuilding(building);
    } catch (error) {
      _error = 'No se pudo crear la copropiedad: $error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateBuilding(BuildingModel building) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _database.updateBuilding(building);
      return true;
    } catch (error) {
      _error = 'No se pudo actualizar la copropiedad: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
