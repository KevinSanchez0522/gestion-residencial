import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/building_model.dart';
import '../../models/task_model.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/tasks_viewmodel.dart';

class BuildingTasksScreen extends StatefulWidget {
  final BuildingModel building;

  const BuildingTasksScreen({super.key, required this.building});

  @override
  State<BuildingTasksScreen> createState() => _BuildingTasksScreenState();
}

class _BuildingTasksScreenState extends State<BuildingTasksScreen> {
  final NotificationService _notificationService = NotificationService();
  late final TasksViewModel _viewModel;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _viewModel = TasksViewModel(buildingId: widget.building.id);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Comprueba si dos fechas corresponden al mismo día
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showCreateTaskModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime taskDate = _selectedDay ?? DateTime.now();
    TimeOfDay taskTime = TimeOfDay.now();
    int reminderOffset = 60; // Minutos antes (1 hora por defecto)

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva Tarea - ${widget.building.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la tarea',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Proveedor / Detalle',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selector de Hora
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      leading: const Icon(Icons.access_time, color: Colors.indigo),
                      title: Text('Hora: ${taskTime.format(context)}'),
                      trailing: const Text('Cambiar', style: TextStyle(color: Colors.indigo)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: taskTime,
                        );
                        if (picked != null) {
                          setModalState(() => taskTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Selector de Recordatorio
                    DropdownButtonFormField<int>(
                      initialValue: reminderOffset,
                      decoration: const InputDecoration(
                        labelText: 'Cuándo notificar',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notifications_active_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                        DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                        DropdownMenuItem(value: 1440, child: Text('1 día antes')),
                        DropdownMenuItem(value: 2880, child: Text('2 días antes')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => reminderOffset = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Programar Tarea', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Debes ingresar un título para la tarea'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            return;
                          }

                          final fullDateTime = DateTime(
                            taskDate.year,
                            taskDate.month,
                            taskDate.day,
                            taskTime.hour,
                            taskTime.minute,
                          );

                          final newTask = TaskModel(
                            id: '',
                            buildingId: widget.building.id,
                            title: title,
                            description: descController.text.trim(),
                            dueDate: fullDateTime,
                            reminderMinutesBefore: reminderOffset,
                            type: 'tarea',
                          );

                          // 1. Guardar en SQLite y obtener ID
                          final taskId = await _viewModel.createTask(newTask);

                          if (taskId == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _viewModel.error ??
                                        'No se pudo guardar la tarea',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          // 2. Programar Notificación Local
                          final notifyAt = fullDateTime
                              .subtract(Duration(minutes: reminderOffset));
                          final notificationId = taskId.hashCode;

                          await _notificationService.scheduleTaskNotification(
                            id: notificationId,
                            title: 'Tarea próxima: ${widget.building.name}',
                            body:
                                '$title programada para las ${DateFormat.jm().format(fullDateTime)}',
                            scheduledDate: notifyAt,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tarea creada y notificación programada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Seguro que deseas eliminar "${task.title}"?\n\n'
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

    final success = await _viewModel.deleteTask(task);
    if (success) {
      // La tarea ya no existe: cancelar su recordatorio si estaba programado.
      try {
        await _notificationService.cancelNotification(task.id.hashCode);
      } catch (_) {
        // No bloquear la eliminación si falla la cancelación local.
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${task.title}" eliminada correctamente'
              : _viewModel.error ?? 'No se pudo eliminar la tarea',
        ),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tareas: ${widget.building.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.error != null && _viewModel.tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _viewModel.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final allTasks = _viewModel.tasks;

          // Filtrar tareas que coinciden con el día seleccionado en el calendario
          final selectedTasks = allTasks.where((task) {
            return _selectedDay != null && _isSameDay(task.dueDate, _selectedDay!);
          }).toList();

          return Column(
            children: [
              // Calendario interactivo
              TableCalendar(
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  return allTasks.where((t) => _isSameDay(t.dueDate, day)).toList();
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                ),
              ),
              const Divider(),
              // Lista de tareas del día seleccionado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDay != null
                          ? 'Tareas: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'
                          : 'Selecciona una fecha',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text('${selectedTasks.length} registradas', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No hay tareas programadas para este día.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          final task = selectedTasks[index];
                          final isCompleted = task.status == 'completada';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isCompleted ? Colors.green : Colors.grey,
                                ),
                                onPressed: () async {
                                  final newStatus =
                                      isCompleted ? 'pendiente' : 'completada';
                                  final success = await _viewModel.updateStatus(
                                    task,
                                    newStatus,
                                  );

                                  if (success && newStatus == 'completada') {
                                    await _notificationService
                                        .cancelNotification(task.id.hashCode);
                                  } else if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _viewModel.error ??
                                              'No se pudo actualizar la tarea',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: task.type == 'solicitud'
                                          ? Colors.orange.shade50
                                          : Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: task.type == 'solicitud'
                                            ? Colors.orange.shade200
                                            : Colors.indigo.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      task.type == 'solicitud' ? 'SOLICITUD' : 'TAREA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: task.type == 'solicitud'
                                            ? Colors.orange.shade800
                                            : Colors.indigo.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(task.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hora: ${DateFormat.jm().format(task.dueDate)} • Recordatorio: ${task.reminderMinutesBefore >= 1440 ? '${task.reminderMinutesBefore ~/ 1440} día(s) antes' : '${task.reminderMinutesBefore} min antes'}',
                                    style: TextStyle(
                                        color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                  if (task.type == 'solicitud' &&
                                      task.reportedByName != null)
                                    Text(
                                      'Reportado por: ${task.reportedByName}${task.reportedByApartment != null ? " - Apto: ${task.reportedByApartment}" : ""}',
                                      style: TextStyle(
                                          color: Colors.grey.shade700, fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Eliminar tarea',
                                onPressed: () => _confirmDeleteTask(task),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text('Crear Tarea', style: TextStyle(color: Colors.white)),
        onPressed: _showCreateTaskModal,
      ),
    );
  }
}