import 'dart:convert';

class MaintenanceEntry {
  final String id;
  final String? vehicleId;
  final String type;
  final String description;
  final double cost;
  final double? mileage;
  final DateTime dateTime;
  final String? notes;
  final double? nextDueMileage;
  final DateTime? nextDueDate;

  MaintenanceEntry({
    required this.id,
    this.vehicleId,
    required this.type,
    required this.description,
    required this.cost,
    this.mileage,
    required this.dateTime,
    this.notes,
    this.nextDueMileage,
    this.nextDueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'type': type,
        'description': description,
        'cost': cost,
        'mileage': mileage,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'nextDueMileage': nextDueMileage,
        'nextDueDate': nextDueDate?.toIso8601String(),
      };

  factory MaintenanceEntry.fromJson(Map<String, dynamic> json) =>
      MaintenanceEntry(
        id: json['id'],
        vehicleId: json['vehicleId'],
        type: json['type'] ?? 'general_service',
        description: json['description'] ?? '',
        cost: (json['cost'] ?? 0).toDouble(),
        mileage: json['mileage']?.toDouble(),
        dateTime: DateTime.parse(json['dateTime']),
        notes: json['notes'],
        nextDueMileage: json['nextDueMileage']?.toDouble(),
        nextDueDate: json['nextDueDate'] != null
            ? DateTime.parse(json['nextDueDate'])
            : null,
      );

  static List<MaintenanceEntry> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => MaintenanceEntry.fromJson(e)).toList();
  }

  static String listToJson(List<MaintenanceEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  MaintenanceEntry copyWith({
    String? vehicleId,
    String? type,
    String? description,
    double? cost,
    double? mileage,
    DateTime? dateTime,
    String? notes,
    double? nextDueMileage,
    DateTime? nextDueDate,
    bool clearVehicleId = false,
    bool clearMileage = false,
    bool clearNotes = false,
    bool clearNextDueMileage = false,
    bool clearNextDueDate = false,
  }) =>
      MaintenanceEntry(
        id: id,
        vehicleId: clearVehicleId ? null : (vehicleId ?? this.vehicleId),
        type: type ?? this.type,
        description: description ?? this.description,
        cost: cost ?? this.cost,
        mileage: clearMileage ? null : (mileage ?? this.mileage),
        dateTime: dateTime ?? this.dateTime,
        notes: clearNotes ? null : (notes ?? this.notes),
        nextDueMileage:
            clearNextDueMileage ? null : (nextDueMileage ?? this.nextDueMileage),
        nextDueDate:
            clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      );

  static const Map<String, String> maintenanceTypes = {
    'oil_change': 'Oil Change',
    'tire_rotation': 'Tire Rotation',
    'brake_service': 'Brake Service',
    'air_filter': 'Air Filter',
    'transmission': 'Transmission',
    'battery': 'Battery',
    'coolant': 'Coolant Flush',
    'spark_plugs': 'Spark Plugs',
    'belt_replacement': 'Belt Replace',
    'wheel_alignment': 'Alignment',
    'suspension': 'Suspension',
    'exhaust': 'Exhaust',
    'ac_service': 'AC Service',
    'wiper_blades': 'Wiper Blades',
    'headlights': 'Headlights',
    'car_wash': 'Car Wash',
    'detailing': 'Detailing',
    'inspection': 'Inspection',
    'insurance': 'Insurance',
    'registration': 'Registration',
    'towing': 'Towing',
    'general_service': 'General Service',
    'body_repair': 'Body Repair',
    'other': 'Other',
  };

}
