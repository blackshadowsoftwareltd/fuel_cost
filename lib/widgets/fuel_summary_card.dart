import 'package:flutter/material.dart';

class FuelSummaryCard extends StatelessWidget {
  final String currency;
  final double liters;
  final double pricePerLiter;
  final double? estimatedMileage;

  const FuelSummaryCard({
    super.key,
    required this.currency,
    required this.liters,
    required this.pricePerLiter,
    this.estimatedMileage,
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = liters * pricePerLiter;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Fill-up Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Cost', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '$currency${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (estimatedMileage != null) ...[
                Container(width: 1, height: 20, color: Colors.white30),
                Column(
                  children: [
                    const Text('Mileage', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${estimatedMileage!.toStringAsFixed(1)} km/L',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
