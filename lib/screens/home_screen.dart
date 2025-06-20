import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/currency_service.dart';
import 'add_fuel_screen.dart';
import 'fuel_history_screen.dart';
import 'settings_screen.dart';
import 'how_to_use_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  double _totalCost = 0.0;
  double _totalLiters = 0.0;
  int _totalEntries = 0;
  double? _averageMileage;
  double? _currentOdometer;
  double _lastTripMileage = 0.0;
  double _overallMileage = 0.0;
  double _totalDistance = 0.0;
  List<FuelEntry> _entries = [];
  bool _isAuthenticated = false;
  bool _isSyncing = false;
  String _currency = '\$';
  DateTime? _lastSyncTime;

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

    _loadSummaryData();
    _checkAuthStatus();
    _loadCurrency();
    _loadLastSyncTime();

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

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) {
      setState(() {
        _currency = currency;
      });
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      final totalCost = await FuelStorageService.getTotalFuelCost();
      final totalLiters = await FuelStorageService.getTotalLiters();
      final entries = await FuelStorageService.getFuelEntries();
      final averageMileage = await FuelStorageService.getAverageMileage();
      final currentOdometer = await FuelStorageService.getCurrentOdometer();

      // Calculate mileage metrics and total distance
      final sortedEntries = List<FuelEntry>.from(entries)..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      double lastTripMileage = 0.0;
      double overallMileage = 0.0;
      double totalDistance = 0.0;

      if (sortedEntries.length > 1) {
        final mileages = <double>[];

        // Calculate total distance from all trips
        for (int i = 1; i < sortedEntries.length; i++) {
          if (sortedEntries[i].odometerReading != null && sortedEntries[i - 1].odometerReading != null) {
            final distance = sortedEntries[i].odometerReading! - sortedEntries[i - 1].odometerReading!;
            if (distance > 0) {
              totalDistance += distance;
              final mileage = distance / sortedEntries[i].liters;
              mileages.add(mileage);
            }
          }
        }

        if (totalDistance > 0) {
          // Last trip mileage: distance of last trip / (fuel consumed - skip last entry fuel)
          if (sortedEntries.length >= 2) {
            final lastEntry = sortedEntries.last;
            final secondLastEntry = sortedEntries[sortedEntries.length - 2];
            
            if (lastEntry.odometerReading != null && secondLastEntry.odometerReading != null) {
              final lastTripDistance = lastEntry.odometerReading! - secondLastEntry.odometerReading!;
              if (lastTripDistance > 0) {
                // Skip the last entry fuel, use the second last entry fuel for this trip
                lastTripMileage = lastTripDistance / secondLastEntry.liters;
              }
            }
          }

          // Overall mileage: total distance / (total fuel - last entry fuel)
          final totalFuelExcludingLast = totalLiters - sortedEntries.last.liters;
          if (totalFuelExcludingLast > 0) {
            overallMileage = totalDistance / totalFuelExcludingLast;
          }
        }
      }

      setState(() {
        _totalCost = totalCost;
        _totalLiters = totalLiters;
        _totalEntries = entries.length;
        _averageMileage = averageMileage;
        _currentOdometer = currentOdometer;
        _lastTripMileage = lastTripMileage;
        _overallMileage = overallMileage;
        _totalDistance = totalDistance;
        _entries = entries..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await AuthService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
    });
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = await SyncService.getLastFullSync();
    if (mounted) {
      setState(() {
        _lastSyncTime = lastSync;
      });
    }
  }

  Future<void> _handleSync() async {
    if (!_isAuthenticated) {
      // Navigate to sign in screen
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));

      // If sign in was successful, immediately sync
      if (result == true) {
        await _checkAuthStatus();
        if (_isAuthenticated) {
          await _performSync();
        }
      }
    } else {
      // User is already signed in, just sync
      await _performSync();
    }
  }

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await SyncService.fullSync();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data synced successfully!'), backgroundColor: Colors.green));
        _loadSummaryData();
        _loadLastSyncTime();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
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
                                    _loadSummaryData();
                                    _checkAuthStatus();
                                    _loadCurrency();
                                    _loadLastSyncTime();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // // Stats Cards with staggered animation
                  // StaggeredAnimationWrapper(
                  //   index: 0,
                  //   animation: _staggeredAnimation,
                  //   child: GridView.count(
                  //     shrinkWrap: true,
                  //     physics: const NeverScrollableScrollPhysics(),
                  //     crossAxisCount: 2,
                  //     mainAxisSpacing: 12,
                  //     crossAxisSpacing: 12,
                  //     childAspectRatio: 1.2,
                  //     children: [
                  //       StatCard(
                  //         icon: Icons.attach_money,
                  //         title: 'Total Spent',
                  //         value: '$_currency${_totalCost.toStringAsFixed(2)}',
                  //         color: Colors.red,
                  //         backgroundColor: const Color(0xFFE91E63),
                  //         onTap: () async {
                  //           await Navigator.push(
                  //             context,
                  //             MaterialPageRoute(builder: (context) => const FuelHistoryScreen()),
                  //           );
                  //           _loadSummaryData();
                  //           _loadLastSyncTime();
                  //         },
                  //       ),
                  //       StatCard(
                  //         icon: Icons.local_gas_station,
                  //         title: 'Total Liters',
                  //         value: '${_totalLiters.toStringAsFixed(1)}L',
                  //         color: Colors.blue,
                  //         backgroundColor: const Color(0xFF2196F3),
                  //         onTap: () async {
                  //           await Navigator.push(
                  //             context,
                  //             MaterialPageRoute(builder: (context) => const FuelHistoryScreen()),
                  //           );
                  //           _loadSummaryData();
                  //           _loadLastSyncTime();
                  //         },
                  //       ),
                  //       StatCard(
                  //         icon: Icons.list_alt,
                  //         title: 'Fuel Entries',
                  //         value: '$_totalEntries',
                  //         color: Colors.green,
                  //         backgroundColor: const Color(0xFF4CAF50),
                  //         onTap: () async {
                  //           await Navigator.push(
                  //             context,
                  //             MaterialPageRoute(builder: (context) => const FuelHistoryScreen()),
                  //           );
                  //           _loadSummaryData();
                  //           _loadLastSyncTime();
                  //         },
                  //       ),
                  //       StatCard(
                  //         icon: _averageMileage != null ? Icons.trending_up : Icons.speed,
                  //         title: _averageMileage != null ? 'Average Mileage' : 'Current Odometer',
                  //         value: _averageMileage != null
                  //             ? '${_averageMileage!.toStringAsFixed(1)} km/L'
                  //             : _currentOdometer != null
                  //             ? '${_currentOdometer!.toStringAsFixed(0)} km'
                  //             : 'No data',
                  //         color: Colors.orange,
                  //         backgroundColor: const Color(0xFFFF9800),
                  //         onTap: _averageMileage != null
                  //             ? () async {
                  //                 await Navigator.push(
                  //                   context,
                  //                   MaterialPageRoute(builder: (context) => const FuelHistoryScreen()),
                  //                 );
                  //                 _loadSummaryData();
                  //                 _loadLastSyncTime();
                  //               }
                  //             : null,
                  //       ),
                  //     ],
                  //   ),
                  // ),
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
                            _buildSummaryLine(
                              icon: Icons.payments_rounded,
                              label: 'Total Cost',
                              value: '$_currency${_totalCost.toStringAsFixed(2)}',
                              color: const Color(0xFFE91E63),
                            ),

                            const SizedBox(height: 16),

                            // Liters Line
                            _buildSummaryLine(
                              icon: Icons.local_gas_station_rounded,
                              label: 'Total Liters',
                              value: '${_totalLiters.toStringAsFixed(1)}L',
                              color: const Color(0xFF2196F3),
                            ),

                            const SizedBox(height: 16),

                            // Distance Line
                            _buildSummaryLine(
                              icon: Icons.route_rounded,
                              label: 'Total Distance',
                              value: _totalDistance > 0 ? '${_totalDistance.toStringAsFixed(0)} km' : 'N/A',
                              color: const Color(0xFFFF9800),
                            ),

                            const SizedBox(height: 16),

                            // Last Trip Mileage Line
                            _buildSummaryLine(
                              icon: Icons.directions_car_rounded,
                              label: 'Last Trip Mileage',
                              value: _lastTripMileage > 0 ? '${_lastTripMileage.toStringAsFixed(1)} km/L' : 'N/A',
                              color: const Color(0xFF4CAF50),
                            ),

                            const SizedBox(height: 16),

                            // Overall Mileage Line
                            _buildSummaryLine(
                              icon: Icons.trending_up_rounded,
                              label: 'Overall Mileage',
                              value: _overallMileage > 0 ? '${_overallMileage.toStringAsFixed(1)} km/L' : 'N/A',
                              color: const Color(0xFF9C27B0),
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
                    child: FuelChartDashboard(entries: _entries, currency: _currency),
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
                        _loadSummaryData();
                        _loadLastSyncTime();
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
                        _loadSummaryData();
                        _loadLastSyncTime();
                      },
                      color: const Color.fromARGB(255, 11, 141, 53),
                    ),
                  ),

                  StaggeredAnimationWrapper(
                    index: 6,
                    animation: _staggeredAnimation,
                    child: SyncButton(
                      isSyncing: _isSyncing,
                      isAuthenticated: _isAuthenticated,
                      onPressed: _handleSync,
                      lastSyncTime: _lastSyncTime,
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
