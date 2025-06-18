import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
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
  bool _isAuthenticated = false;
  bool _isSyncing = false;
  String _currency = '\$';

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
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggeredAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _staggeredAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggeredAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _loadSummaryData();
    _checkAuthStatus();
    _loadCurrency();

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

      setState(() {
        _totalCost = totalCost;
        _totalLiters = totalLiters;
        _totalEntries = entries.length;
        _averageMileage = averageMileage;
        _currentOdometer = currentOdometer;
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

  Future<void> _handleSync() async {
    if (!_isAuthenticated) {
      // Navigate to sign in screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSummaryData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
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
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Cards with staggered animation
                  StaggeredAnimationWrapper(
                    index: 0,
                    animation: _staggeredAnimation,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        StatCard(
                          icon: Icons.attach_money,
                          title: 'Total Spent',
                          value: '$_currency${_totalCost.toStringAsFixed(2)}',
                          color: Colors.red,
                          backgroundColor: const Color(0xFFE91E63),
                        ),
                        StatCard(
                          icon: Icons.local_gas_station,
                          title: 'Total Liters',
                          value: '${_totalLiters.toStringAsFixed(1)}L',
                          color: Colors.blue,
                          backgroundColor: const Color(0xFF2196F3),
                        ),
                        StatCard(
                          icon: Icons.list_alt,
                          title: 'Fuel Entries',
                          value: '$_totalEntries',
                          color: Colors.green,
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        StatCard(
                          icon: _averageMileage != null ? Icons.trending_up : Icons.speed,
                          title: _averageMileage != null ? 'Average Mileage' : 'Current Odometer',
                          value: _averageMileage != null
                              ? '${_averageMileage!.toStringAsFixed(1)} km/L'
                              : _currentOdometer != null
                              ? '${_currentOdometer!.toStringAsFixed(0)} km'
                              : 'No data',
                          color: Colors.orange,
                          backgroundColor: const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action Buttons section with staggered animation
                  StaggeredAnimationWrapper(
                    index: 1,
                    animation: _staggeredAnimation,
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),

                  StaggeredAnimationWrapper(
                    index: 2,
                    animation: _staggeredAnimation,
                    child: ActionButton(
                      icon: Icons.add_circle,
                      title: 'Add Fuel Entry',
                      subtitle: _getButtonSubtitle('Add Fuel Entry'),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFuelScreen()));
                        _loadSummaryData();
                      },
                      color: const Color(0xFF2196F3),
                      isPrimary: true,
                    ),
                  ),

                  StaggeredAnimationWrapper(
                    index: 3,
                    animation: _staggeredAnimation,
                    child: ActionButton(
                      icon: Icons.history,
                      title: 'View Fuel History',
                      subtitle: _getButtonSubtitle('View Fuel History'),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const FuelHistoryScreen()));
                        _loadSummaryData();
                      },
                      color: const Color(0xFF4CAF50),
                    ),
                  ),

                  StaggeredAnimationWrapper(
                    index: 4,
                    animation: _staggeredAnimation,
                    child: SyncButton(
                      isSyncing: _isSyncing,
                      isAuthenticated: _isAuthenticated,
                      onPressed: _handleSync,
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