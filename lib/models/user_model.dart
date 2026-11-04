class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'gerente', 'delegado', 'residente'
  final String? buildingId;
  final String? apartment;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.buildingId,
    this.apartment,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'residente',
      buildingId: map['buildingId'],
      apartment: map['apartment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'buildingId': buildingId,
      'apartment': apartment,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}