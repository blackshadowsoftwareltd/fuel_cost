import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fuel_entry.dart';

class FuelEntryCard extends StatelessWidget {
  final FuelEntry entry;
  final String currency;
  final VoidCallback onDelete;
  final int index;
  final Animation<double> animation;

  const FuelEntryCard({
    super.key,
    required this.entry,
    required this.currency,
    required this.onDelete,
    required this.index,
    required this.animation,
  });

  List<Widget> _buildWideLayout(
    FuelEntry entry,
    ColorScheme colorScheme,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station_rounded, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${entry.liters.toStringAsFixed(2)} Liters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$currency${entry.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      dateFormatter.format(entry.dateTime),
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      timeFormatter.format(entry.dateTime),
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$currency${entry.pricePerLiter.toStringAsFixed(2)} per liter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (entry.odometerReading != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'Odometer: ${entry.odometerReading!.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildNarrowLayout(
    FuelEntry entry,
    ColorScheme colorScheme,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_gas_station_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '${entry.liters.toStringAsFixed(2)}L',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currency${entry.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                dateFormatter.format(entry.dateTime),
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                timeFormatter.format(entry.dateTime),
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.attach_money_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                '$currency${entry.pricePerLiter.toStringAsFixed(2)} per liter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (entry.odometerReading != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.speed_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Odometer: ${entry.odometerReading!.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delay = index * 0.1;
        final delayedValue = (animation.value - delay).clamp(0.0, 1.0);
        final dop = animation.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 30 * (1 - delayedValue)),
          child: Opacity(
            opacity: dop,
            child: Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width < 400 ? 12 : 16,
                right: MediaQuery.of(context).size.width < 400 ? 12 : 16,
                bottom: 16,
                top: index == 0 ? 0 : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey[50]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;

                  return Padding(
                    padding: EdgeInsets.all(isNarrow ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isNarrow)
                          ..._buildNarrowLayout(entry, colorScheme, dateFormatter, timeFormatter)
                        else
                          ..._buildWideLayout(entry, colorScheme, dateFormatter, timeFormatter),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
