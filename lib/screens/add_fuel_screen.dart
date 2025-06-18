import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/currency_service.dart';
import '../widgets/widgets.dart';

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  bool _isLoading = false;
  double? _currentOdometer;
  double? _estimatedMileage;
  Map<String, dynamic>? _calculationDetails;
  String _currency = '\$';

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _staggeredAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _staggeredAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnimationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scaleAnimationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _staggeredAnimationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut));

    _staggeredAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _staggeredAnimationController, curve: Curves.easeOutCubic));

    _loadCurrentOdometer();
    _loadCurrency();
    _litersController.addListener(_calculateMileage);
    _odometerController.addListener(_calculateMileage);

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
    _staggeredAnimationController.forward();
  }

  Future<void> _loadCurrentOdometer() async {
    final odometer = await FuelStorageService.getCurrentOdometer();
    setState(() {
      _currentOdometer = odometer;
      if (odometer != null) {
        _odometerController.text = odometer.toString();
      }
    });
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) {
      setState(() {
        _currency = currency;
      });
    }
  }

  void _calculateMileage() {
    final liters = double.tryParse(_litersController.text);
    final odometer = double.tryParse(_odometerController.text);

    if (liters != null && liters > 0 && odometer != null) {
      FuelStorageService.getMileageCalculationDetails(liters, odometer).then((details) {
        if (mounted) {
          setState(() {
            _calculationDetails = details;
            _estimatedMileage = details?['mileage'];
          });
        }
      });
    } else {
      setState(() {
        _estimatedMileage = null;
        _calculationDetails = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    _staggeredAnimationController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _odometerController.dispose();
    super.dispose();
  }



  Future<void> _saveFuelEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final liters = double.parse(_litersController.text);
      final pricePerLiter = double.parse(_priceController.text);
      final odometerReading = _odometerController.text.isEmpty ? null : double.parse(_odometerController.text);

      final entry = FuelEntry.create(liters: liters, pricePerLiter: pricePerLiter, odometerReading: odometerReading);

      await FuelStorageService.saveFuelEntry(entry);

      // Try to upload to server if user is authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      if (isAuthenticated) {
        try {
          await SyncService.uploadEntry(entry);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fuel entry saved and synced successfully!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Entry saved locally. Sync failed: $e'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fuel entry saved locally! Sign in to sync with server.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving entry: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section with fade animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Fuel Entry',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Track your fuel consumption',
                                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Fields with scale animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              StaggeredAnimationWrapper(
                                index: 0,
                                animation: _staggeredAnimation,
                                child: GlassTextField(
                                  controller: _litersController,
                                  label: 'Fuel Amount (Liters)',
                                  icon: Icons.local_gas_station,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter fuel amount';
                                    }
                                    final number = double.tryParse(value);
                                    if (number == null || number <= 0) {
                                      return 'Please enter a valid positive number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              StaggeredAnimationWrapper(
                                index: 1,
                                animation: _staggeredAnimation,
                                child: GlassTextField(
                                  controller: _priceController,
                                  label: 'Price per Liter',
                                  icon: Icons.attach_money,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter price per liter';
                                    }
                                    final number = double.tryParse(value);
                                    if (number == null || number <= 0) {
                                      return 'Please enter a valid positive number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              StaggeredAnimationWrapper(
                                index: 2,
                                animation: _staggeredAnimation,
                                child: GlassTextField(
                                  controller: _odometerController,
                                  label: _currentOdometer != null
                                      ? 'Current Odometer Reading (km)'
                                      : 'Odometer Reading (km) - Optional',
                                  icon: Icons.speed,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
                                  helperText: _currentOdometer != null
                                      ? 'Last recorded: ${_currentOdometer!.toStringAsFixed(0)} km'
                                      : null,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final number = double.tryParse(value);
                                      if (number == null || number < 0) {
                                        return 'Please enter a valid positive number';
                                      }
                                      if (_currentOdometer != null && number < _currentOdometer!) {
                                        return 'Odometer reading cannot be less than last recorded (${_currentOdometer!.toStringAsFixed(0)} km)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preview Cards with staggered animations
                    if (_litersController.text.isNotEmpty && _priceController.text.isNotEmpty)
                      StaggeredAnimationWrapper(
                        index: 3,
                        delay: 0.15,
                        animation: _staggeredAnimation,
                        child: Column(
                          children: [
                            FuelSummaryCard(
                              currency: _currency,
                              liters: double.tryParse(_litersController.text) ?? 0,
                              pricePerLiter: double.tryParse(_priceController.text) ?? 0,
                              estimatedMileage: _estimatedMileage,
                            ),

                            if (_calculationDetails != null) ...[
                              const SizedBox(height: 16),
                              StaggeredAnimationWrapper(
                                index: 4,
                                delay: 0.15,
                                animation: _staggeredAnimation,
                                child: MileageCalculationCard(
                                  calculationDetails: _calculationDetails!,
                                  formatDate: _formatDate,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Save Button with staggered and bounce animation
                    StaggeredAnimationWrapper(
                      index: 5,
                      delay: 0.12,
                      animation: _staggeredAnimation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _scaleAnimationController,
                            curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color.fromARGB(255, 64, 169, 255), Color.fromARGB(255, 92, 225, 255)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveFuelEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Save Fuel Entry',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
