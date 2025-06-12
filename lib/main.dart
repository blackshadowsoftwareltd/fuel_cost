import 'package:flutter/material.dart';
import 'screens/add_fuel_screen.dart';
import 'screens/fuel_history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/fuel_storage_service.dart';

void main() {
  runApp(const FuelCostApp());
}

class FuelCostApp extends StatelessWidget {
  const FuelCostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Cost Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), 
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        
        // Enhanced AppBar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        
        // Enhanced ElevatedButton theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Enhanced Card theme
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        
        // Enhanced FloatingActionButton theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        
        // Enhanced Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        
        // Enhanced Dialog theme
        dialogTheme: DialogThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Enhanced SnackBar theme
        snackBarTheme: SnackBarThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalCost = 0.0;
  double _totalLiters = 0.0;
  int _totalEntries = 0;
  double? _averageMileage;
  double? _currentOdometer;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor.withValues(alpha: 0.8), backgroundColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: backgroundColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isPrimary
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : color.withValues(alpha: 0.1),
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2196F3).withValues(alpha: 0.1), const Color(0xFF21CBF3).withValues(alpha: 0.05), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fuel Tracker',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                          Text(
                            'Monitor your fuel efficiency',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
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
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Stats Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        icon: Icons.attach_money,
                        title: 'Total Spent',
                        value: '\$${_totalCost.toStringAsFixed(2)}',
                        color: Colors.red,
                        backgroundColor: const Color(0xFFE91E63),
                      ),
                      _buildStatCard(
                        icon: Icons.local_gas_station,
                        title: 'Total Liters',
                        value: '${_totalLiters.toStringAsFixed(1)}L',
                        color: Colors.blue,
                        backgroundColor: const Color(0xFF2196F3),
                      ),
                      _buildStatCard(
                        icon: Icons.list_alt,
                        title: 'Fuel Entries',
                        value: '$_totalEntries',
                        color: Colors.green,
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      _buildStatCard(
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

                  const SizedBox(height: 40),

                  // Action Buttons
                  Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 20),

                  _buildActionButton(
                    icon: Icons.add_circle,
                    title: 'Add Fuel Entry',
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFuelScreen()));
                      _loadSummaryData();
                    },
                    color: const Color(0xFF2196F3),
                    isPrimary: true,
                  ),

                  _buildActionButton(
                    icon: Icons.history,
                    title: 'View Fuel History',
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const FuelHistoryScreen()));
                      _loadSummaryData();
                    },
                    color: const Color(0xFF4CAF50),
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
