import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fuel_entries_provider.dart';
import '../services/budget_service.dart';
import '../services/currency_service.dart';

class SpendingComparisonScreen extends ConsumerStatefulWidget {
  const SpendingComparisonScreen({super.key});

  @override
  ConsumerState<SpendingComparisonScreen> createState() =>
      _SpendingComparisonScreenState();
}

class _SpendingComparisonScreenState
    extends ConsumerState<SpendingComparisonScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _monthA;
  late DateTime _monthB;
  late DateTime _monthC;
  late DateTime _monthD;
  String _currency = '\$';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthA = DateTime(now.year, now.month, 1);
    _monthB = DateTime(now.year, now.month - 1, 1);
    _monthC = DateTime(now.year, now.month - 2, 1);
    _monthD = DateTime(now.year, now.month - 3, 1);
    _loadCurrency();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const Color _colorA = Color(0xFF667eea);
  static const Color _colorB = Color(0xFFE91E63);
  static const Color _colorC = Color(0xFF4CAF50);
  static const Color _colorD = Color(0xFFFF9800);

  Color _colorForPeriod(int period) {
    switch (period) {
      case 0: return _colorA;
      case 1: return _colorB;
      case 2: return _colorC;
      case 3: return _colorD;
      default: return _colorA;
    }
  }

  String _labelForPeriod(int period) {
    switch (period) {
      case 0: return 'Period A';
      case 1: return 'Period B';
      case 2: return 'Period C';
      case 3: return 'Period D';
      default: return 'Period A';
    }
  }

  DateTime _getMonth(int period) {
    switch (period) {
      case 0: return _monthA;
      case 1: return _monthB;
      case 2: return _monthC;
      case 3: return _monthD;
      default: return _monthA;
    }
  }

  void _setMonth(int period, DateTime month) {
    setState(() {
      switch (period) {
        case 0: _monthA = month; break;
        case 1: _monthB = month; break;
        case 2: _monthC = month; break;
        case 3: _monthD = month; break;
      }
    });
  }

  void _showMonthPicker({required int period}) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      return DateTime(now.year, now.month - i, 1);
    });
    final selected = _getMonth(period);
    final color = _colorForPeriod(period);
    final label = _labelForPeriod(period);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select $label',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.year == selected.year &&
                        month.month == selected.month;
                    return ListTile(
                      title: Text(
                        DateFormat('MMMM yyyy').format(month),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? color
                              : (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: color)
                          : null,
                      onTap: () {
                        _setMonth(period, month);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(fuelEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460)
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFF2196F3)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spending Comparison',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Compare periods side by side',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121212)
                        : Colors.grey.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: entriesAsync.when(
                    data: (entries) {
                      // Compute stats for all 4 periods
                      final months = [_monthA, _monthB, _monthC, _monthD];
                      final spending = months.map((m) =>
                          BudgetService.getMonthlySpending(entries, m.year, m.month)).toList();
                      final liters = months.map((m) =>
                          BudgetService.getMonthlyLiters(entries, m.year, m.month)).toList();
                      final fills = months.map((m) =>
                          BudgetService.getMonthlyFillUpCount(entries, m.year, m.month)).toList();
                      final avgDaily = months.map((m) =>
                          BudgetService.getAvgDailySpending(entries, m.year, m.month)).toList();
                      final avgPerFill = List.generate(4, (i) =>
                          fills[i] > 0 ? spending[i] / fills[i] : 0.0);

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Period Selectors
                              _buildPeriodSelectors(isDark),
                              const SizedBox(height: 16),

                              // Visual Comparison Bars
                              _buildVisualComparisonCard(
                                isDark,
                                spending: spending,
                                liters: liters,
                                fills: fills.map((f) => f.toDouble()).toList(),
                                avgDaily: avgDaily,
                              ),
                              const SizedBox(height: 16),

                              // Detailed Comparison
                              _buildDetailedComparisonCard(
                                isDark,
                                spending: spending,
                                liters: liters,
                                fills: fills,
                                avgDaily: avgDaily,
                                avgPerFill: avgPerFill,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelectors(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodCard(
                  label: _labelForPeriod(i),
                  month: _getMonth(i),
                  color: _colorForPeriod(i),
                  isDark: isDark,
                  onTap: () => _showMonthPicker(period: i),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodCard({
    required String label,
    required DateTime month,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              DateFormat('MMM yyyy').format(month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.calendar_month, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualComparisonCard(
    bool isDark, {
    required List<double> spending,
    required List<double> liters,
    required List<double> fills,
    required List<double> avgDaily,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (int i = 0; i < 4; i++)
                _buildLegendItem(_labelForPeriod(i), _colorForPeriod(i)),
            ],
          ),
          const SizedBox(height: 20),
          _buildComparisonBarRow(
            label: 'Total Cost',
            values: spending,
            formatValue: (v) => '$_currency${v.toStringAsFixed(0)}',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildComparisonBarRow(
            label: 'Liters',
            values: liters,
            formatValue: (v) => '${v.toStringAsFixed(1)}L',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildComparisonBarRow(
            label: 'Fill-ups',
            values: fills,
            formatValue: (v) => v.toInt().toString(),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildComparisonBarRow(
            label: 'Avg/Day',
            values: avgDaily,
            formatValue: (v) => '$_currency${v.toStringAsFixed(0)}',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBarRow({
    required String label,
    required List<double> values,
    required String Function(double) formatValue,
    required bool isDark,
  }) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  formatValue(values[i]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _colorForPeriod(i),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxValue > 0 ? values[i] / maxValue : 0.0,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(_colorForPeriod(i)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedComparisonCard(
    bool isDark, {
    required List<double> spending,
    required List<double> liters,
    required List<int> fills,
    required List<double> avgDaily,
    required List<double> avgPerFill,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          // Column headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          'Metric',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      for (int i = 0; i < 4; i++)
                        SizedBox(
                          width: 70,
                          child: Text(
                            _labelForPeriod(i).replaceAll('Period ', ''),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _colorForPeriod(i),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  _buildComparisonRow('Total Spent',
                      spending.map((v) => '$_currency${v.toStringAsFixed(0)}').toList(), isDark),
                  _buildComparisonRow('Total Liters',
                      liters.map((v) => '${v.toStringAsFixed(1)}L').toList(), isDark),
                  _buildComparisonRow('Fill-ups',
                      fills.map((v) => v.toString()).toList(), isDark),
                  _buildComparisonRow('Avg/Day',
                      avgDaily.map((v) => '$_currency${v.toStringAsFixed(0)}').toList(), isDark),
                  _buildComparisonRow('Avg/Fill',
                      avgPerFill.map((v) => '$_currency${v.toStringAsFixed(0)}').toList(), isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    List<String> values,
    bool isDark,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
              for (int i = 0; i < values.length; i++)
                SizedBox(
                  width: 70,
                  child: Text(
                    values[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _colorForPeriod(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ],
    );
  }
}
