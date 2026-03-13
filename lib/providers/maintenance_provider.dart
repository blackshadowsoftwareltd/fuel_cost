import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_entry.dart';
import '../services/maintenance_service.dart';

final maintenanceEntriesProvider =
    FutureProvider<List<MaintenanceEntry>>((ref) async {
  return await MaintenanceService.getMaintenanceEntries();
});
