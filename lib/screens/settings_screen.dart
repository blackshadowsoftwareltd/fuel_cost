import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/fuel_storage_service.dart';
import '../services/currency_service.dart';
import '../services/drive_backup_service.dart';
import '../services/budget_service.dart';
import '../services/theme_service.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../providers/theme_provider.dart';
import '../widgets/widgets.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _loadingAction;
  String _selectedCurrency = '\$';
  bool _isGoogleSignedIn = false;
  String? _googleEmail;
  DateTime? _lastBackupTime;
  bool _autoBackupEnabled = false;
  double? _monthlyBudget;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _checkGoogleDriveStatus();
    _loadBudget();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) setState(() => _selectedCurrency = currency);
  }

  Future<void> _loadBudget() async {
    final budget = await BudgetService.getMonthlyBudget();
    if (mounted) setState(() => _monthlyBudget = budget);
  }

  Future<void> _showCurrencyDialog() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CurrencySelectionDialog(
          selectedCurrency: _selectedCurrency,
          onCurrencySelected: (currency) async {
            await CurrencyService.setSelectedCurrency(currency);
            await _loadCurrency();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Currency changed to $currency (${CurrencyService.getCurrencyName(currency)})'),
                  ]),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showBudgetDialog() async {
    final controller = TextEditingController(text: _monthlyBudget?.toStringAsFixed(0) ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))],
          decoration: InputDecoration(
            labelText: 'Budget ($_selectedCurrency)',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            hintText: 'e.g. 5000',
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        actions: [
          if (_monthlyBudget != null)
            TextButton(
              onPressed: () => Navigator.pop(context, -1.0),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result == -1.0) {
        await BudgetService.setMonthlyBudget(null);
        setState(() => _monthlyBudget = null);
      } else if (result > 0) {
        await BudgetService.setMonthlyBudget(result);
        setState(() => _monthlyBudget = result);
      }
    }
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    Color? confirmColor,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          onConfirm: onConfirm,
          confirmColor: confirmColor,
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    setState(() => _loadingAction = 'clearAllData');
    try {
      await FuelStorageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('All fuel data cleared successfully')]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing data: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _clearFuelEntries() async {
    setState(() => _loadingAction = 'clearEntries');
    try {
      await FuelStorageService.clearFuelEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Fuel entries cleared successfully')]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _clearOdometerData() async {
    setState(() => _loadingAction = 'clearOdometer');
    try {
      await FuelStorageService.clearCurrentOdometer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Odometer data cleared successfully')]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _loadingAction = 'clearCache');
    try {
      await FuelStorageService.clearAllSharedPreferences();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('All cache and preferences cleared')]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _exportCsv() async {
    final vehicles = await VehicleService.getVehicles();
    if (!mounted) return;

    // Show vehicle selection dialog
    final selectedVehicleId = await _showVehiclePickerDialog(
      title: 'Export Data',
      subtitle: 'Select which vehicle data to export',
      vehicles: vehicles,
    );
    if (selectedVehicleId == null) return; // User cancelled

    setState(() => _loadingAction = 'export');
    try {
      final allEntries = await FuelStorageService.getFuelEntries();

      List<FuelEntry> entriesToExport;
      String fileName;
      if (selectedVehicleId == '__all__') {
        entriesToExport = allEntries;
        fileName = 'fuel_entries_all.csv';
      } else {
        final entryIds = await VehicleService.getEntryIdsForVehicle(selectedVehicleId);
        entriesToExport = allEntries.where((e) => entryIds.contains(e.id)).toList();
        final vehicle = vehicles.firstWhere((v) => v.id == selectedVehicleId);
        fileName = 'fuel_entries_${vehicle.name.replaceAll(' ', '_').toLowerCase()}.csv';
      }

      if (entriesToExport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Row(children: [Icon(Icons.info_outline, color: Colors.white), SizedBox(width: 12), Text('No entries to export for this vehicle')]),
              backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('id,liters,pricePerLiter,totalCost,dateTime,odometerReading');
      for (final entry in entriesToExport) {
        buffer.writeln(
          '${entry.id},${entry.liters},${entry.pricePerLiter},${entry.totalCost},${entry.dateTime.toIso8601String()},${entry.odometerReading ?? ''}',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles([XFile(file.path)], text: 'Fuel Cost Export',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : const Rect.fromLTWH(0, 0, 100, 100));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Text('${entriesToExport.length} entries exported')]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Export CSV error: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _importCsv() async {
    final vehicles = await VehicleService.getVehicles();
    if (!mounted) return;

    // Show vehicle selection dialog for assigning imported entries
    final selectedVehicleId = await _showVehiclePickerDialog(
      title: 'Import Data',
      subtitle: 'Assign imported entries to a vehicle',
      vehicles: vehicles,
      showUnassigned: true,
    );
    if (selectedVehicleId == null) return; // User cancelled

    setState(() => _loadingAction = 'import');
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.single.path == null) {
        setState(() => _loadingAction = null);
        return;
      }
      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();

      // Parse and import entries
      final lines = csvContent.trim().split('\n');
      if (lines.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('CSV file is empty or invalid'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
        }
        return;
      }

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 5) continue;
        try {
          final entry = FuelEntry()
            ..id = parts[0]
            ..liters = double.parse(parts[1])
            ..pricePerLiter = double.parse(parts[2])
            ..totalCost = double.parse(parts[3])
            ..dateTime = DateTime.parse(parts[4])
            ..odometerReading = parts.length > 5 && parts[5].isNotEmpty ? double.parse(parts[5]) : null;

          await FuelStorageService.saveFuelEntry(entry);

          // Assign to selected vehicle if not "unassigned"
          if (selectedVehicleId != '__all__' && selectedVehicleId != '__none__') {
            await VehicleService.assignVehicleToEntry(entry.id, selectedVehicleId);
          }
          imported++;
        } catch (e) {
          debugPrint('Skipping invalid CSV row $i: $e');
        }
      }

      if (mounted) {
        final vehicleName = selectedVehicleId == '__all__' || selectedVehicleId == '__none__'
            ? ''
            : ' to ${vehicles.firstWhere((v) => v.id == selectedVehicleId).name}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('$imported entries imported$vehicleName'))]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing CSV: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  static const Map<String, IconData> _vehicleIconMap = {
    'directions_car': Icons.directions_car,
    'two_wheeler': Icons.two_wheeler,
    'local_shipping': Icons.local_shipping,
    'airport_shuttle': Icons.airport_shuttle,
    'electric_car': Icons.electric_car,
    'pedal_bike': Icons.pedal_bike,
  };

  /// Shows a dialog to pick a vehicle for export/import.
  /// Returns the vehicle ID, '__all__' for all vehicles, '__none__' for unassigned, or null if cancelled.
  Future<String?> _showVehiclePickerDialog({
    required String title,
    required String subtitle,
    required List<Vehicle> vehicles,
    bool showUnassigned = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                const SizedBox(height: 16),
                // All vehicles option
                _buildVehicleOption(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  label: 'All Vehicles',
                  subtitle: 'Include data from all vehicles',
                  color: const Color(0xFF667eea),
                  onTap: () => Navigator.pop(context, '__all__'),
                  isDark: isDark,
                ),
                if (showUnassigned)
                  _buildVehicleOption(
                    context: context,
                    icon: Icons.help_outline,
                    label: 'No Vehicle',
                    subtitle: 'Don\'t assign to any vehicle',
                    color: Colors.grey,
                    onTap: () => Navigator.pop(context, '__none__'),
                    isDark: isDark,
                  ),
                if (vehicles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  ...vehicles.map((v) => _buildVehicleOption(
                        context: context,
                        icon: _vehicleIconMap[v.iconName] ?? Icons.directions_car,
                        label: v.name,
                        subtitle: Vehicle.fuelTypes[v.fuelType] ?? v.fuelType,
                        color: const Color(0xFF2196F3),
                        onTap: () => Navigator.pop(context, v.id),
                        isDark: isDark,
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  Widget _buildVehicleOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _checkGoogleDriveStatus() async {
    try {
      final isSignedIn = await DriveBackupService.isSignedIn();
      final autoBackup = await DriveBackupService.isAutoBackupEnabled();
      DateTime? lastBackup;
      String? email;
      if (isSignedIn) {
        lastBackup = await DriveBackupService.getLastBackupTime();
        email = DriveBackupService.currentUser?.email;
      }
      if (mounted) setState(() { _isGoogleSignedIn = isSignedIn; _lastBackupTime = lastBackup; _googleEmail = email; _autoBackupEnabled = autoBackup; });
    } catch (e) {
      debugPrint('Google Drive status check failed: $e');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loadingAction = 'googleSignIn');
    try {
      final account = await DriveBackupService.signIn();
      if (account != null && mounted) {
        setState(() { _isGoogleSignedIn = true; _googleEmail = account.email; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Signed in as ${account.email}'))]),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _googleSignOut() async {
    setState(() => _loadingAction = 'googleSignOut');
    try {
      await DriveBackupService.signOut();
      if (mounted) {
        setState(() { _isGoogleSignedIn = false; _googleEmail = null; _lastBackupTime = null; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Disconnected from Google Drive')]),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _backupToDrive() async {
    setState(() => _loadingAction = 'backup');
    try {
      await DriveBackupService.backupToDrive();
      final now = DateTime.now();
      if (mounted) {
        setState(() => _lastBackupTime = now);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.cloud_done, color: Colors.white), SizedBox(width: 12), Text('Backup successful!')]),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _restoreFromDrive() async {
    setState(() => _loadingAction = 'restore');
    try {
      final count = await DriveBackupService.restoreFromDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.cloud_done, color: Colors.white), const SizedBox(width: 12), Text('Restored $count entries from backup')]),
          backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  String _formatBackupTime(DateTime time) => DateFormat('MMM dd, yyyy HH:mm').format(time);

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              // Custom AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
              ),

              // Content area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1E1E).withValues(alpha: 0.98), const Color(0xFF1E1E1E).withValues(alpha: 0.92)]
                          : [Colors.white.withValues(alpha: 0.98), Colors.white.withValues(alpha: 0.92)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.white.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 25, offset: const Offset(0, 15), spreadRadius: -5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 8),
                        Text('Manage your preferences and data', style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        const SizedBox(height: 24),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Appearance Section
                                CupertinoSection(
                                  title: 'Appearance',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: _getThemeIcon(themeState.themeMode),
                                      title: 'Theme',
                                      subtitle: 'Current: ${_getThemeLabel(themeState.themeMode)}',
                                      onTap: () => _showThemeDialog(),
                                      iconColor: const Color(0xFF9C27B0),
                                      isFirst: true, isLoading: false,
                                    ),
                                    CustomCupertinoListTile(
                                      icon: Icons.palette_outlined,
                                      title: 'Accent Color',
                                      subtitle: 'Customize app color',
                                      onTap: () => _showAccentColorDialog(),
                                      iconColor: themeState.accentColor,
                                      isLast: true, isLoading: false,
                                      trailing: Container(width: 24, height: 24, decoration: BoxDecoration(color: themeState.accentColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1))),
                                    ),
                                  ],
                                ),

                                // Preferences Section
                                CupertinoSection(
                                  title: 'Preferences',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: Icons.currency_exchange,
                                      title: 'Currency',
                                      subtitle: 'Current: $_selectedCurrency (${CurrencyService.getCurrencyName(_selectedCurrency)})',
                                      onTap: _showCurrencyDialog,
                                      iconColor: const Color(0xFF2196F3),
                                      isFirst: true,
                                    ),
                                    CustomCupertinoListTile(
                                      icon: Icons.account_balance_wallet,
                                      title: 'Monthly Budget',
                                      subtitle: _monthlyBudget != null ? '$_selectedCurrency${_monthlyBudget!.toStringAsFixed(0)} per month' : 'Not set',
                                      onTap: _showBudgetDialog,
                                      iconColor: const Color(0xFFFF9800),
                                      isLast: true, isLoading: false,
                                    ),
                                  ],
                                ),

                                // Export & Import Section
                                CupertinoSection(
                                  title: 'Export & Import',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: Icons.file_upload_outlined, title: 'Export to CSV', subtitle: 'Export all fuel entries as a CSV file',
                                      onTap: _exportCsv, iconColor: const Color(0xFF4CAF50), isFirst: true, isLoading: _loadingAction == 'export'),
                                    CustomCupertinoListTile(
                                      icon: Icons.file_download_outlined, title: 'Import from CSV', subtitle: 'Import fuel entries from a CSV file',
                                      onTap: _importCsv,
                                      iconColor: const Color(0xFF2196F3), isLast: true, isLoading: _loadingAction == 'import'),
                                  ],
                                ),

                                // Google Drive Backup Section
                                CupertinoSection(
                                  title: 'Google Drive Backup',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: _isGoogleSignedIn ? Icons.cloud_done : Icons.cloud_outlined,
                                      title: _isGoogleSignedIn ? 'Connected' : 'Connect Google Drive',
                                      subtitle: _isGoogleSignedIn
                                          ? '${_googleEmail ?? ''}\nLast backup: ${_lastBackupTime != null ? _formatBackupTime(_lastBackupTime!) : "Never"}'
                                          : 'Sign in to backup your data to Google Drive',
                                      onTap: _isGoogleSignedIn ? () {} : _googleSignIn,
                                      iconColor: _isGoogleSignedIn ? Colors.green : const Color(0xFF4285F4),
                                      isFirst: true, isLast: !_isGoogleSignedIn, isLoading: _loadingAction == 'googleSignIn',
                                      trailing: _isGoogleSignedIn
                                          ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 20)
                                          : Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: const Color(0xFF4285F4), borderRadius: BorderRadius.circular(16)),
                                              child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                                    ),
                                    if (_isGoogleSignedIn) ...[
                                      CustomCupertinoListTile(icon: Icons.cloud_upload, title: 'Backup Now', subtitle: 'Upload your data to Google Drive',
                                        onTap: _backupToDrive, iconColor: const Color(0xFF4CAF50), isLoading: _loadingAction == 'backup'),
                                      CustomCupertinoListTile(
                                        icon: Icons.backup,
                                        title: 'Auto Backup',
                                        subtitle: 'Automatically backup after saving an entry',
                                        onTap: () async {
                                          final newValue = !_autoBackupEnabled;
                                          await DriveBackupService.setAutoBackup(newValue);
                                          setState(() => _autoBackupEnabled = newValue);
                                        },
                                        iconColor: const Color(0xFF9C27B0),
                                        trailing: CupertinoSwitch(
                                          value: _autoBackupEnabled,
                                          activeTrackColor: const Color(0xFF9C27B0),
                                          onChanged: (value) async {
                                            await DriveBackupService.setAutoBackup(value);
                                            setState(() => _autoBackupEnabled = value);
                                          },
                                        ),
                                      ),
                                      CustomCupertinoListTile(icon: Icons.cloud_download, title: 'Restore from Backup', subtitle: 'Download and restore your data',
                                        onTap: () => _showConfirmationDialog(title: 'Restore', message: 'This will replace all current data with the backup. This cannot be undone.',
                                          confirmText: 'Restore', confirmColor: Colors.orange, onConfirm: _restoreFromDrive),
                                        iconColor: const Color(0xFF2196F3), isLoading: _loadingAction == 'restore'),
                                      CustomCupertinoListTile(icon: Icons.link_off, title: 'Disconnect', subtitle: 'Sign out from Google backup',
                                        onTap: () => _showConfirmationDialog(title: 'Disconnect', message: 'Existing backups will remain. No new backups will be made.',
                                          confirmText: 'Disconnect', confirmColor: Colors.red, onConfirm: _googleSignOut),
                                        iconColor: Colors.red, isLast: true, isLoading: _loadingAction == 'googleSignOut'),
                                    ],
                                  ],
                                ),

                                // Data Management Section
                                CupertinoSection(
                                  title: 'Data Management',
                                  children: [
                                    CustomCupertinoListTile(icon: Icons.delete_sweep, title: 'Clear Fuel Entries', subtitle: 'Remove all fuel entries',
                                      onTap: () => _showConfirmationDialog(title: 'Clear Fuel Entries', message: 'This will permanently delete all your fuel entries.',
                                        confirmText: 'Clear Entries', confirmColor: Colors.orange, onConfirm: _clearFuelEntries),
                                      iconColor: Colors.orange, isFirst: true, isLoading: _loadingAction == 'clearEntries'),
                                    CustomCupertinoListTile(icon: Icons.speed, title: 'Clear Odometer Data', subtitle: 'Reset current odometer reading',
                                      onTap: () => _showConfirmationDialog(title: 'Clear Odometer', message: 'This will reset your odometer reading.',
                                        confirmText: 'Clear Odometer', confirmColor: Colors.blue, onConfirm: _clearOdometerData),
                                      iconColor: Colors.blue, isLoading: _loadingAction == 'clearOdometer'),
                                    CustomCupertinoListTile(icon: Icons.delete_forever, title: 'Clear All Fuel Data', subtitle: 'Remove all entries and odometer data',
                                      onTap: () => _showConfirmationDialog(title: 'Clear All', message: 'This will permanently delete ALL fuel data. Cannot be undone.',
                                        confirmText: 'Clear All Data', confirmColor: Colors.red, onConfirm: _clearAllData),
                                      iconColor: Colors.red, isLast: true, isLoading: _loadingAction == 'clearAllData'),
                                  ],
                                ),

                                // Advanced Section
                                CupertinoSection(
                                  title: 'Advanced',
                                  children: [
                                    CustomCupertinoListTile(icon: Icons.cleaning_services, title: 'Clear All Cache & Preferences', subtitle: 'Reset the entire app to factory settings',
                                      onTap: () => _showConfirmationDialog(title: 'Clear All Cache', message: 'This will completely reset the app. ALL data will be lost.',
                                        confirmText: 'Reset App', confirmColor: Colors.purple, onConfirm: _clearAllCache),
                                      iconColor: Colors.purple, isFirst: true, isLast: true, isLoading: _loadingAction == 'clearCache'),
                                  ],
                                ),

                                if (_loadingAction != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600))),
                                        const SizedBox(width: 16),
                                        Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      case ThemeMode.system: return Icons.brightness_auto;
    }
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System';
    }
  }

  void _showThemeDialog() {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentMode = ref.read(themeProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_getThemeLabel(mode)),
                secondary: Icon(_getThemeIcon(mode)),
                value: mode,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAccentColorDialog() {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentColor = ref.read(themeProvider).accentColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Accent Color'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ThemeService.accentColors.map((color) {
              // ignore: deprecated_member_use
              final isSelected = color.value == currentColor.value;
              return GestureDetector(
                onTap: () {
                  themeNotifier.setAccentColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                    boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
