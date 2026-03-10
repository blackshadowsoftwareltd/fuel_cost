import '../models/fuel_entry.dart';

class FuelCalculations {
  /// Calculate mileage metrics:
  /// - Fuel at entry i is consumed between entry i and entry i+1
  /// - Per trip (i to i+1): (odo[i+1] - odo[i]) / liters[i]
  /// - Last entry fuel is excluded (not yet consumed)
  /// - Overall: total distance / (total fuel - last entry fuel)
  static Map<String, double> calculateMileageMetrics(
    List<FuelEntry> entries,
    double totalLiters,
  ) {
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    double lastTripMileage = 0.0;
    double overallMileage = 0.0;
    double totalDistance = 0.0;
    double maxMileage = 0.0;
    double minMileage = double.infinity;

    if (sortedEntries.length > 1) {
      final tripMileages = <double>[];

      for (int i = 1; i < sortedEntries.length; i++) {
        if (sortedEntries[i].odometerReading != null &&
            sortedEntries[i - 1].odometerReading != null) {
          final distance = sortedEntries[i].odometerReading! -
                          sortedEntries[i - 1].odometerReading!;
          if (distance > 0) {
            totalDistance += distance;
            // Fuel at entry i-1 was consumed during this trip
            final tripMileage = distance / sortedEntries[i - 1].liters;
            tripMileages.add(tripMileage);
          }
        }
      }

      if (totalDistance > 0) {
        if (tripMileages.isNotEmpty) {
          maxMileage = tripMileages.reduce((a, b) => a > b ? a : b);
          minMileage = tripMileages.reduce((a, b) => a < b ? a : b);
        }

        // Last trip mileage
        if (sortedEntries.length >= 2) {
          final lastEntry = sortedEntries.last;
          final secondLastEntry = sortedEntries[sortedEntries.length - 2];

          if (lastEntry.odometerReading != null &&
              secondLastEntry.odometerReading != null) {
            final lastTripDistance = lastEntry.odometerReading! -
                                   secondLastEntry.odometerReading!;
            if (lastTripDistance > 0) {
              lastTripMileage = lastTripDistance / secondLastEntry.liters;
            }
          }
        }

        // Overall: total distance / (total fuel - last entry fuel)
        // Last entry fuel hasn't been consumed yet
        final totalFuelExcludingLast = totalLiters - sortedEntries.last.liters;
        if (totalFuelExcludingLast > 0) {
          overallMileage = totalDistance / totalFuelExcludingLast;
        }
      }
    }

    if (minMileage == double.infinity) {
      minMileage = 0.0;
    }

    return {
      'lastTripMileage': lastTripMileage,
      'overallMileage': overallMileage,
      'totalDistance': totalDistance,
      'maxMileage': maxMileage,
      'minMileage': minMileage,
    };
  }

  /// Calculate efficiency chart data using cumulative mileage
  static List<double> calculateEfficiencyChartData(List<FuelEntry> entries) {
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final chartData = <double>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i > 0) {
        double totalDistance = 0;
        for (int j = 1; j <= i; j++) {
          if (sortedEntries[j].odometerReading != null &&
              sortedEntries[j - 1].odometerReading != null) {
            final distance = sortedEntries[j].odometerReading! -
                           sortedEntries[j - 1].odometerReading!;
            if (distance > 0) {
              totalDistance += distance;
            }
          }
        }

        // Total fuel up to this point, minus last entry (not yet consumed)
        double totalFuel = 0;
        for (int j = 0; j <= i; j++) {
          totalFuel += sortedEntries[j].liters;
        }
        final totalFuelMinusLast = totalFuel - sortedEntries[i].liters;

        final mileage = totalFuelMinusLast > 0 ? totalDistance / totalFuelMinusLast : 0.0;
        chartData.add(mileage);
      } else {
        chartData.add(0);
      }
    }

    return chartData;
  }

  /// Calculate total distance from all entries
  static double calculateTotalDistance(List<FuelEntry> entries) {
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    double totalDistance = 0.0;
    
    for (int i = 1; i < sortedEntries.length; i++) {
      if (sortedEntries[i].odometerReading != null && 
          sortedEntries[i - 1].odometerReading != null) {
        final distance = sortedEntries[i].odometerReading! - 
                        sortedEntries[i - 1].odometerReading!;
        if (distance > 0) {
          totalDistance += distance;
        }
      }
    }
    
    return totalDistance;
  }
}