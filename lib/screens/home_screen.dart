import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart' show AuthService;
import '../services/vehicle_service.dart';
import '../services/budget_service.dart';
import '../widgets/widgets.dart';
import '../providers/fuel_entries_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/summary_providers.dart';
import '../providers/sync_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import 'add_fuel_screen.dart';
import 'fuel_history_screen.dart';
import 'settings_screen.dart';
import 'how_to_use_screen.dart';
import 'trip_calculator_screen.dart';
import 'budget_report_screen.dart';
import 'vehicle_management_screen.dart';
import 'maintenance_log_screen.dart';
import 'spending_comparison_screen.dart';
import 'vehicle_comparison_screen.dart';

const Map<String, IconData> _vehicleIconMap = {
  'directions_car': Icons.directions_car,
  'two_wheeler': Icons.two_wheeler,
  'local_shipping': Icons.local_shipping,
  'airport_shuttle': Icons.airport_shuttle,
  'electric_car': Icons.electric_car,
  'pedal_bike': Icons.pedal_bike,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _staggeredAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _staggeredAnimation;

  late AnimationController _summaryController;

  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;

  // Cache previous values to avoid flicker during provider reload
  double _lastTotalCost = 0.0;
  double _lastTotalLiters = 0.0;
  Map<String, double> _lastMileageCalcs = {};
  String _lastCurrency = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();

    _fadeAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _staggeredAnimationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _summaryController = AnimationController(value: 1.0, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    _staggeredAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _staggeredAnimationController, curve: Curves.easeOutCubic));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _staggeredAnimationController.forward();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await VehicleService.getVehicles();
    final selectedId = await VehicleService.getSelectedVehicleId();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _selectedVehicleId = selectedId;
      });
      ref.read(selectedVehicleIdProvider.notifier).state = selectedId;
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _staggeredAnimationController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _switchVehicle(String? id) async {
    // Reset and replay stagger
    _summaryController.value = 0.0;
    setState(() => _selectedVehicleId = id);
    ref.read(selectedVehicleIdProvider.notifier).state = id;
    VehicleService.setSelectedVehicleId(id);
    _summaryController.animateTo(1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.linear,
    );
  }

  /// Wraps a top-level section so it fades+slides in on its stagger slot.
  Widget _staggerSection(int index, int total, Widget child) {
    final start = index / (total + 1);
    final end = ((index + 2) / (total + 1)).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _summaryController,
      builder: (context, _) {
        final t = Interval(start, end, curve: Curves.easeOut)
            .transform(_summaryController.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  String _getButtonSubtitle(String title) {
    switch (title) {
      case 'Add Fuel Entry':
        return 'Record your fuel purchases';
      case 'View Fuel History':
        return 'Browse your fuel records';
      default:
        return 'Quick action';
    }
  }

  Widget _buildSummaryLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(vehicleFilteredEntriesProvider);
    final totalCostAsync = ref.watch(filteredTotalCostProvider);
    final totalLitersAsync = ref.watch(filteredTotalLitersProvider);
    final mileageCalculationsAsync = ref.watch(filteredMileageCalculationsProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final authAsync = ref.watch(authenticationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve with cached fallback to prevent flicker
    final totalCost = totalCostAsync.valueOrNull ?? _lastTotalCost;
    final totalLiters = totalLitersAsync.valueOrNull ?? _lastTotalLiters;
    final mileageCalcs = mileageCalculationsAsync.valueOrNull ?? _lastMileageCalcs;
    final currency = currencyAsync.valueOrNull ?? _lastCurrency;
    if (totalCostAsync.hasValue) _lastTotalCost = totalCost;
    if (totalLitersAsync.hasValue) _lastTotalLiters = totalLiters;
    if (mileageCalculationsAsync.hasValue) _lastMileageCalcs = mileageCalcs;
    if (currencyAsync.hasValue) _lastCurrency = currency;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1a1a2e).withValues(alpha: 0.3), const Color(0xFF121212)]
                : [
                    const Color(0xFF2196F3).withValues(alpha: 0.1),
                    const Color(0xFF21CBF3).withValues(alpha: 0.05),
                    Colors.white,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fuel Cost',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Monitor your fuel efficiency',
                                style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HowToUseScreen()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                                  onPressed: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                                    ref.invalidate(fuelEntriesProvider);
                                    ref.invalidate(authenticationProvider);
                                    ref.invalidate(currencyProvider);
                                    ref.invalidate(syncStatusProvider);
                                    ref.invalidate(vehiclesProvider);
                                    _loadVehicles();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Vehicle Selector
                  StaggeredAnimationWrapper(
                    index: 0,
                    animation: _staggeredAnimation,
                    child: SizedBox(
                      height: 38,
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                // "All" chip
                                _buildVehicleChip(
                                  id: null,
                                  label: 'All',
                                  icon: Icons.dashboard_rounded,
                                  isSelected: _selectedVehicleId == null,
                                  isDark: isDark,
                                ),
                                ..._vehicles.map((v) => _buildVehicleChip(
                                      id: v.id,
                                      label: v.name,
                                      icon: _vehicleIconMap[v.iconName] ?? Icons.directions_car,
                                      isSelected: _selectedVehicleId == v.id,
                                      isDark: isDark,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleManagementScreen()));
                              ref.invalidate(vehiclesProvider);
                              _loadVehicles();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _vehicles.isEmpty ? Icons.add_rounded : Icons.tune_rounded,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Quick Stats Card
                  _staggerSection(0, 4, entriesAsync.when(
                      data: (entries) => currencyAsync.when(
                        data: (currency) {
                          if (entries.isEmpty) return const SizedBox();
                          final now = DateTime.now();
                          final thisMonthSpent = BudgetService.getMonthlySpending(entries, now.year, now.month);
                          final daysSinceLastFill = entries.isNotEmpty
                              ? now.difference(entries.last.dateTime).inDays
                              : 0;
                          final lastCost = entries.isNotEmpty ? entries.last.totalCost : 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF667eea).withValues(alpha: 0.3), const Color(0xFF764ba2).withValues(alpha: 0.3)]
                                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: const Color(0xFF667eea).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStat('This Month', '$currency${thisMonthSpent.toStringAsFixed(0)}', Icons.calendar_month),
                                ),
                                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                                Expanded(
                                  child: _buildQuickStat('Last Fill', '$currency${lastCost.toStringAsFixed(0)}', Icons.local_gas_station),
                                ),
                                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                                Expanded(
                                  child: _buildQuickStat('Days Ago', '$daysSinceLastFill', Icons.schedule),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    )),

                  // Summary Section
                  _staggerSection(1, 4, _selectedVehicleId == null
                      ? _buildOverallSummary(totalCost, totalLiters, mileageCalcs, currency, isDark)
                      : _buildVehicleSummary(totalCost, totalLiters, mileageCalcs, currency, isDark),
                  ),

                  const SizedBox(height: 10),

                  // Analytics Dashboard Section
                  _staggerSection(2, 4, entriesAsync.when(
                    data: (entries) => currencyAsync.when(
                      data: (currency) => FuelChartDashboard(entries: entries, currency: currency),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  )),

                  const SizedBox(height: 16),

                  // Action Buttons
                  _staggerSection(3, 4, Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
                      const SizedBox(height: 12),
                      ActionButton(
                        icon: Icons.add_circle,
                        title: 'Add Fuel Entry',
                        subtitle: _getButtonSubtitle('Add Fuel Entry'),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFuelScreen()));
                          ref.invalidate(fuelEntriesProvider);
                          ref.invalidate(syncStatusProvider);
                        },
                        color: const Color.fromARGB(255, 46, 161, 254),
                        isPrimary: true,
                      ),
                      ActionButton(
                        icon: Icons.history,
                        title: 'View Fuel History',
                        subtitle: _getButtonSubtitle('View Fuel History'),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const FuelHistoryScreen()));
                          ref.invalidate(fuelEntriesProvider);
                          ref.invalidate(syncStatusProvider);
                        },
                        color: const Color.fromARGB(255, 11, 141, 53),
                      ),
                      ActionButton(
                        icon: Icons.calculate_rounded,
                        title: 'Trip Cost Calculator',
                        subtitle: 'Estimate fuel cost for a trip',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TripCalculatorScreen()));
                        },
                        color: const Color(0xFF9C27B0),
                      ),
                      ActionButton(
                        icon: Icons.bar_chart_rounded,
                        title: 'Budget & Reports',
                        subtitle: 'Monthly spending & budget tracking',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetReportScreen()));
                        },
                        color: const Color(0xFFFF9800),
                      ),
                      ActionButton(
                        icon: Icons.build_circle,
                        title: 'Maintenance Log',
                        subtitle: 'Track your vehicle services',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MaintenanceLogScreen()));
                        },
                        color: const Color(0xFF00BCD4),
                      ),
                      ActionButton(
                        icon: Icons.compare_arrows,
                        title: 'Spending Comparison',
                        subtitle: 'Compare months side by side',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SpendingComparisonScreen()));
                        },
                        color: const Color(0xFF607D8B),
                      ),
                      ActionButton(
                        icon: Icons.compare,
                        title: 'Compare Vehicles',
                        subtitle: 'Side-by-side efficiency analysis',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleComparisonScreen()));
                        },
                        color: const Color(0xFF795548),
                      ),
                      authAsync.when(
                        data: (isAuthenticated) {
                          final syncStatusAsync = ref.watch(syncStatusProvider);
                          return syncStatusAsync.when(
                            data: (lastSyncTime) => SyncButton(
                              isSyncing: false,
                              isAuthenticated: isAuthenticated,
                              onPressed: () async => await AuthService.handleSync(context, ref),
                              lastSyncTime: lastSyncTime,
                            ),
                            loading: () => SyncButton(
                              isSyncing: true,
                              isAuthenticated: isAuthenticated,
                              onPressed: () async => await AuthService.handleSync(context, ref),
                              lastSyncTime: null,
                            ),
                            error: (e, _) => SyncButton(
                              isSyncing: false,
                              isAuthenticated: isAuthenticated,
                              onPressed: () async => await AuthService.handleSync(context, ref),
                              lastSyncTime: null,
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSummary(
    double totalCost,
    double totalLiters,
    Map<String, double> mileageCalcs,
    String currency,
    bool isDark,
  ) {
    final totalDistance = mileageCalcs['totalDistance'] ?? 0.0;
    return Container(
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width < 400 ? 8 : 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -4),
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Color(0xFF667eea), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Overall Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildOverallStatTile(
                  icon: Icons.payments_rounded, label: 'Total Cost',
                  value: '$currency${totalCost.toStringAsFixed(0)}',
                  color: const Color(0xFFE91E63), isDark: isDark,
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildOverallStatTile(
                  icon: Icons.local_gas_station_rounded, label: 'Total Fuels',
                  value: '${totalLiters.toStringAsFixed(1)}L',
                  color: const Color(0xFF2196F3), isDark: isDark,
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildOverallStatTile(
                  icon: Icons.route_rounded, label: 'Total Distance',
                  value: totalDistance > 0 ? '${totalDistance.toStringAsFixed(0)} km' : 'N/A',
                  color: const Color(0xFFFF9800), isDark: isDark,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSummary(
    double totalCost,
    double totalLiters,
    Map<String, double> mileageCalcs,
    String currency,
    bool isDark,
  ) {
    final totalDistance = mileageCalcs['totalDistance'] ?? 0.0;
    final lastTripMileage = mileageCalcs['lastTripMileage'] ?? 0.0;
    final overallMileage = mileageCalcs['overallMileage'] ?? 0.0;
    final maxMileage = mileageCalcs['maxMileage'] ?? 0.0;
    final minMileage = mileageCalcs['minMileage'] ?? 0.0;
    return Container(
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width < 400 ? 8 : 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -4),
        ],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Color(0xFF667eea), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryLine(icon: Icons.payments_rounded, label: 'Total Cost', value: '$currency${totalCost.toStringAsFixed(2)}', color: const Color(0xFFE91E63)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.local_gas_station_rounded, label: 'Total Liters', value: '${totalLiters.toStringAsFixed(1)}L', color: const Color(0xFF2196F3)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.route_rounded, label: 'Total Distance', value: totalDistance > 0 ? '${totalDistance.toStringAsFixed(0)} km' : 'N/A', color: const Color(0xFFFF9800)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.directions_car_rounded, label: 'Last Trip Mileage', value: lastTripMileage > 0 ? '${lastTripMileage.toStringAsFixed(1)} km/L' : 'N/A', color: const Color(0xFF4CAF50)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.trending_up_rounded, label: 'Overall Mileage', value: overallMileage > 0 ? '${overallMileage.toStringAsFixed(1)} km/L' : 'N/A', color: const Color(0xFF9C27B0)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.keyboard_double_arrow_up_rounded, label: 'Max Mileage', value: maxMileage > 0 ? '${maxMileage.toStringAsFixed(1)} km/L' : 'N/A', color: const Color(0xFF00C853)),
            const SizedBox(height: 16),
            _buildSummaryLine(icon: Icons.keyboard_double_arrow_down_rounded, label: 'Min Mileage', value: minMileage > 0 ? '${minMileage.toStringAsFixed(1)} km/L' : 'N/A', color: const Color(0xFFFF5722)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleChip({
    required String? id,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (_selectedVehicleId == id) return;
          _switchVehicle(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}
