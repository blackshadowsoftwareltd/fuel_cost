import 'package:flutter/material.dart';
import 'fuel_calculation_row.dart';

class MileageCalculationCard extends StatelessWidget {
  final Map<String, dynamic> calculationDetails;
  final String Function(DateTime) formatDate;

  const MileageCalculationCard({super.key, required this.calculationDetails, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calculate, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Mileage Calculation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FuelCalculationRow(
            label: 'Distance Traveled:',
            value:
                '${calculationDetails['currentOdometer'].toStringAsFixed(0)} km - ${calculationDetails['lastOdometer'].toStringAsFixed(0)} km = ${calculationDetails['distance'].toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 12),
          FuelCalculationRow(
            label: 'Fuel Efficiency:',
            value:
                '${calculationDetails['distance'].toStringAsFixed(1)} km ÷ ${calculationDetails['liters'].toStringAsFixed(1)} L = ${calculationDetails['mileage'].toStringAsFixed(2)} km/L',
          ),
          const SizedBox(height: 12),
          Text(
            'Since last fill-up: ${formatDate(calculationDetails['lastFuelDate'])}',
            style: TextStyle(fontSize: 13, color: Colors.white, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
