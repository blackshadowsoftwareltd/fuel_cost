import 'package:flutter/material.dart';

class FuelSummaryStats extends StatelessWidget {
  final double totalCost;
  final double totalLiters;
  final double averagePrice;
  final String currency;

  const FuelSummaryStats({
    super.key,
    required this.totalCost,
    required this.totalLiters,
    required this.averagePrice,
    required this.currency,
  });

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 20),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final colorScheme = Theme.of(context).colorScheme;

        if (isSmallScreen) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.payments_rounded,
                      title: 'Total Cost',
                      value: '$currency${totalCost.toStringAsFixed(2)}',
                      color: Colors.red,
                      colorScheme: colorScheme,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.local_gas_station_rounded,
                      title: 'Total Liters',
                      value: '${totalLiters.toStringAsFixed(1)}L',
                      color: Colors.blue,
                      colorScheme: colorScheme,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                title: 'Average Price per Liter',
                value: '$currency${averagePrice.toStringAsFixed(2)}',
                color: Colors.green,
                colorScheme: colorScheme,
                isSmallScreen: isSmallScreen,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.payments_rounded,
                title: 'Total Cost',
                value: '$currency${totalCost.toStringAsFixed(2)}',
                color: Colors.red,
                colorScheme: colorScheme,
                isSmallScreen: isSmallScreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.local_gas_station_rounded,
                title: 'Total Liters',
                value: '${totalLiters.toStringAsFixed(1)}L',
                color: Colors.blue,
                colorScheme: colorScheme,
                isSmallScreen: isSmallScreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                title: 'Average Price/L',
                value: '$currency${averagePrice.toStringAsFixed(2)}',
                color: Colors.green,
                colorScheme: colorScheme,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        );
      },
    );
  }
}