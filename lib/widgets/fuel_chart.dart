import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fuel_entry.dart';

class FuelChart extends StatelessWidget {
  final List<FuelEntry> entries;
  final String currency;
  final String chartType; // 'cost', 'liters', 'mileage'

  const FuelChart({super.key, required this.entries, required this.currency, this.chartType = 'cost'});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return _buildNoDataWidget();
    }

    // Sort entries by date
    final sortedEntries = List<FuelEntry>.from(entries)..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getChartTitle(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              _buildChartTypeSelector(),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(height: 200, child: LineChart(_buildLineChartData(sortedEntries))),

          const SizedBox(height: 16),

          // Chart legend/info
          _buildChartInfo(sortedEntries),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Not Enough Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text('Add more fuel entries to see trends', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Text(
        _getChartTypeLabel(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
      ),
    );
  }

  String _getChartTitle() {
    switch (chartType) {
      case 'cost':
        return 'Fuel Cost Trend';
      case 'liters':
        return 'Fuel Consumption';
      case 'mileage':
        return 'Fuel Efficiency';
      default:
        return 'Fuel Trend';
    }
  }

  String _getChartTypeLabel() {
    switch (chartType) {
      case 'cost':
        return 'Cost ($currency)';
      case 'liters':
        return 'Liters';
      case 'mileage':
        return 'km/L';
      default:
        return '';
    }
  }

  LineChartData _buildLineChartData(List<FuelEntry> sortedEntries) {
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      double yValue;

      switch (chartType) {
        case 'cost':
          yValue = entry.totalCost;
          break;
        case 'liters':
          yValue = entry.liters;
          break;
        case 'mileage':
          if (i > 0) {
            // Get ALL distance up to this point
            double totalDistance = 0;
            for (int j = 1; j <= i; j++) {
              if (sortedEntries[j].odometerReading != null && sortedEntries[j - 1].odometerReading != null) {
                final distance = sortedEntries[j].odometerReading! - sortedEntries[j - 1].odometerReading!;
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
            
            yValue = totalFuelMinusLast > 0 ? totalDistance / totalFuelMinusLast : 0;
          } else {
            yValue = 0;
          }
          break;
        default:
          yValue = entry.totalCost;
      }

      spots.add(FlSpot(i.toDouble(), yValue));
    }

    // Remove zero values for mileage chart (first entry)
    if (chartType == 'mileage' && spots.isNotEmpty) {
      spots.removeAt(0);
      // Adjust x-values
      for (int i = 0; i < spots.length; i++) {
        spots[i] = FlSpot(i.toDouble(), spots[i].y);
      }
    }

    final maxY = spots.isEmpty ? 10.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.isEmpty ? 0.0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < sortedEntries.length) {
                final entry = sortedEntries[index];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${entry.dateTime.day}/${entry.dateTime.month}',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w400, fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                _formatYAxisValue(value),
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w400, fontSize: 10),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      minX: 0,
      maxX: (sortedEntries.length - 1).toDouble(),
      minY: minY * 0.9,
      maxY: maxY * 1.1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _getChartColor(),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(radius: 4, color: _getChartColor(), strokeWidth: 2, strokeColor: Colors.white);
            },
          ),
          belowBarData: BarAreaData(show: true, color: _getChartColor().withValues(alpha: 0.1)),
        ),
      ],
    );
  }

  Color _getChartColor() {
    switch (chartType) {
      case 'cost':
        return const Color(0xFFE91E63);
      case 'liters':
        return const Color(0xFF2196F3);
      case 'mileage':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String _formatYAxisValue(double value) {
    switch (chartType) {
      case 'cost':
        return value.toStringAsFixed(0);
      case 'liters':
        return value.toStringAsFixed(1);
      case 'mileage':
        return value.toStringAsFixed(1);
      default:
        return value.toStringAsFixed(1);
    }
  }

  Widget _buildChartInfo(List<FuelEntry> sortedEntries) {
    if (sortedEntries.isEmpty) return const SizedBox();

    double total = 0;
    double average = 0;
    String unit = '';

    switch (chartType) {
      case 'cost':
        total = sortedEntries.fold(0, (sum, entry) => sum + entry.totalCost);
        average = total / sortedEntries.length;
        unit = currency;
        break;
      case 'liters':
        total = sortedEntries.fold(0, (sum, entry) => sum + entry.liters);
        average = total / sortedEntries.length;
        unit = 'L';
        break;
      case 'mileage':
        // Get ALL distance
        double totalDistance = 0;
        for (int i = 1; i < sortedEntries.length; i++) {
          if (sortedEntries[i].odometerReading != null && sortedEntries[i - 1].odometerReading != null) {
            final distance = sortedEntries[i].odometerReading! - sortedEntries[i - 1].odometerReading!;
            if (distance > 0) {
              totalDistance += distance;
            }
          }
        }
        
        // Get total fuel in liters, then minus the last entry fuel
        double totalFuel = sortedEntries.fold(0.0, (sum, entry) => sum + entry.liters);
        final totalFuelMinusLast = totalFuel - sortedEntries.last.liters;
        
        if (totalFuelMinusLast > 0) {
          average = totalDistance / totalFuelMinusLast;
          total = totalDistance; // Show total distance
        }
        unit = 'km/L';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total', chartType == 'mileage' ? '${total.toStringAsFixed(0)} km' : '${total.toStringAsFixed(1)}$unit', _getChartColor()),
        _buildStatItem('Average', '${average.toStringAsFixed(1)}$unit', _getChartColor()),
        _buildStatItem('Entries', '${sortedEntries.length}', _getChartColor()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
