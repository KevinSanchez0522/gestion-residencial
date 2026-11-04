import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'screens/auth/login_screen.dart';
import 'screens/delegate/delegate_home_screen.dart';
import 'screens/resident/resident_home_screen.dart';
import 'services/notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crea/abre la base de datos SQLite antes de mostrar la interfaz.
  await AppDatabase.instance.database;
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel()..restoreSession(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gestión Residencial',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apartment_rounded, size: 56, color: Colors.indigo),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final user = auth.user;
    if (user == null) return const LoginScreen();

    switch (auth.role) {
      case 'residente':
        return ResidentHomeScreen(buildingId: user.buildingId);
      case 'delegado':
        return const DelegateHomeScreen();
      case 'gerente':
        return _ManagerHomeScreen(userName: user.name);
      default:
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Rol no reconocido: "${user.role}"'),
            ),
          ),
        );
    }
  }
}

class _ManagerHomeScreen extends StatelessWidget {
  const _ManagerHomeScreen({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Gerente'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenido, $userName',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
