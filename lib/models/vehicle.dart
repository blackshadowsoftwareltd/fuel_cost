import 'dart:convert';

class Vehicle {
  final String id;
  final String name;
  final String iconName;
  final String fuelType; // petrol, diesel, cng, electric
  final double? tankCapacity;

  Vehicle({
    required this.id,
    required this.name,
    this.iconName = 'directions_car',
    this.fuelType = 'petrol',
    this.tankCapacity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'fuelType': fuelType,
        'tankCapacity': tankCapacity,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'],
        name: json['name'],
        iconName: json['iconName'] ?? 'directions_car',
        fuelType: json['fuelType'] ?? 'petrol',
        tankCapacity: json['tankCapacity']?.toDouble(),
      );

  static List<Vehicle> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => Vehicle.fromJson(e)).toList();
  }

  static String listToJson(List<Vehicle> vehicles) {
    return jsonEncode(vehicles.map((v) => v.toJson()).toList());
  }

  Vehicle copyWith({
    String? name,
    String? iconName,
    String? fuelType,
    double? tankCapacity,
    bool clearTankCapacity = false,
  }) =>
      Vehicle(
        id: id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        fuelType: fuelType ?? this.fuelType,
        tankCapacity: clearTankCapacity ? null : (tankCapacity ?? this.tankCapacity),
      );

  static const Map<String, String> fuelTypes = {
    'petrol': 'Petrol',
    'diesel': 'Diesel',
    'cng': 'CNG',
    'electric': 'Electric',
    'hybrid': 'Hybrid',
  };

  static const Map<String, IconInfo> vehicleIcons = {
    'directions_car': IconInfo('Car', 0xe1d7),
    'two_wheeler': IconInfo('Bike', 0xf23e),
    'local_shipping': IconInfo('Truck', 0xe401),
    'airport_shuttle': IconInfo('Van', 0xe19c),
    'electric_car': IconInfo('Electric Car', 0xeb1c),
    'pedal_bike': IconInfo('Bicycle', 0xeb29),
  };
}

class IconInfo {
  final String label;
  final int codePoint;
  const IconInfo(this.label, this.codePoint);
}
