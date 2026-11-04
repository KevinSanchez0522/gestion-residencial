class TaskModel {
  final String id;
  final String buildingId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status; // 'pendiente', 'en_proceso', 'completada'
  final int reminderMinutesBefore; // Minutos antes del vencimiento
  final String type; // 'tarea' | 'solicitud'
  final String? reportedByUid;
  final String? reportedByName;
  final String? reportedByApartment;

  TaskModel({
    required this.id,
    required this.buildingId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = 'pendiente',
    this.reminderMinutesBefore = 60,
    this.type = 'tarea',
    this.reportedByUid,
    this.reportedByName,
    this.reportedByApartment,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      buildingId: map['buildingId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: _parseDate(map['dueDate']) ?? DateTime.now(),
      status: map['status'] ?? 'pendiente',
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 60,
      type: map['type'] ?? 'tarea',
      reportedByUid: map['reportedByUid'],
      reportedByName: map['reportedByName'],
      reportedByApartment: map['reportedByApartment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'reminderMinutesBefore': reminderMinutesBefore,
      'type': type,
      'reportedByUid': reportedByUid,
      'reportedByName': reportedByName,
      'reportedByApartment': reportedByApartment,
    };
  }
}