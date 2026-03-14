import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

part 'fuel_entry.g.dart';

const _uuid = Uuid();

@collection
class FuelEntry {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late double liters;
  late double pricePerLiter;
  late double totalCost;
  late DateTime dateTime;
  double? odometerReading;

  FuelEntry();

  factory FuelEntry.create({
    required double liters,
    required double pricePerLiter,
    double? odometerReading,
  }) {
    return FuelEntry()
      ..id = _uuid.v4()
      ..liters = liters
      ..pricePerLiter = pricePerLiter
      ..totalCost = liters * pricePerLiter
      ..dateTime = DateTime.now()
      ..odometerReading = odometerReading;
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
    return FuelEntry()
      ..id = json['id']
      ..liters = (json['liters'] as num).toDouble()
      ..pricePerLiter = (json['pricePerLiter'] as num).toDouble()
      ..totalCost = (json['totalCost'] as num).toDouble()
      ..dateTime = DateTime.parse(json['dateTime'])
      ..odometerReading = json['odometerReading'] != null
          ? (json['odometerReading'] as num).toDouble()
          : null;
  }

  static double? calculateMileage(FuelEntry current, FuelEntry previous) {
    if (current.odometerReading == null || previous.odometerReading == null) {
      return null;
    }

    final distance = current.odometerReading! - previous.odometerReading!;
    if (distance <= 0) return null;

    // Fuel at previous entry was consumed during the trip from previous to current
    return distance / previous.liters;
  }
}
