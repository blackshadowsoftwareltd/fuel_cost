import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/maintenance_provider.dart';
import '../services/maintenance_service.dart';
import '../services/vehicle_service.dart';
import '../models/maintenance_entry.dart';
import '../models/vehicle.dart';
import '../services/currency_service.dart';

const Map<String, IconData> _maintenanceIconMap = {
  'oil_change': Icons.oil_barrel,
  'tire_rotation': Icons.tire_repair,
  'brake_service': Icons.do_not_touch,
  'air_filter': Icons.air,
  'transmission': Icons.settings,
  'battery': Icons.battery_charging_full,
  'coolant': Icons.water_drop,
  'spark_plugs': Icons.flash_on,
  'belt_replacement': Icons.rotate_right,
  'wheel_alignment': Icons.straighten,
  'suspension': Icons.swap_vert,
  'exhaust': Icons.cloud,
  'ac_service': Icons.ac_unit,
  'wiper_blades': Icons.water,
  'headlights': Icons.lightbulb,
  'car_wash': Icons.local_car_wash,
  'detailing': Icons.auto_awesome,
  'inspection': Icons.fact_check,
  'insurance': Icons.shield,
  'registration': Icons.assignment,
  'towing': Icons.rv_hookup,
  'general_service': Icons.build,
  'body_repair': Icons.format_paint,
  'other': Icons.handyman,
};

class MaintenanceLogScreen extends ConsumerStatefulWidget {
  const MaintenanceLogScreen({super.key});

