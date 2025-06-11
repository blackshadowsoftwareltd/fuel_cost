import 'package:flutter/material.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  bool _isLoading = false;
  double? _currentOdometer;
  double? _estimatedMileage;
  Map<String, dynamic>? _calculationDetails;

  @override
  void initState() {
    super.initState();
    _loadCurrentOdometer();
    _litersController.addListener(_calculateMileage);
    _odometerController.addListener(_calculateMileage);
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

  Widget _buildCalculationRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
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
      final odometerReading = _odometerController.text.isEmpty 
          ? null 
          : double.parse(_odometerController.text);

      final entry = FuelEntry.create(
        liters: liters,
        pricePerLiter: pricePerLiter,
        odometerReading: odometerReading,
      );

      await FuelStorageService.saveFuelEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2196F3).withOpacity(0.1),
              const Color(0xFF21CBF3).withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                    // Header Section
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
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
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              'Track your fuel consumption',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    // Form Fields
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _litersController,
                            decoration: InputDecoration(
                              labelText: 'Fuel Amount (Liters)',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_gas_station, color: Color(0xFF2196F3)),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
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
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Price per Liter',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.attach_money, color: Color(0xFF4CAF50)),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
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
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _odometerController,
                            decoration: InputDecoration(
                              labelText: _currentOdometer != null 
                                  ? 'Current Odometer Reading (km)' 
                                  : 'Odometer Reading (km) - Optional',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.speed, color: Color(0xFFFF9800)),
                              ),
                              helperText: _currentOdometer != null 
                                  ? 'Last recorded: ${_currentOdometer!.toStringAsFixed(0)} km'
                                  : null,
                              helperStyle: TextStyle(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
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
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Preview Cards
                    if (_litersController.text.isNotEmpty && _priceController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4CAF50).withOpacity(0.8),
                              const Color(0xFF4CAF50).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Fill-up Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'Total Cost',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${((double.tryParse(_litersController.text) ?? 0) * (double.tryParse(_priceController.text) ?? 0)).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_estimatedMileage != null) ...[
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white30,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'Mileage',
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_estimatedMileage!.toStringAsFixed(1)} km/L',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (_calculationDetails != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.calculate, color: Color(0xFF2196F3), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Mileage Calculation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildCalculationRow(
                                'Distance Traveled:',
                                '${_calculationDetails!['currentOdometer'].toStringAsFixed(0)} km - ${_calculationDetails!['lastOdometer'].toStringAsFixed(0)} km = ${_calculationDetails!['distance'].toStringAsFixed(1)} km',
                              ),
                              const SizedBox(height: 12),
                              _buildCalculationRow(
                                'Fuel Efficiency:',
                                '${_calculationDetails!['distance'].toStringAsFixed(1)} km ÷ ${_calculationDetails!['liters'].toStringAsFixed(1)} L = ${_calculationDetails!['mileage'].toStringAsFixed(2)} km/L',
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Since last fill-up: ${_formatDate(_calculationDetails!['lastFuelDate'])}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.4),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
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