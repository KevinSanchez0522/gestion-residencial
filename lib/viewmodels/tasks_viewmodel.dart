import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../services/database_service.dart';

/// ViewModel de tareas y solicitudes de un edificio.
class TasksViewModel extends ChangeNotifier {
  TasksViewModel({
    required this.buildingId,
    DatabaseService? database,
  }) : _database = database ?? DatabaseService() {
    _listen();
  }

  final String buildingId;
  final DatabaseService _database;

  StreamSubscription<List<TaskModel>>? _subscription;
  List<TaskModel> _tasks = const [];
  bool _isLoading = true;
  String? _error;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _listen() {
    _subscription = _database.getBuildingTasks(buildingId).listen(
      (tasks) {
        _tasks = tasks;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = 'No se pudieron cargar las tareas: $error';
        notifyListeners();
      },
    );
  }

  Future<String?> createTask(TaskModel task) async {
    try {
      return await _database.createTask(task);
    } catch (error) {
      _error = 'No se pudo guardar la tarea: $error';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateStatus(TaskModel task, String status) async {
    try {
      await _database.updateTaskStatus(task.id, status);
      return true;
    } catch (error) {
      _error = 'No se pudo actualizar la tarea: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(TaskModel task) async {
    try {
      await _database.deleteTask(task.id);
      return true;
    } catch (error) {
      _error = 'No se pudo eliminar la tarea: $error';
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
