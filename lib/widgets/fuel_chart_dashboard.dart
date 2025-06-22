import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/fuel_entry.dart';
import '../business_logic/fuel_calculations.dart';
import 'fuel_chart.dart';

class FuelChartDashboard extends StatefulWidget {
  final List<FuelEntry> entries;
  final String currency;

  const FuelChartDashboard({super.key, required this.entries, required this.currency});

  @override
  State<FuelChartDashboard> createState() => _FuelChartDashboardState();
}

class _FuelChartDashboardState extends State<FuelChartDashboard> {
  String _selectedChartType = 'mileage';

  @override
  Widget build(BuildContext context) {
    // Only show analytics when there are enough entries
    if (widget.entries.length < 2) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart type selector
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;

            if (isSmallScreen) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: Colors.grey.shade800, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Analytics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChartTypeSelector(),
                ],
              );
            }

            return Row(
              children: [
                Icon(Icons.analytics_rounded, color: Colors.grey.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const Spacer(),
                _buildChartTypeSelector(),
              ],
            );
          },
        ),

        SizedBox(height: MediaQuery.of(context).size.width < 400 ? 8 : 12),

        // Chart
        FuelChart(entries: widget.entries, currency: widget.currency, chartType: _selectedChartType),

        const SizedBox(height: 8),

        // Quick stats row
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectorButton('mileage', 'Efficiency', Icons.trending_up),
          _buildSelectorButton('cost', 'Cost', Icons.attach_money),
          _buildSelectorButton('liters', 'Volume', Icons.local_gas_station),
        ],
      ),
    );
  }

  Widget _buildSelectorButton(String type, String label, IconData icon) {
    final isSelected = _selectedChartType == type;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChartType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? _getChartColor(type) : Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.black87 : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getChartColor(String type) {
    switch (type) {
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

  Widget _buildQuickStats() {
    if (widget.entries.length < 2) {
      return const SizedBox();
    }

    // Calculate trending stats based on selected chart type
    final sortedEntries = List<FuelEntry>.from(widget.entries)..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final midPoint = sortedEntries.length ~/ 2;
    final recent = sortedEntries.skip(midPoint).toList();
    final older = sortedEntries.take(midPoint).toList();

    double recentAvg = 0.0;
    double olderAvg = 0.0;
    double trend = 0.0;
    String trendLabel = '';
    String trendValue = '';
    Color trendColor = Colors.grey;

    switch (_selectedChartType) {
      case 'cost':
        recentAvg = recent.isEmpty ? 0.0 : recent.fold(0.0, (sum, e) => sum + e.totalCost) / recent.length;
        olderAvg = older.isEmpty ? 0.0 : older.fold(0.0, (sum, e) => sum + e.totalCost) / older.length;
        trend = recentAvg - olderAvg;
        trendLabel = trend > 0 ? 'Costs trending up' : 'Costs trending down';
        trendValue = '${widget.currency}${trend.abs().toStringAsFixed(1)}';
        trendColor = trend > 0 ? Colors.red : Colors.green;
        break;

      case 'liters':
        recentAvg = recent.isEmpty ? 0.0 : recent.fold(0.0, (sum, e) => sum + e.liters) / recent.length;
        olderAvg = older.isEmpty ? 0.0 : older.fold(0.0, (sum, e) => sum + e.liters) / older.length;
        trend = recentAvg - olderAvg;
        trendLabel = trend > 0 ? 'Volume trending up' : 'Volume trending down';
        trendValue = '${trend.abs().toStringAsFixed(1)}L';
        trendColor = trend > 0 ? Colors.red : Colors.green;
        break;

      case 'mileage':
        // Calculate mileage for recent and older periods
        if (recent.length > 1) {
          final recentTotalLiters = recent.fold(0.0, (sum, e) => sum + e.liters);
          final recentMileageData = FuelCalculations.calculateMileageMetrics(recent, recentTotalLiters);
          recentAvg = recentMileageData['overallMileage'] ?? 0.0;
        }
        if (older.length > 1) {
          final olderTotalLiters = older.fold(0.0, (sum, e) => sum + e.liters);
          final olderMileageData = FuelCalculations.calculateMileageMetrics(older, olderTotalLiters);
          olderAvg = olderMileageData['overallMileage'] ?? 0.0;
        }
        trend = recentAvg - olderAvg;
        trendLabel = trend > 0 ? 'Efficiency improving' : 'Efficiency declining';
        trendValue = '${trend.abs().toStringAsFixed(1)} km/L';
        trendColor = trend > 0 ? Colors.green : Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            trend > 0 ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            color: trendColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trendLabel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
          ),
          Text(
            trendValue,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: trendColor),
          ),
        ],
      ),
    );
  }
}
