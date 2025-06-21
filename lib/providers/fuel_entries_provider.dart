import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';
import '../business_logic/sync_logic.dart';

part 'fuel_entries_provider.g.dart';

@riverpod
class FuelEntries extends _$FuelEntries {
  @override
  Future<List<FuelEntry>> build() async {
    return await FuelStorageService.getFuelEntries();
  }

  Future<void> addEntry(FuelEntry entry) async {
    state = const AsyncValue.loading();
    try {
      await FuelStorageService.saveFuelEntry(entry);
      
      // Try to upload to server
      await SyncLogic.uploadEntry(entry);
      
      state = AsyncValue.data(await FuelStorageService.getFuelEntries());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await FuelStorageService.deleteFuelEntry(id);
      
      // Try to delete from server
      await SyncLogic.deleteEntryFromServer(id);
      
      state = AsyncValue.data(await FuelStorageService.getFuelEntries());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await FuelStorageService.getFuelEntries());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> syncWithServer() async {
    state = const AsyncValue.loading();
    try {
      await SyncLogic.performFullSync();
      state = AsyncValue.data(await FuelStorageService.getFuelEntries());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}