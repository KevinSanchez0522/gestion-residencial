import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/apartment_model.dart';
import '../models/building_model.dart';
import '../services/database_service.dart';

/// ViewModel del detalle de una copropiedad y sus apartamentos.
class BuildingDetailViewModel extends ChangeNotifier {
  BuildingDetailViewModel({
    required this.buildingId,
    BuildingModel? initialBuilding,
    DatabaseService? database,
  })  : _building = initialBuilding,
        _database = database ?? DatabaseService() {
    _listen();
  }

  final String buildingId;
  final DatabaseService _database;

  StreamSubscription<BuildingModel?>? _buildingSubscription;
  StreamSubscription<List<ApartmentModel>>? _apartmentSubscription;

  BuildingModel? _building;
  List<ApartmentModel> _apartments = const [];
  bool _isLoadingApartments = true;
  String? _error;

  BuildingModel? get building => _building;
  List<ApartmentModel> get apartments => _apartments;
  bool get isLoadingBuilding => _building == null;
  bool get isLoadingApartments => _isLoadingApartments;
  String? get error => _error;

  void _listen() {
    _buildingSubscription = _database.getBuildingStream(buildingId).listen(
      (building) {
        if (building != null) {
          _building = building;
          _error = null;
          notifyListeners();
        }
      },
      onError: (Object error) {
        _error = 'No se pudo cargar la copropiedad: $error';
        notifyListeners();
      },
    );

    _apartmentSubscription = _database.getBuildingApartments(buildingId).listen(
      (apartments) {
        _apartments = apartments;
        _isLoadingApartments = false;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoadingApartments = false;
        _error = 'No se pudieron cargar los apartamentos: $error';
        notifyListeners();
      },
    );
  }

  Future<bool> toggleFavorite() async {
    final current = _building;
    if (current == null) return false;

    try {
      _building = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
      await _database.setBuildingFavorite(buildingId, _building!.isFavorite);
      return true;
    } catch (error) {
      _building = current;
      _error = 'No se pudo actualizar el favorito: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBuilding() async {
    try {
      await _database.deleteBuilding(buildingId);
      return true;
    } catch (error) {
      _error = 'No se pudo eliminar la copropiedad: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addApartment(ApartmentModel apartment) async {
    try {
      await _database.saveApartment(buildingId, apartment);
      return true;
    } catch (error) {
      _error = 'No se pudo guardar el apartamento: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameApartment({
    required String oldApartmentId,
    required ApartmentModel updatedApartment,
  }) async {
    try {
      await _database.renameApartment(
        buildingId: buildingId,
        oldApartmentId: oldApartmentId,
        newApartment: updatedApartment,
      );
      return true;
    } catch (error) {
      _error = 'No se pudo actualizar el apartamento: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteApartment(ApartmentModel apartment) async {
    try {
      await _database.deleteApartment(buildingId, apartment.id);
      return true;
    } catch (error) {
      _error = 'No se pudo eliminar el apartamento: $error';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _buildingSubscription?.cancel();
    _apartmentSubscription?.cancel();
    super.dispose();
  }
}
