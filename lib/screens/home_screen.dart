import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/widgets.dart';
import '../providers/fuel_entries_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/summary_providers.dart';
import '../providers/sync_provider.dart';
import 'add_fuel_screen.dart';
import 'fuel_history_screen.dart';
import 'settings_screen.dart';
import 'how_to_use_screen.dart';
import 'auth_screen.dart';

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

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _staggeredAnimationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));

    _staggeredAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _staggeredAnimationController, curve: Curves.easeOutCubic));

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _staggeredAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _staggeredAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    final isAuthenticated = ref.read(authenticationProvider).value ?? false;

    if (!isAuthenticated) {
      // Navigate to sign in screen
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));

      // If sign in was successful, immediately sync
      if (result == true) {
        await ref.read(authenticationProvider.notifier).refresh();
        final newAuthState = ref.read(authenticationProvider).value ?? false;
        if (newAuthState) {
          await _performSync();
        }
      }
    } else {
      // User is already signed in, just sync
      await _performSync();
    }
  }

  Future<void> _performSync() async {
    try {
      // Use the proper sync provider instead of direct fuel entries sync
      await ref.read(syncStatusProvider.notifier).performSync();
      // Refresh fuel entries after sync
      await ref.read(fuelEntriesProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data synced successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red));
      }
    }
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
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
    // Watch all the providers
    final entriesAsync = ref.watch(fuelEntriesProvider);
    final totalCostAsync = ref.watch(totalCostProvider);
    final totalLitersAsync = ref.watch(totalLitersProvider);
    final mileageCalculationsAsync = ref.watch(mileageCalculationsProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final authAsync = ref.watch(authenticationProvider); 

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
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
            padding: EdgeInsets.only(bottom: 50.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section with fade and slide animation
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
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Monitor your fuel efficiency',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.help_outline, color: Color(0xFF2196F3)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HowToUseScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.settings, color: Color(0xFF2196F3)),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                    );
                                    // Refresh providers after returning from settings
                                    ref.invalidate(fuelEntriesProvider);
                                    ref.invalidate(authenticationProvider);
                                    ref.invalidate(currencyProvider);
                                    ref.invalidate(syncStatusProvider);
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

                  // Summary Section
                  StaggeredAnimationWrapper(
                    index: 1,
                    animation: _staggeredAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width < 400 ? 8 : 10),
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
                      child: Padding(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 20 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2), width: 1),
                                  ),
                                  child: Icon(Icons.analytics_rounded, color: const Color(0xFF667eea), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Cost Line
                            totalCostAsync.when(
                              data: (totalCost) => currencyAsync.when(
                                data: (currency) => _buildSummaryLine(
                                  icon: Icons.payments_rounded,
                                  label: 'Total Cost',
                                  value: '$currency${totalCost.toStringAsFixed(2)}',
                                  color: const Color(0xFFE91E63),
                                ),
                                loading: () => const CircularProgressIndicator(),
                                error: (e, _) => Text('Error: $e'),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Liters Line
                            totalLitersAsync.when(
                              data: (totalLiters) => _buildSummaryLine(
                                icon: Icons.local_gas_station_rounded,
                                label: 'Total Liters',
                                value: '${totalLiters.toStringAsFixed(1)}L',
                                color: const Color(0xFF2196F3),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Distance Line
                            mileageCalculationsAsync.when(
                              data: (calculations) => _buildSummaryLine(
                                icon: Icons.route_rounded,
                                label: 'Total Distance',
                                value: calculations['totalDistance']! > 0
                                    ? '${calculations['totalDistance']!.toStringAsFixed(0)} km'
                                    : 'N/A',
                                color: const Color(0xFFFF9800),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Last Trip Mileage Line
                            mileageCalculationsAsync.when(
                              data: (calculations) => _buildSummaryLine(
                                icon: Icons.directions_car_rounded,
                                label: 'Last Trip Mileage',
                                value: calculations['lastTripMileage']! > 0
                                    ? '${calculations['lastTripMileage']!.toStringAsFixed(1)} km/L'
                                    : 'N/A',
                                color: const Color(0xFF4CAF50),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Overall Mileage Line
                            mileageCalculationsAsync.when(
                              data: (calculations) => _buildSummaryLine(
                                icon: Icons.trending_up_rounded,
                                label: 'Overall Mileage',
                                value: calculations['overallMileage']! > 0
                                    ? '${calculations['overallMileage']!.toStringAsFixed(1)} km/L'
                                    : 'N/A',
                                color: const Color(0xFF9C27B0),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Max Mileage Line
                            mileageCalculationsAsync.when(
                              data: (calculations) => _buildSummaryLine(
                                icon: Icons.keyboard_double_arrow_up_rounded,
                                label: 'Max Mileage',
                                value: calculations['maxMileage']! > 0
                                    ? '${calculations['maxMileage']!.toStringAsFixed(1)} km/L'
                                    : 'N/A',
                                color: const Color(0xFF00C853),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),

                            const SizedBox(height: 16),

                            // Min Mileage Line
                            mileageCalculationsAsync.when(
                              data: (calculations) => _buildSummaryLine(
                                icon: Icons.keyboard_double_arrow_down_rounded,
                                label: 'Min Mileage',
                                value: calculations['minMileage']! > 0
                                    ? '${calculations['minMileage']!.toStringAsFixed(1)} km/L'
                                    : 'N/A',
                                color: const Color(0xFFFF5722),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text('Error: $e'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Analytics Dashboard Section
                  StaggeredAnimationWrapper(
                    index: 2,
                    animation: _staggeredAnimation,
                    child: entriesAsync.when(
                      data: (entries) => currencyAsync.when(
                        data: (currency) => FuelChartDashboard(entries: entries, currency: currency),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons section with staggered animation
                  StaggeredAnimationWrapper(
                    index: 3,
                    animation: _staggeredAnimation,
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(height: 12),

                  StaggeredAnimationWrapper(
                    index: 4,
                    animation: _staggeredAnimation,
                    child: ActionButton(
                      icon: Icons.add_circle,
                      title: 'Add Fuel Entry',
                      subtitle: _getButtonSubtitle('Add Fuel Entry'),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFuelScreen()));
                        // Refresh providers after adding entry
                        ref.invalidate(fuelEntriesProvider);
                        ref.invalidate(syncStatusProvider);
                      },
                      color: const Color.fromARGB(255, 46, 161, 254),
                      isPrimary: true,
                    ),
                  ),

                  StaggeredAnimationWrapper(
                    index: 5,
                    animation: _staggeredAnimation,
                    child: ActionButton(
                      icon: Icons.history,
                      title: 'View Fuel History',
                      subtitle: _getButtonSubtitle('View Fuel History'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FuelHistoryScreen()),
                        );
                        // Refresh providers after returning from history
                        ref.invalidate(fuelEntriesProvider);
                        ref.invalidate(syncStatusProvider);
                      },
                      color: const Color.fromARGB(255, 11, 141, 53),
                    ),
                  ),

                  StaggeredAnimationWrapper(
                    index: 6,
                    animation: _staggeredAnimation,
                    child: authAsync.when(
                      data: (isAuthenticated) {
                        final syncStatusAsync = ref.watch(syncStatusProvider);
                        return syncStatusAsync.when(
                          data: (lastSyncTime) => SyncButton(
                            isSyncing: false,
                            isAuthenticated: isAuthenticated,
                            onPressed: _handleSync,
                            lastSyncTime: lastSyncTime,
                          ),
                          loading: () => SyncButton(
                            isSyncing: true,
                            isAuthenticated: isAuthenticated,
                            onPressed: _handleSync,
                            lastSyncTime: null,
                          ),
                          error: (e, _) => SyncButton(
                            isSyncing: false,
                            isAuthenticated: isAuthenticated,
                            onPressed: _handleSync,
                            lastSyncTime: null,
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
