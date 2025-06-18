import 'package:flutter/material.dart';

class FuelCalculationRow extends StatelessWidget {
  final String label;
  final String value;

  const FuelCalculationRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 15, fontFamily: 'monospace', color: Colors.white.withValues(alpha: 0.95)),
          ),
        ),
      ],
    );
  }
}