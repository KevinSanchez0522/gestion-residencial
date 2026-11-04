class BuildingModel {
  final String id;
  final String name;
  final String address;
  final String nit;
  final String bankAccount;
  final String? delegateUid;

  // Aspectos Técnicos y Equipos
  final bool isAutomated;
  final int elevatorsCount;
  final bool hasElectricDoors;
  final bool hasGenerator;
  final bool hasPressurePumps;
  final bool hasJanitor;

  // Fechas Clave
  final DateTime? elevatorCertificationDate;
  final DateTime? fireExtinguisherRefillDate;
  final DateTime? pumpMaintenanceDate;
  final DateTime? generatorMaintenanceDate;

  // Proveedores y Empresas
  final String elevatorMaintenanceCompany;
  final String certificationCompany;
  final String electricDoorsCompany;
  final String cleaningCompany;
  final String securityCompany;
  final String gardeningCompany;

  // Listas de Personal y Consejo
  final List<StaffMember> staff;
  final List<CouncilMember> councilMembers;

  // Configuración
  final int apartmentsCount;

  // Preferencia local del delegado
  final bool isFavorite;

  BuildingModel({
    required this.id,
    required this.name,
    required this.address,
    required this.nit,
    required this.bankAccount,
    this.delegateUid,
    this.isAutomated = false,
    this.elevatorsCount = 0,
    this.hasElectricDoors = false,
    this.hasGenerator = false,
    this.hasPressurePumps = false,
    this.hasJanitor = false,
    this.elevatorCertificationDate,
    this.fireExtinguisherRefillDate,
    this.pumpMaintenanceDate,
    this.generatorMaintenanceDate,
    this.elevatorMaintenanceCompany = '',
    this.certificationCompany = '',
    this.electricDoorsCompany = '',
    this.cleaningCompany = '',
    this.securityCompany = '',
    this.gardeningCompany = '',
    this.staff = const [],
    this.councilMembers = const [],
    this.apartmentsCount = 0,
    this.isFavorite = false,
  });

  factory BuildingModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return BuildingModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      nit: map['nit'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
      delegateUid: map['delegateUid'],
      isAutomated: map['isAutomated'] as bool? ?? false,
      elevatorsCount: (map['elevatorsCount'] as num?)?.toInt() ?? 0,
      hasElectricDoors: map['hasElectricDoors'] as bool? ?? false,
      hasGenerator: map['hasGenerator'] as bool? ?? false,
      hasPressurePumps: map['hasPressurePumps'] as bool? ?? false,
      hasJanitor: map['hasJanitor'] as bool? ?? false,
      elevatorCertificationDate: parseDate(map['elevatorCertificationDate']),
      fireExtinguisherRefillDate: parseDate(map['fireExtinguisherRefillDate']),
      pumpMaintenanceDate: parseDate(map['pumpMaintenanceDate']),
      generatorMaintenanceDate: parseDate(map['generatorMaintenanceDate']),
      elevatorMaintenanceCompany: map['elevatorMaintenanceCompany'] ?? '',
      certificationCompany: map['certificationCompany'] ?? '',
      electricDoorsCompany: map['electricDoorsCompany'] ?? '',
      cleaningCompany: map['cleaningCompany'] ?? '',
      securityCompany: map['securityCompany'] ?? '',
      gardeningCompany: map['gardeningCompany'] ?? '',
      staff: (map['staff'] as List<dynamic>? ?? []).map((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        return StaffMember.fromMap(itemMap);
      }).toList(),
      councilMembers: (map['councilMembers'] as List<dynamic>? ?? []).map((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        return CouncilMember.fromMap(itemMap);
      }).toList(),
      apartmentsCount: (map['apartmentsCount'] as num?)?.toInt() ?? 0,
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  BuildingModel copyWith({
    String? id,
    String? name,
    String? address,
    String? nit,
    String? bankAccount,
    String? delegateUid,
    bool? isAutomated,
    int? elevatorsCount,
    bool? hasElectricDoors,
    bool? hasGenerator,
    bool? hasPressurePumps,
    bool? hasJanitor,
    DateTime? elevatorCertificationDate,
    DateTime? fireExtinguisherRefillDate,
    DateTime? pumpMaintenanceDate,
    DateTime? generatorMaintenanceDate,
    String? elevatorMaintenanceCompany,
    String? certificationCompany,
    String? electricDoorsCompany,
    String? cleaningCompany,
    String? securityCompany,
    String? gardeningCompany,
    List<StaffMember>? staff,
    List<CouncilMember>? councilMembers,
    int? apartmentsCount,
    bool? isFavorite,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      nit: nit ?? this.nit,
      bankAccount: bankAccount ?? this.bankAccount,
      delegateUid: delegateUid ?? this.delegateUid,
      isAutomated: isAutomated ?? this.isAutomated,
      elevatorsCount: elevatorsCount ?? this.elevatorsCount,
      hasElectricDoors: hasElectricDoors ?? this.hasElectricDoors,
      hasGenerator: hasGenerator ?? this.hasGenerator,
      hasPressurePumps: hasPressurePumps ?? this.hasPressurePumps,
      hasJanitor: hasJanitor ?? this.hasJanitor,
      elevatorCertificationDate:
          elevatorCertificationDate ?? this.elevatorCertificationDate,
      fireExtinguisherRefillDate:
          fireExtinguisherRefillDate ?? this.fireExtinguisherRefillDate,
      pumpMaintenanceDate: pumpMaintenanceDate ?? this.pumpMaintenanceDate,
      generatorMaintenanceDate:
          generatorMaintenanceDate ?? this.generatorMaintenanceDate,
      elevatorMaintenanceCompany:
          elevatorMaintenanceCompany ?? this.elevatorMaintenanceCompany,
      certificationCompany: certificationCompany ?? this.certificationCompany,
      electricDoorsCompany:
          electricDoorsCompany ?? this.electricDoorsCompany,
      cleaningCompany: cleaningCompany ?? this.cleaningCompany,
      securityCompany: securityCompany ?? this.securityCompany,
      gardeningCompany: gardeningCompany ?? this.gardeningCompany,
      staff: staff ?? this.staff,
      councilMembers: councilMembers ?? this.councilMembers,
      apartmentsCount: apartmentsCount ?? this.apartmentsCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class StaffMember {
  final String name;
  final String role;
  final String schedule;
  final String phone;

  StaffMember({
    required this.name,
    required this.role,
    required this.schedule,
    this.phone = '',
  });

  factory StaffMember.fromMap(Map<String, dynamic> map) => StaffMember(
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        schedule: map['schedule'] ?? '',
        phone: map['phone'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'schedule': schedule,
        'phone': phone,
      };
}

class CouncilMember {
  final String name;
  final String position;
  final String apartment;
  final String phone;

  CouncilMember({
    required this.name,
    required this.position,
    required this.apartment,
    this.phone = '',
  });

  factory CouncilMember.fromMap(Map<String, dynamic> map) => CouncilMember(
        name: map['name'] ?? '',
        position: map['position'] ?? '',
        apartment: map['apartment'] ?? '',
        phone: map['phone'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'position': position,
        'apartment': apartment,
        'phone': phone,
      };
}