  @override
  ConsumerState<MaintenanceLogScreen> createState() =>
      _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends ConsumerState<MaintenanceLogScreen>
    with SingleTickerProviderStateMixin {
  List<Vehicle> _vehicles = [];
  String _currency = '\$';
  String? _selectedFilterVehicleId;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _loadCurrency();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await VehicleService.getVehicles();
    if (mounted) setState(() => _vehicles = vehicles);
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getVehicleName(String? vehicleId) {
    if (vehicleId == null) return '';
    try {
      return _vehicles.firstWhere((v) => v.id == vehicleId).name;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(maintenanceEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460)
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFF2196F3)
                  ],
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
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Maintenance Log',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Track your vehicle services',
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Colors.white.withValues(alpha: 0.8))),
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
                        onPressed: () => _showMaintenanceDialog(),
                        tooltip: 'Add Service',
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121212)
                        : Colors.grey.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: entriesAsync.when(
                    data: (allEntries) {
                      if (allEntries.isEmpty) {
                        return _buildEmptyState(isDark);
                      }
                      final filtered = _selectedFilterVehicleId == null
                          ? allEntries
                          : allEntries.where((e) => e.vehicleId == _selectedFilterVehicleId).toList();
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard(filtered, isDark),
                              const SizedBox(height: 16),
                              ...filtered.map(
                                  (entry) => _buildEntryCard(entry, isDark)),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined,
              size: 80,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No maintenance records yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Tap + to add your first service record',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<MaintenanceEntry> entries, bool isDark) {
    final totalCost = MaintenanceService.getTotalMaintenanceCost(entries);
    final recordCount = entries.length;
    final mostRecent = entries.isEmpty
        ? null
        : entries.map((e) => e.dateTime).reduce((a, b) => a.isAfter(b) ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 12),
          // Vehicle filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: _selectedFilterVehicleId == null,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedFilterVehicleId = null),
                ),
                ..._vehicles.map((v) => _buildFilterChip(
                      label: v.name,
                      isSelected: _selectedFilterVehicleId == v.id,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedFilterVehicleId = v.id),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                    'Total Cost',
                    '$_currency${totalCost.toStringAsFixed(0)}',
                    const Color(0xFFE91E63),
                    isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile('Records', '$recordCount',
                    const Color(0xFF2196F3), isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                    'Last Service',
                    mostRecent != null
                        ? DateFormat('MMM d, yyyy').format(mostRecent)
                        : 'N/A',
                    const Color(0xFF9C27B0),
                    isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF667eea)
                : isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF667eea)
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildEntryCard(MaintenanceEntry entry, bool isDark) {
    final icon = _maintenanceIconMap[entry.type] ?? Icons.handyman;
    final typeLabel =
        MaintenanceEntry.maintenanceTypes[entry.type] ?? 'Other';
    final vehicleName = _getVehicleName(entry.vehicleId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showMaintenanceDialog(entry: entry),
        onLongPress: () => _showDeleteConfirmation(entry),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
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
                  icon,
                  color: const Color(0xFF667eea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : Colors.grey.shade800)),
                    if (entry.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(entry.description,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                            DateFormat('MMM d, yyyy').format(entry.dateTime),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade500)),
                        if (vehicleName.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.directions_car,
                              size: 12,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(vehicleName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500)),
                        ],
                        if (entry.mileage != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.speed,
                              size: 12,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('${entry.mileage!.toStringAsFixed(0)} km',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$_currency${entry.cost.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF667eea))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(MaintenanceEntry entry) async {
    final typeLabel =
        MaintenanceEntry.maintenanceTypes[entry.type] ?? 'Other';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete "$typeLabel"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await MaintenanceService.deleteMaintenanceEntry(entry.id);
      ref.invalidate(maintenanceEntriesProvider);
    }
  }

  List<Widget> _buildTypeRows(
      String selectedType, bool isDark, void Function(String) onSelect) {
    final allTypes = MaintenanceEntry.maintenanceTypes.entries.toList();
    final rowCount = 3;
    final perRow = (allTypes.length / rowCount).ceil();
    final rows = <Widget>[];

    for (int r = 0; r < rowCount; r++) {
      final start = r * perRow;
      final end = (start + perRow).clamp(0, allTypes.length);
      if (start >= allTypes.length) break;
      final rowItems = allTypes.sublist(start, end);

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: r < rowCount - 1 ? 6 : 0),
          child: Row(
            children: rowItems.map((e) {
              final isSelected = selectedType == e.key;
              final typeIcon =
                  _maintenanceIconMap[e.key] ?? Icons.handyman;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF667eea).withValues(alpha: 0.15)
                          : isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF667eea)
                            : isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeIcon,
                          size: 16,
                          color: isSelected
                              ? const Color(0xFF667eea)
                              : isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF667eea)
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
            }).toList(),
          ),
        ),
      );
    }

    return rows;
  }

  Future<void> _showMaintenanceDialog({MaintenanceEntry? entry}) async {
    final isEditing = entry != null;
    String selectedType = entry?.type ?? 'oil_change';
    final costController = TextEditingController(
        text: entry != null ? entry.cost.toStringAsFixed(2) : '');
    final notesController =
        TextEditingController(text: entry?.notes ?? '');
    DateTime selectedDate = entry?.dateTime ?? DateTime.now();
    String? selectedVehicleId = entry?.vehicleId;

    await showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Service' : 'Add Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    Text('Service Type',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildTypeRows(
                            selectedType,
                            isDark,
                            (key) => setDialogState(() => selectedType = key),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cost
                    TextField(
                      controller: costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9]*\.?[0-9]*'))
                      ],
                      decoration: InputDecoration(
                        labelText: 'Cost ($_currency)',
                        prefixIcon: const Icon(Icons.attach_money),
                        hintText: 'e.g. 150',
                      ),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                              const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(selectedDate),
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle (required)
                    DropdownButtonFormField<String>(
                      initialValue: selectedVehicleId,
                      decoration: InputDecoration(
                        labelText: 'Vehicle *',
                        prefixIcon: const Icon(Icons.directions_car),
                        errorText: selectedVehicleId == null
                            ? 'Please select a vehicle'
                            : null,
                      ),
                      items: _vehicles.map((v) => DropdownMenuItem<String>(
                            value: v.id,
                            child: Text(v.name),
                          )).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedVehicleId = value);
                      },
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                        hintText: 'Any additional notes...',
                      ),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: selectedVehicleId == null
                      ? null
                      : () async {
                    final cost = double.tryParse(costController.text) ?? 0;
                    if (cost <= 0) return;

                    final newEntry = MaintenanceEntry(
                      id: entry?.id ?? MaintenanceService.generateId(),
                      vehicleId: selectedVehicleId,
                      type: selectedType,
                      description: '',
                      cost: cost,
                      dateTime: selectedDate,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    await MaintenanceService.saveMaintenanceEntry(newEntry);
                    ref.invalidate(maintenanceEntriesProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
