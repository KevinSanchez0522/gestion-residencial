import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/user_model.dart';

/// Error controlado de autenticación para mostrar mensajes claros en la UI.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Autenticación local.
///
/// Las contraseñas se guardan como hash SHA-256 con una sal aleatoria por
/// usuario. La sesión se conserva en SharedPreferences para que el usuario no
/// tenga que iniciar sesión cada vez que abre la aplicación.
class AuthService {
  AuthService({AppDatabase? database})
      : _appDb = database ?? AppDatabase.instance;

  final AppDatabase _appDb;
  final Random _random = Random.secure();

  static const String _sessionKey = 'session_uid';

  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    if (uid == null) return null;

    final db = await _appDb.database;
    final rows = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (rows.isEmpty) {
      await prefs.remove(_sessionKey);
      return null;
    }

    return _userFromRow(rows.first);
  }

  Future<UserModel> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await _appDb.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AuthException('No existe una cuenta con ese correo.');
    }

    final row = rows.first;
    final salt = row['salt'] as String;
    final passwordHash = row['password_hash'] as String;

    if (_hashPassword(password, salt) != passwordHash) {
      throw const AuthException('Contraseña incorrecta.');
    }

    final user = _userFromRow(row);
    await _saveSession(user.uid);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? buildingInput,
    String? apartment,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      throw const AuthException('El nombre es obligatorio.');
    }
    if (!_isValidEmail(normalizedEmail)) {
      throw const AuthException('El correo electrónico no es válido.');
    }
    if (password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres.');
    }

    const allowedRoles = {'gerente', 'delegado', 'residente'};
    if (!allowedRoles.contains(role)) {
      throw const AuthException('El rol seleccionado no es válido.');
    }

    String? buildingId;
    String? normalizedApartment;

    if (role == 'residente') {
      final input = buildingInput?.trim() ?? '';
      if (input.isEmpty) {
        throw const AuthException('Ingresa el edificio al que perteneces.');
      }
      if ((apartment?.trim() ?? '').isEmpty) {
        throw const AuthException('Ingresa tu apartamento.');
      }

      buildingId = await resolveBuildingId(input);
      if (buildingId == null) {
        throw const AuthException(
          'No existe un edificio con ese nombre o código. Verifica el dato.',
        );
      }
      normalizedApartment = apartment!.trim();
    }

    final uid = _generateUid();
    final salt = _generateSalt();
    final db = await _appDb.database;

    try {
      await db.insert('users', {
        'uid': uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'password_hash': _hashPassword(password, salt),
        'salt': salt,
        'role': role,
        'building_id': buildingId,
        'apartment': normalizedApartment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AuthException('Ya existe una cuenta con ese correo.');
      }
      rethrow;
    }

    final user = UserModel(
      uid: uid,
      email: normalizedEmail,
      name: normalizedName,
      role: role,
      buildingId: buildingId,
      apartment: normalizedApartment,
    );
    await _saveSession(uid);
    return user;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Busca un edificio por id exacto, nombre exacto o coincidencia parcial.
  Future<String?> resolveBuildingId(String input) async {
    final value = input.trim();
    if (value.isEmpty) return null;

    final db = await _appDb.database;

    final byId = await db.query(
      'buildings',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [value],
      limit: 1,
    );
    if (byId.isNotEmpty) return byId.first['id'] as String;

    final byExactName = await db.query(
      'buildings',
      columns: ['id'],
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [value],
      limit: 1,
    );
    if (byExactName.isNotEmpty) return byExactName.first['id'] as String;

    final byPartialName = await db.query(
      'buildings',
      columns: ['id'],
      where: 'name LIKE ? COLLATE NOCASE',
      whereArgs: ['%$value%'],
      orderBy: 'name COLLATE NOCASE ASC',
      limit: 1,
    );
    if (byPartialName.isNotEmpty) return byPartialName.first['id'] as String;

    return null;
  }

  Future<void> _saveSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, uid);
  }

  UserModel _userFromRow(Map<String, Object?> row) {
    return UserModel(
      uid: row['uid'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      role: row['role'] as String,
      buildingId: row['building_id'] as String?,
      apartment: row['apartment'] as String?,
    );
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _generateUid() {
    return 'usr_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999999)}';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
