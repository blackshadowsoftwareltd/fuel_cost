import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_entry.dart';

class BudgetService {
  static const String _monthlyBudgetKey = 'monthly_fuel_budget';

  static Future<double?> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getDouble(_monthlyBudgetKey);
    return budget;
  }

  static Future<void> setMonthlyBudget(double? budget) async {
    final prefs = await SharedPreferences.getInstance();
    if (budget == null) {
      await prefs.remove(_monthlyBudgetKey);
    } else {
      await prefs.setDouble(_monthlyBudgetKey, budget);
    }
  }

  /// Get spending for a specific month
  static double getMonthlySpending(List<FuelEntry> entries, int year, int month) {
    return entries
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .fold(0.0, (sum, e) => sum + e.totalCost);
  }

  /// Get spending for a specific week of a month (week 1-5)
  static double getWeeklySpending(List<FuelEntry> entries, int year, int month, int week) {
    final startDay = (week - 1) * 7 + 1;
    final endDay = week * 7;
    return entries
        .where((e) =>
            e.dateTime.year == year &&
            e.dateTime.month == month &&
            e.dateTime.day >= startDay &&
            e.dateTime.day <= endDay)
        .fold(0.0, (sum, e) => sum + e.totalCost);
  }

  /// Get liters for a specific month
  static double getMonthlyLiters(List<FuelEntry> entries, int year, int month) {
    return entries
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .fold(0.0, (sum, e) => sum + e.liters);
  }

  /// Get fill-up count for a specific month
  static int getMonthlyFillUpCount(List<FuelEntry> entries, int year, int month) {
    return entries
        .where((e) => e.dateTime.year == year && e.dateTime.month == month)
        .length;
  }

  /// Get monthly spending data for the last N months
  static List<MonthlyData> getMonthlyHistory(List<FuelEntry> entries, int months) {
    final now = DateTime.now();
    final result = <MonthlyData>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final year = date.year;
      final month = date.month;
      final spending = getMonthlySpending(entries, year, month);
      final liters = getMonthlyLiters(entries, year, month);
      final count = getMonthlyFillUpCount(entries, year, month);

      result.add(MonthlyData(
        year: year,
        month: month,
        totalCost: spending,
        totalLiters: liters,
        fillUpCount: count,
      ));
    }

    return result;
  }

  /// Get average daily spending for a month
  static double getAvgDailySpending(List<FuelEntry> entries, int year, int month) {
    final spending = getMonthlySpending(entries, year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final daysElapsed = (year == now.year && month == now.month) ? now.day : daysInMonth;
    return daysElapsed > 0 ? spending / daysElapsed : 0;
  }
}

class MonthlyData {
  final int year;
  final int month;
  final double totalCost;
  final double totalLiters;
  final int fillUpCount;

  MonthlyData({
    required this.year,
    required this.month,
    required this.totalCost,
    required this.totalLiters,
    required this.fillUpCount,
  });

  String get monthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String get fullMonthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
