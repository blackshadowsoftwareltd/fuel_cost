class FuelEntry {
  final String id;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final DateTime dateTime;
  final double? odometerReading;

  FuelEntry({
    required this.id,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.dateTime,
    this.odometerReading,
  });

  factory FuelEntry.create({
    required double liters,
    required double pricePerLiter,
    double? odometerReading,
  }) {
    return FuelEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalCost: liters * pricePerLiter,
      dateTime: DateTime.now(),
      odometerReading: odometerReading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'dateTime': dateTime.toIso8601String(),
      'odometerReading': odometerReading,
    };
  }

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'],
      liters: json['liters'],
      pricePerLiter: json['pricePerLiter'],
      totalCost: json['totalCost'],
      dateTime: DateTime.parse(json['dateTime']),
      odometerReading: json['odometerReading']?.toDouble(),
    );
  }

  static double? calculateMileage(FuelEntry current, FuelEntry previous) {
    if (current.odometerReading == null || previous.odometerReading == null) {
      return null;
    }
    
    final distance = current.odometerReading! - previous.odometerReading!;
    if (distance <= 0) return null;
    
    return distance / current.liters;
  }
}