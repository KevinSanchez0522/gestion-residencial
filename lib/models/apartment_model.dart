class ResidentPerson {
  final String fullName;
  final String documentId;
  final String phone;
  final String email;
  final String type; // 'propietario', 'residente', 'inquilino'

  ResidentPerson({
    required this.fullName,
    required this.documentId,
    required this.phone,
    required this.email,
    required this.type,
  });

  factory ResidentPerson.fromMap(Map<String, dynamic> map) => ResidentPerson(
        fullName: map['fullName'] ?? '',
        documentId: map['documentId'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        type: map['type'] ?? 'residente',
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'documentId': documentId,
        'phone': phone,
        'email': email,
        'type': type,
      };
}

class ApartmentModel {
  final String id; // Nomenclatura (ej: "Apt 201", "Torre 1 - 302")
  final String nomenclature;
  final bool hasChildren;
  final int childrenCount;
  final List<ResidentPerson> occupants;

  ApartmentModel({
    required this.id,
    required this.nomenclature,
    this.hasChildren = false,
    this.childrenCount = 0,
    this.occupants = const [],
  });

  factory ApartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return ApartmentModel(
      id: id,
      nomenclature: map['nomenclature'] ?? id,
      hasChildren: map['hasChildren'] ?? false,
      childrenCount: map['childrenCount'] ?? 0,
      occupants: (map['occupants'] as List<dynamic>? ?? [])
          .map((p) => ResidentPerson.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nomenclature': nomenclature,
        'hasChildren': hasChildren,
        'childrenCount': childrenCount,
        'occupants': occupants.map((p) => p.toMap()).toList(),
      };
}