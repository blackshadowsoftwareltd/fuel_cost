import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../providers/vehicle_provider.dart';

class VehicleManagementScreen extends ConsumerStatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  ConsumerState<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

const Map<String, IconData> _vehicleIconMap = {
  'directions_car': Icons.directions_car,
  'two_wheeler': Icons.two_wheeler,
  'local_shipping': Icons.local_shipping,
  'airport_shuttle': Icons.airport_shuttle,
  'electric_car': Icons.electric_car,
  'pedal_bike': Icons.pedal_bike,
};

class _VehicleManagementScreenState extends ConsumerState<VehicleManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _showVehicleDialog({Vehicle? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final tankController = TextEditingController(text: existing?.tankCapacity?.toString() ?? '');
    String selectedFuelType = existing?.fuelType ?? 'petrol';
    String selectedIcon = existing?.iconName ?? 'directions_car';

    String? nameError;

    final result = await showDialog<Vehicle?>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing != null ? 'Edit Vehicle' : 'Add Vehicle',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Name
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      onChanged: (_) {
                        if (nameError != null) {
                          setDialogState(() => nameError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Vehicle Name',
                        hintText: 'e.g. My Car',
                        prefixIcon: const Icon(Icons.label),
                        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : null),
                        hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : null),
                        errorText: nameError,
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Icon Selection
                    Text('Vehicle Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Vehicle.vehicleIcons.entries.map((entry) {
                        final isSelected = selectedIcon == entry.key;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF667eea).withValues(alpha: 0.15) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_vehicleIconMap[entry.key] ?? Icons.directions_car,
                                    color: isSelected ? const Color(0xFF667eea) : (isDark ? Colors.grey.shade400 : Colors.grey.shade600), size: 24),
                                const SizedBox(height: 2),
                                Text(entry.value.label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Fuel Type
                    Text('Fuel Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Vehicle.fuelTypes.entries.map((entry) {
                        final isSelected = selectedFuelType == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() => selectedFuelType = entry.key),
                          selectedColor: const Color(0xFF667eea).withValues(alpha: 0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Tank Capacity
                    TextField(
                      controller: tankController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
                      decoration: const InputDecoration(
                        labelText: 'Tank Capacity (L) - Optional',
                        prefixIcon: Icon(Icons.local_gas_station),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => nameError = 'Please enter a vehicle name');
                      return;
                    }
                    final vehicle = Vehicle(
                      id: existing?.id ?? VehicleService.generateId(),
                      name: name,
                      iconName: selectedIcon,
                      fuelType: selectedFuelType,
                      tankCapacity: double.tryParse(tankController.text),
                    );
                    Navigator.pop(context, vehicle);
                  },
                  child: Text(existing != null ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await VehicleService.saveVehicle(result);
      ref.invalidate(vehiclesProvider);
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete "${vehicle.name}"? Fuel entries will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VehicleService.deleteVehicle(vehicle.id);
      ref.invalidate(vehiclesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)]
                : [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Vehicles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Manage your vehicles', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _showVehicleDialog(),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: vehiclesAsync.when(
                      data: (vehicles) {
                        if (vehicles.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No vehicles added yet', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                const SizedBox(height: 8),
                                Text('Tap + to add your first vehicle', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () => _showVehicleDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Vehicle'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            return _buildVehicleCard(vehicle, isDark);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, bool isDark) {
    final fuelLabel = Vehicle.fuelTypes[vehicle.fuelType] ?? vehicle.fuelType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _vehicleIconMap[vehicle.iconName] ?? Icons.directions_car,
              color: const Color(0xFF667eea),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(fuelLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500)),
                    ),
                    if (vehicle.tankCapacity != null) ...[
                      const SizedBox(width: 8),
                      Text('${vehicle.tankCapacity!.toStringAsFixed(0)}L tank', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 20),
            onPressed: () => _showVehicleDialog(existing: vehicle),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _deleteVehicle(vehicle),
          ),
        ],
      ),
    );
  }
}
