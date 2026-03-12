import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fuel_entry.dart';
import '../models/vehicle.dart';
import '../services/fuel_storage_service.dart';
import '../services/currency_service.dart';
import '../services/vehicle_service.dart';
import '../services/drive_backup_service.dart';
import '../widgets/widgets.dart';

class AddFuelScreen extends StatefulWidget {
  final FuelEntry? existingEntry;

  const AddFuelScreen({super.key, this.existingEntry});

  bool get isEditing => existingEntry != null;

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
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  String? _vehicleError;

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

    _loadCurrency();
    _loadVehicles();
    _litersController.addListener(_calculateMileage);
    _odometerController.addListener(_calculateMileage);

    // Pre-populate fields if editing
    if (widget.isEditing) {
      final entry = widget.existingEntry!;
      _litersController.text = entry.liters.toString();
      _priceController.text = entry.pricePerLiter.toString();
      if (entry.odometerReading != null) {
        _odometerController.text = entry.odometerReading.toString();
      }
    }

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
    _staggeredAnimationController.forward();
  }

  Future<void> _loadOdometerForVehicle(String? vehicleId) async {
    final odometer = await FuelStorageService.getLastOdometerForVehicle(vehicleId);
    if (mounted) {
      setState(() {
        _currentOdometer = odometer;
        if (!widget.isEditing) {
          _odometerController.text = odometer?.toString() ?? '';
        }
      });
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) {
      setState(() {
        _currency = currency;
      });
    }
  }

  Future<void> _loadVehicles() async {
    final vehicles = await VehicleService.getVehicles();
    String? selectedId;
    if (widget.isEditing) {
      selectedId = await VehicleService.getVehicleIdForEntry(widget.existingEntry!.id);
    } else {
      selectedId = await VehicleService.getSelectedVehicleId();
      // Default to last vehicle if none selected
      if (selectedId == null && vehicles.isNotEmpty) {
        selectedId = vehicles.last.id;
      }
    }
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _selectedVehicleId = selectedId;
      });
      _loadOdometerForVehicle(selectedId);
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

  static const Map<String, IconData> _vehicleIcons = {
    'directions_car': Icons.directions_car,
    'two_wheeler': Icons.two_wheeler,
    'local_shipping': Icons.local_shipping,
    'airport_shuttle': Icons.airport_shuttle,
    'electric_car': Icons.electric_car,
    'pedal_bike': Icons.pedal_bike,
  };

  IconData _vehicleSegmentIcon(String iconName) {
    return _vehicleIcons[iconName] ?? Icons.directions_car;
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

  Future<void> _showBackupPrompt() async {
    final isSignedIn = await DriveBackupService.isSignedIn();
    if (!mounted) return;

    // Auto backup silently if enabled and signed in
    if (isSignedIn && await DriveBackupService.isAutoBackupEnabled()) {
      try {
        await DriveBackupService.backupToDrive();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 12),
                Text('Auto backup successful!'),
              ]),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auto backup failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        bool isBackingUp = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isSignedIn ? Icons.cloud_upload : Icons.cloud_outlined,
                    color: isSignedIn ? Colors.green : const Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 10),
                  Text(isSignedIn ? 'Backup Data' : 'Backup to Cloud'),
                ],
              ),
              content: Text(
                isSignedIn
                    ? 'Would you like to backup your data to Google Drive?'
                    : 'Connect your Gmail to backup your fuel data to Google Drive.',
              ),
              actions: [
                TextButton(
                  onPressed: isBackingUp ? null : () => Navigator.pop(ctx),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: isBackingUp
                      ? null
                      : () async {
                          setDialogState(() => isBackingUp = true);
                          try {
                            if (isSignedIn) {
                              await DriveBackupService.backupToDrive();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(children: [
                                      Icon(Icons.cloud_done, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Backup successful!'),
                                    ]),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              }
                            } else {
                              final account = await DriveBackupService.signIn();
                              if (account != null) {
                                await DriveBackupService.backupToDrive();
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(children: [
                                        Icon(Icons.cloud_done, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Connected & backed up!'),
                                      ]),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }
                              } else {
                                setDialogState(() => isBackingUp = false);
                              }
                            }
                          } catch (e) {
                            setDialogState(() => isBackingUp = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${isSignedIn ? "Backup" : "Sign-in"} failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSignedIn ? Colors.green : const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isBackingUp
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isSignedIn ? 'Backup Now' : 'Connect Gmail'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveFuelEntry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleId == null) {
      setState(() => _vehicleError = 'Please select a vehicle');
      return;
    }

    setState(() {
      _isLoading = true;
      _vehicleError = null;
    });

    try {
      final liters = double.parse(_litersController.text);
      final pricePerLiter = double.parse(_priceController.text);
      final odometerReading = _odometerController.text.isEmpty ? null : double.parse(_odometerController.text);

      if (widget.isEditing) {
        final entry = widget.existingEntry!
          ..liters = liters
          ..pricePerLiter = pricePerLiter
          ..totalCost = liters * pricePerLiter
          ..odometerReading = odometerReading;

        await FuelStorageService.updateFuelEntry(entry);
        // Update vehicle assignment
        if (_selectedVehicleId != null) {
          await VehicleService.assignVehicleToEntry(entry.id, _selectedVehicleId!);
        }
      } else {
        final entry = FuelEntry.create(liters: liters, pricePerLiter: pricePerLiter, odometerReading: odometerReading);
        await FuelStorageService.saveFuelEntry(entry);
        // Assign vehicle to entry
        if (_selectedVehicleId != null) {
          await VehicleService.assignVehicleToEntry(entry.id, _selectedVehicleId!);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Fuel entry updated!' : 'Fuel entry saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        await _showBackupPrompt();
        if (mounted) Navigator.pop(context);
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
                                  widget.isEditing ? 'Edit Fuel Entry' : 'Add Fuel Entry',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  widget.isEditing ? 'Update your fuel entry' : 'Track your fuel consumption',
                                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Vehicle Selector (segmented buttons)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_vehicles.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.redAccent, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No vehicles added. Add one in Settings > Vehicles.',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _vehicleError != null
                                      ? Colors.redAccent
                                      : Colors.transparent,
                                  width: _vehicleError != null ? 2 : 0,
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _vehicles.map((v) {
                                      final isSelected = _selectedVehicleId == v.id;
                                      final iconData = _vehicleSegmentIcon(v.iconName);
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedVehicleId = v.id;
                                              _vehicleError = null;
                                            });
                                            _loadOdometerForVehicle(v.id);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white.withValues(alpha: 0.25),
                                                width: 1.5,
                                              ),
                                              boxShadow: isSelected
                                                  ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 2))]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  iconData,
                                                  size: 20,
                                                  color: isSelected ? const Color(0xFF667eea) : Colors.white.withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  v.name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                    color: isSelected ? const Color(0xFF667eea) : Colors.white.withValues(alpha: 0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          if (_vehicleError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
                              child: Text(
                                _vehicleError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (_vehicleError == null)
                            const SizedBox(height: 12),
                        ],
                      ),
                    ),

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
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 10),
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
                                      if (!widget.isEditing && _currentOdometer != null && number < _currentOdometer!) {
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

                    const SizedBox(height: 5),

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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.isEditing ? 'Update Entry' : 'Save Fuel Entry',
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
