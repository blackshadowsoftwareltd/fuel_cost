import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../business_logic/sync_logic.dart';

part 'sync_provider.g.dart';

@riverpod
class SyncStatus extends _$SyncStatus {
  @override
  Future<DateTime?> build() async {
    return await SyncLogic.getLastSyncTime();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await SyncLogic.getLastSyncTime());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> performSync() async {
    state = const AsyncValue.loading();
    try {
      await SyncLogic.performFullSync();
      state = AsyncValue.data(await SyncLogic.getLastSyncTime());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

@riverpod
Future<bool> isSyncNeeded(Ref ref) async {
  // Watch sync status to recalculate when sync happens
  await ref.watch(syncStatusProvider.future);
  return await SyncLogic.isSyncNeeded();
}

@riverpod
Future<String> lastSyncFormatted(Ref ref) async {
  final lastSync = await ref.watch(syncStatusProvider.future);
  return SyncLogic.formatSyncTime(lastSync);
}