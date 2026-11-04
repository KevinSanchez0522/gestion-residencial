import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/building_model.dart';
import '../services/database_service.dart';

/// ViewModel de la lista de edificios del delegado.
class BuildingsViewModel extends ChangeNotifier {
  BuildingsViewModel({
    required this.delegateUid,
    DatabaseService? database,
  }) : _database = database ?? DatabaseService();

  final String delegateUid;
  final DatabaseService _database;

  StreamSubscription<List<BuildingModel>>? _subscription;
  List<BuildingModel> _buildings = const [];
  bool _isLoading = true;
  String? _error;

  List<BuildingModel> get buildings => _buildings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void load() {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _database.getDelegateBuildings(delegateUid).listen(
      (buildings) {
        _buildings = buildings;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = 'No se pudieron cargar los edificios: $error';
        notifyListeners();
      },
    );
  }

  Future<bool> deleteBuilding(BuildingModel building) async {
    try {
      await _database.deleteBuilding(building.id);
      return true;
    } catch (error) {
      _error = 'No se pudo eliminar la copropiedad: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite(BuildingModel building) async {
    try {
      await _database.setBuildingFavorite(building.id, !building.isFavorite);
      return true;
    } catch (error) {
      _error = 'No se pudo actualizar el favorito: $error';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
