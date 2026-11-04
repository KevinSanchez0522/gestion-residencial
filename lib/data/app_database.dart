import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos local SQLite de la aplicación.
///
/// Centraliza la creación del esquema y la conexión. La app funciona sin
/// Firebase: usuarios, edificios, apartamentos y tareas viven en el dispositivo.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'delegado_local.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Necesario para que los borrados en cascada de SQLite funcionen.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        building_id TEXT,
        apartment TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE buildings (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL DEFAULT '',
        nit TEXT NOT NULL DEFAULT '',
        bank_account TEXT NOT NULL DEFAULT '',
        delegate_uid TEXT,
        is_automated INTEGER NOT NULL DEFAULT 0,
        elevators_count INTEGER NOT NULL DEFAULT 0,
        has_electric_doors INTEGER NOT NULL DEFAULT 0,
        has_generator INTEGER NOT NULL DEFAULT 0,
        has_pressure_pumps INTEGER NOT NULL DEFAULT 0,
        has_janitor INTEGER NOT NULL DEFAULT 0,
        elevator_certification_date TEXT,
        fire_extinguisher_refill_date TEXT,
        pump_maintenance_date TEXT,
        generator_maintenance_date TEXT,
        elevator_maintenance_company TEXT NOT NULL DEFAULT '',
        certification_company TEXT NOT NULL DEFAULT '',
        electric_doors_company TEXT NOT NULL DEFAULT '',
        cleaning_company TEXT NOT NULL DEFAULT '',
        security_company TEXT NOT NULL DEFAULT '',
        gardening_company TEXT NOT NULL DEFAULT '',
        staff_json TEXT NOT NULL DEFAULT '[]',
        council_json TEXT NOT NULL DEFAULT '[]',
        apartments_count INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_buildings_delegate
      ON buildings(delegate_uid)
    ''');

    await db.execute('''
      CREATE TABLE apartments (
        id TEXT NOT NULL,
        building_id TEXT NOT NULL,
        nomenclature TEXT NOT NULL,
        has_children INTEGER NOT NULL DEFAULT 0,
        children_count INTEGER NOT NULL DEFAULT 0,
        occupants_json TEXT NOT NULL DEFAULT '[]',
        PRIMARY KEY (building_id, id),
        FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_apartments_building
      ON apartments(building_id)
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        building_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendiente',
        reminder_minutes_before INTEGER NOT NULL DEFAULT 60,
        type TEXT NOT NULL DEFAULT 'tarea',
        reported_by_uid TEXT,
        reported_by_name TEXT,
        reported_by_apartment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_building
      ON tasks(building_id)
    ''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
