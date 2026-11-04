import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/building_model.dart';
import '../../services/database_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'resident_ai_chat_screen.dart';
import 'resident_building_tasks_screen.dart';

class ResidentHomeScreen extends StatefulWidget {
  final String? buildingId;
  final String? buildingName;

  const ResidentHomeScreen({
    super.key,
    this.buildingId,
    this.buildingName,
  });

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthViewModel>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingId = widget.buildingId;

    return StreamBuilder<BuildingModel?>(
      stream: buildingId == null || buildingId.isEmpty
          ? const Stream<BuildingModel?>.empty()
          : _dbService.getBuildingStream(buildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final building = snapshot.data;
        final defaultBuildingName =
            building?.name ?? widget.buildingName ?? 'Copropiedad';
        final data = <String, dynamic>{
          'name': defaultBuildingName,
          'address': building?.address ?? 'Dirección no registrada',
          'nit': building?.nit ?? 'En trámite / No registrado',
        };

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: AppBar(
            title: Text(
              defaultBuildingName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: _signOut,
              ),
            ],
          ),
          body: _buildDashboardContent(data, defaultBuildingName),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text(
              'Asistente IA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResidentAiChatScreen(
                    buildingName: defaultBuildingName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(
    Map<String, dynamic> data,
    String defaultBuildingName,
  ) {
    // Datos del Edificio
    final String name = data['name'] ?? defaultBuildingName;
    final String address = data['address'] ?? 'Dirección no registrada';
    final String nit = data['nit'] ?? 'En trámite / No registrado';
    final String conciergePhone = data['conciergePhone'] ?? 'No disponible';

    // Datos de la Póliza de Seguro de Áreas Comunes
    final Map<String, dynamic> insurance =
        data['insurance'] as Map<String, dynamic>? ?? {};
    final String insurerName =
        insurance['company'] ?? data['insuranceCompany'] ?? 'Seguros del Estado';
    final String policyNumber =
        insurance['policyNumber'] ?? data['insurancePolicy'] ?? 'POL-99887766';
    final String policyValidity =
        insurance['validity'] ?? data['insuranceValidity'] ?? 'Ene 2026 - Ene 2027';
    final String coverages = insurance['coverages'] ??
        data['insuranceCoverages'] ??
        'Incendio, Terremoto, Responsabilidad Civil Extracontractual';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de la Copropiedad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.indigo, Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.apartment, color: Colors.white70, size: 28),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIT: $nit',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección Póliza de Seguros de Áreas Comunes
          const Text(
            'Seguros y Protección de Copropiedad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Póliza de Áreas Comunes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              insurerName,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Vigente',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'No. Póliza:',
                    value: policyNumber,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.event_available_outlined,
                    label: 'Vigencia:',
                    value: policyValidity,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.shield_outlined,
                    label: 'Amparos:',
                    value: coverages,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contactos Directos y Operación
          const Text(
            'Líneas de Atención y Contacto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.phone_in_talk, color: Colors.indigo),
                  ),
                  title: const Text(
                    'Portería / Recepción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(conciergePhone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.support_agent, color: Colors.teal),
                  ),
                  title: const Text(
                    'Delegado de Administración',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: const Text('Horario de atención: Lun a Vie 8:00 AM - 5:00 PM'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Solicitudes y Novedades
          const Text(
            'Solicitudes y Seguimiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.assignment_outlined, color: Colors.orange),
              ),
              title: const Text(
                'Solicitudes / Tareas del Edificio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              subtitle: const Text('Reportar novedad y ver seguimiento'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final bid = widget.buildingId;
                if (bid == null || bid.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No tienes un edificio asignado. Contacta al Delegado o Gerencia.',
                      ),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResidentBuildingTasksScreen(
                      buildingId: bid,
                      buildingName: defaultBuildingName,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 80), // Margen inferior para que el FAB no tape nada
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}