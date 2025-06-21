import '../models/fuel_entry.dart';

class FuelCalculations {
  /// Calculate mileage metrics using the corrected logic:
  /// - Get ALL distance
  /// - Get total fuel in liters, then minus the last entry fuel
  /// - Calculate mileage: all distance / (total fuel - last entry)
  static Map<String, double> calculateMileageMetrics(
    List<FuelEntry> entries,
    double totalLiters,
  ) {
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    double lastTripMileage = 0.0;
    double overallMileage = 0.0;
    double totalDistance = 0.0;
    
    if (sortedEntries.length > 1) {
      // Get ALL distance
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

      if (totalDistance > 0) {
        // Last trip mileage: distance of last trip / (fuel consumed - skip last entry fuel)
        if (sortedEntries.length >= 2) {
          final lastEntry = sortedEntries.last;
          final secondLastEntry = sortedEntries[sortedEntries.length - 2];
          
          if (lastEntry.odometerReading != null && 
              secondLastEntry.odometerReading != null) {
            final lastTripDistance = lastEntry.odometerReading! - 
                                   secondLastEntry.odometerReading!;
            if (lastTripDistance > 0) {
              // Skip the last entry fuel, use the second last entry fuel for this trip
              lastTripMileage = lastTripDistance / secondLastEntry.liters;
            }
          }
        }

        // Overall mileage: total distance / (total fuel - last entry fuel)
        final totalFuelExcludingLast = totalLiters - sortedEntries.last.liters;
        if (totalFuelExcludingLast > 0) {
          overallMileage = totalDistance / totalFuelExcludingLast;
        }
      }
    }
    
    return {
      'lastTripMileage': lastTripMileage,
      'overallMileage': overallMileage,
      'totalDistance': totalDistance,
    };
  }

  /// Calculate efficiency chart data using corrected mileage logic
  static List<double> calculateEfficiencyChartData(List<FuelEntry> entries) {
    final sortedEntries = List<FuelEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    final chartData = <double>[];
    
    for (int i = 0; i < sortedEntries.length; i++) {
      if (i > 0) {
        // Get ALL distance up to this point
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
        
        // Get total fuel up to this point, then minus the last entry
        double totalFuel = 0;
        for (int j = 0; j <= i; j++) {
          totalFuel += sortedEntries[j].liters;
        }
        // Minus the last entry fuel (which is the current entry in the loop)
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