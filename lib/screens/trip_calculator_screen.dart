import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/summary_providers.dart';
import '../providers/fuel_entries_provider.dart';
import '../services/currency_service.dart';

class TripCalculatorScreen extends ConsumerStatefulWidget {
  const TripCalculatorScreen({super.key});

  @override
  ConsumerState<TripCalculatorScreen> createState() => _TripCalculatorScreenState();
}

class _TripCalculatorScreenState extends ConsumerState<TripCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _distanceController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _customMileageController = TextEditingController();
  bool _useCustomPrice = false;
  bool _useCustomMileage = false;
  String _currency = '\$';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _animController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _animController.dispose();
    _distanceController.dispose();
    _customPriceController.dispose();
    _customMileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mileageAsync = ref.watch(mileageCalculationsProvider);
    final entriesAsync = ref.watch(fuelEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)]
                      : [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Cost Calculator',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Estimate your trip fuel cost',
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Distance Input
                        _buildTextField(
                          controller: _distanceController,
                          label: 'Trip Distance (km)',
                          icon: Icons.route_rounded,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 16),

                        // Custom Price Toggle
                        _buildToggleRow(
                          label: 'Use custom fuel price',
                          value: _useCustomPrice,
                          onChanged: (v) => setState(() => _useCustomPrice = v),
                          isDark: isDark,
                        ),
                        if (_useCustomPrice) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _customPriceController,
                            label: 'Fuel Price ($_currency/L)',
                            icon: Icons.attach_money,
                            isDark: isDark,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Custom Mileage Toggle
                        _buildToggleRow(
                          label: 'Use custom mileage',
                          value: _useCustomMileage,
                          onChanged: (v) => setState(() => _useCustomMileage = v),
                          isDark: isDark,
                        ),
                        if (_useCustomMileage) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _customMileageController,
                            label: 'Mileage (km/L)',
                            icon: Icons.speed,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Results Card
                  mileageAsync.when(
                    data: (calculations) => entriesAsync.when(
                      data: (entries) {
                        final distance = double.tryParse(_distanceController.text);
                        if (distance == null || distance <= 0) {
                          return _buildPromptCard(isDark);
                        }

                        final mileage = _useCustomMileage
                            ? (double.tryParse(_customMileageController.text) ?? 0)
                            : calculations['overallMileage']!;

                        if (mileage <= 0) {
                          return _buildNoDataCard('Not enough data to calculate mileage. Enter custom mileage or add more fuel entries.', isDark);
                        }

                        // Get average price from entries
                        double avgPrice = 0;
                        if (entries.isNotEmpty) {
                          avgPrice = entries.map((e) => e.pricePerLiter).reduce((a, b) => a + b) / entries.length;
                        }
                        final price = _useCustomPrice
                            ? (double.tryParse(_customPriceController.text) ?? avgPrice)
                            : avgPrice;

                        if (price <= 0) {
                          return _buildNoDataCard('No fuel price data available. Enter a custom price.', isDark);
                        }

                        final litersNeeded = distance / mileage;
                        final estimatedCost = litersNeeded * price;
                        final costPerKm = estimatedCost / distance;

                        return _buildResultsCard(
                          distance: distance,
                          mileage: mileage,
                          price: price,
                          litersNeeded: litersNeeded,
                          estimatedCost: estimatedCost,
                          costPerKm: costPerKm,
                          isDark: isDark,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
        Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: const Color(0xFF667eea)),
      ],
    );
  }

  Widget _buildPromptCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Icon(Icons.calculate_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Enter trip distance to calculate',
            style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.orange.shade400),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildResultsCard({
    required double distance,
    required double mileage,
    required double price,
    required double litersNeeded,
    required double estimatedCost,
    required double costPerKm,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 24),
              ),
              const SizedBox(width: 12),
              Text('Trip Estimate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
            ],
          ),
          const SizedBox(height: 20),

          // Main Cost Display
          Center(
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$_currency${estimatedCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF667eea),
                    ),
                  ),
                ),
                Text(
                  'Estimated Total Cost',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details Grid
          _buildDetailRow(Icons.local_gas_station, 'Fuel Needed', '${litersNeeded.toStringAsFixed(1)} L', const Color(0xFF2196F3), isDark),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.route_rounded, 'Distance', '${distance.toStringAsFixed(0)} km', const Color(0xFFFF9800), isDark),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.speed, 'Mileage Used', '${mileage.toStringAsFixed(1)} km/L', const Color(0xFF4CAF50), isDark),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.attach_money, 'Fuel Price', '$_currency${price.toStringAsFixed(2)}/L', const Color(0xFFE91E63), isDark),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.trending_up, 'Cost per km', '$_currency${costPerKm.toStringAsFixed(2)}/km', const Color(0xFF9C27B0), isDark),

          const SizedBox(height: 20),

          // Round Trip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: isDark ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFF667eea)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round Trip', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800)),
                      Text(
                        '$_currency${(estimatedCost * 2).toStringAsFixed(2)} for ${(distance * 2).toStringAsFixed(0)} km',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800)),
      ],
    );
  }
}
