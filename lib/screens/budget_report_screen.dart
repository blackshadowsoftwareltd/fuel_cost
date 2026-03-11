import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/fuel_entries_provider.dart';
import '../providers/summary_providers.dart';
import '../services/budget_service.dart';
import '../services/currency_service.dart';

class BudgetReportScreen extends ConsumerStatefulWidget {
  const BudgetReportScreen({super.key});

  @override
  ConsumerState<BudgetReportScreen> createState() => _BudgetReportScreenState();
}

class _BudgetReportScreenState extends ConsumerState<BudgetReportScreen>
    with SingleTickerProviderStateMixin {
  double? _monthlyBudget;
  String _currency = '\$';
  int _selectedMonthsBack = 6;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _loadCurrency();
    _animController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  Future<void> _loadBudget() async {
    final budget = await BudgetService.getMonthlyBudget();
    if (mounted) setState(() => _monthlyBudget = budget);
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

  Future<void> _showBudgetDialog() async {
    final controller = TextEditingController(text: _monthlyBudget?.toStringAsFixed(0) ?? '');
    final result = await showDialog<double?>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
            decoration: InputDecoration(
              labelText: 'Budget ($_currency)',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              hintText: 'e.g. 5000',
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          actions: [
            if (_monthlyBudget != null)
              TextButton(
                onPressed: () => Navigator.pop(context, -1.0),
                child: const Text('Remove Budget', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result == -1.0) {
        await BudgetService.setMonthlyBudget(null);
        setState(() => _monthlyBudget = null);
      } else if (result > 0) {
        await BudgetService.setMonthlyBudget(result);
        setState(() => _monthlyBudget = result);
      }
    }
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
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)]
                : [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFF2196F3)],
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Budget & Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Track your fuel spending', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                        onPressed: _showBudgetDialog,
                        tooltip: 'Set Budget',
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: entriesAsync.when(
                    data: (entries) {
                      final now = DateTime.now();
                      final monthlyData = BudgetService.getMonthlyHistory(entries, _selectedMonthsBack);
                      final thisMonthSpending = BudgetService.getMonthlySpending(entries, now.year, now.month);
                      final lastMonthSpending = BudgetService.getMonthlySpending(
                        entries,
                        DateTime(now.year, now.month - 1).year,
                        DateTime(now.year, now.month - 1).month,
                      );
                      final thisMonthLiters = BudgetService.getMonthlyLiters(entries, now.year, now.month);
                      final avgDaily = BudgetService.getAvgDailySpending(entries, now.year, now.month);

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Budget Progress (if set)
                              if (_monthlyBudget != null) ...[
                                _buildBudgetProgressCard(thisMonthSpending, isDark),
                                const SizedBox(height: 16),
                              ],

                              // This Month Summary
                              _buildCurrentMonthCard(thisMonthSpending, lastMonthSpending, thisMonthLiters, avgDaily, isDark),
                              const SizedBox(height: 16),

                              // Monthly Spending Chart
                              _buildMonthlyChartCard(monthlyData, isDark),
                              const SizedBox(height: 16),

                              // Weekly Breakdown
                              _buildWeeklyBreakdownCard(entries, now, isDark),
                              const SizedBox(height: 16),

                              // Monthly Comparison Table
                              _buildMonthlyTableCard(monthlyData, isDark),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildBudgetProgressCard(double spending, bool isDark) {
    final progress = _monthlyBudget! > 0 ? (spending / _monthlyBudget!).clamp(0.0, 1.0) : 0.0;
    final remaining = _monthlyBudget! - spending;
    final isOver = remaining < 0;
    final progressColor = isOver
        ? Colors.red
        : progress > 0.8
            ? Colors.orange
            : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: progressColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Monthly Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
                ],
              ),
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: _showBudgetDialog),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currency${spending.toStringAsFixed(0)} spent',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              Text(
                isOver
                    ? '$_currency${(-remaining).toStringAsFixed(0)} over budget'
                    : '$_currency${remaining.toStringAsFixed(0)} remaining',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Budget: $_currency${_monthlyBudget!.toStringAsFixed(0)}  |  ${(progress * 100).toStringAsFixed(0)}% used',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthCard(double spending, double lastMonth, double liters, double avgDaily, bool isDark) {
    final change = lastMonth > 0 ? ((spending - lastMonth) / lastMonth * 100) : 0.0;
    final changePositive = change > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatTile('Spent', '$_currency${spending.toStringAsFixed(0)}', const Color(0xFFE91E63), isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile('Liters', '${liters.toStringAsFixed(1)}L', const Color(0xFF2196F3), isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatTile('Avg/Day', '$_currency${avgDaily.toStringAsFixed(0)}', const Color(0xFF9C27B0), isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  'vs Last Month',
                  '${changePositive ? '+' : ''}${change.toStringAsFixed(0)}%',
                  changePositive ? Colors.red : const Color(0xFF4CAF50),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMonthlyChartCard(List<MonthlyData> data, bool isDark) {
    final maxY = data.isEmpty ? 100.0 : data.map((d) => d.totalCost).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Spending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
              DropdownButton<int>(
                value: _selectedMonthsBack,
                underline: const SizedBox(),
                items: [3, 6, 12].map((m) => DropdownMenuItem(value: m, child: Text('${m}M'))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedMonthsBack = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.isEmpty || maxY == 0
                ? Center(child: Text('No data', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)))
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '$_currency${rod.toY.toStringAsFixed(0)}',
                              TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(data[index].monthName, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      barGroups: List.generate(data.length, (i) {
                        final isCurrentMonth = i == data.length - 1;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].totalCost,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              gradient: LinearGradient(
                                colors: isCurrentMonth
                                    ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
                                    : [const Color(0xFF2196F3).withValues(alpha: 0.6), const Color(0xFF2196F3).withValues(alpha: 0.3)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdownCard(List entries, DateTime now, bool isDark) {
    final weeks = List.generate(5, (i) {
      return BudgetService.getWeeklySpending(entries.cast(), now.year, now.month, i + 1);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          Text(DateFormat('MMMM').format(now), style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          const SizedBox(height: 16),
          ...List.generate(weeks.length, (i) {
            final maxWeek = weeks.reduce((a, b) => a > b ? a : b);
            final progress = maxWeek > 0 ? weeks[i] / maxWeek : 0.0;
            final dayRange = '${(i * 7 + 1)}-${((i + 1) * 7).clamp(1, DateTime(now.year, now.month + 1, 0).day)}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 55, child: Text('W${i + 1}', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF667eea)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Day $dayRange', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '$_currency${weeks[i].toStringAsFixed(0)}',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyTableCard(List<MonthlyData> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Comparison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 16),
          // Table Header
          Row(
            children: [
              Expanded(flex: 2, child: Text('Month', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
              Expanded(child: Text('Spent', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
              Expanded(child: Text('Liters', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
              Expanded(child: Text('Fills', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
            ],
          ),
          Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          ...data.reversed.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('${d.fullMonthName} ${d.year}', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                    Expanded(child: Text('$_currency${d.totalCost.toStringAsFixed(0)}', textAlign: TextAlign.end, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.grey.shade800))),
                    Expanded(child: Text('${d.totalLiters.toStringAsFixed(0)}L', textAlign: TextAlign.end, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                    Expanded(child: Text('${d.fillUpCount}', textAlign: TextAlign.end, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
