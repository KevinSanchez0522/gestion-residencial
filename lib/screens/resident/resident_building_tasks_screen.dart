import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/tasks_viewmodel.dart';

class ResidentBuildingTasksScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;

  const ResidentBuildingTasksScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
  });

  @override
  State<ResidentBuildingTasksScreen> createState() =>
      _ResidentBuildingTasksScreenState();
}

class _ResidentBuildingTasksScreenState
    extends State<ResidentBuildingTasksScreen> {
  late final TasksViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TasksViewModel(buildingId: widget.buildingId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showReportNovedadModal() {
    final authUser = context.read<AuthViewModel>().user;
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                Row(
                  children: [
                    const Icon(Icons.report_problem_outlined, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      'Reportar novedad - ${widget.buildingName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Describe la novedad para que el Delegado de Administración la registre y dé seguimiento.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Asunto / Novedad',
                    hintText: 'Ej. Luz del pasillo no enciende',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción detallada',
                    hintText: 'Indica ubicación, hora, detalles...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Enviar reporte al Delegado',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();

                      if (widget.buildingId.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo identificar el edificio'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (title.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debes completar asunto y descripción'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final dueDate = now.add(const Duration(hours: 2));

                      final solicitud = TaskModel(
                        id: '',
                        buildingId: widget.buildingId,
                        title: title,
                        description: desc,
                        dueDate: dueDate,
                        status: 'pendiente',
                        reminderMinutesBefore: 60,
                        type: 'solicitud',
                        reportedByUid: authUser?.uid,
                        reportedByName: authUser?.name ?? authUser?.email,
                        reportedByApartment: authUser?.apartment,
                      );

                      // Capturamos los servicios antes del await para no usar
                      // BuildContext a través de un gap asíncrono.
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      try {
                        final taskId = await _viewModel.createTask(solicitud);
                        if (taskId == null) {
                          throw _viewModel.error ??
                              'No se pudo guardar el reporte.';
                        }

                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Reporte enviado correctamente. El Delegado lo revisará.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error al enviar reporte: $e'),
                            backgroundColor: Colors.redAccent,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes / Tareas - ${widget.buildingName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_alert_outlined, color: Colors.white),
        label: const Text(
          'Reportar novedad',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: _showReportNovedadModal,
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

          final allTasks = [..._viewModel.tasks]
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          if (allTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Aún no hay solicitudes ni tareas registradas para este edificio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showReportNovedadModal,
                      icon: const Icon(Icons.add_alert_outlined),
                      label: const Text('Reportar primera novedad'),
                    )
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              final isSolicitud = task.type == 'solicitud';
              final isCompleted = task.status == 'completada';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSolicitud
                        ? Colors.orange.shade100
                        : Colors.indigo.shade100,
                    child: Icon(
                      isSolicitud
                          ? Icons.report_problem_outlined
                          : Icons.assignment_outlined,
                      color: isSolicitud ? Colors.orange.shade800 : Colors.indigo,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSolicitud
                              ? Colors.orange.shade50
                              : Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSolicitud
                                ? Colors.orange.shade200
                                : Colors.indigo.shade200,
                          ),
                        ),
                        child: Text(
                          isSolicitud ? 'SOLICITUD' : 'TAREA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSolicitud
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
                        'Estado: ${_getStatusLabel(task.status)} • ${DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      if (isSolicitud && task.reportedByName != null)
                        Text(
                          'Reportado por: ${task.reportedByName}${task.reportedByApartment != null ? " (${task.reportedByApartment})" : ""}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_proceso':
        return 'En proceso';
      case 'completada':
        return 'Completada';
      default:
        return 'Pendiente';
    }
  }
}