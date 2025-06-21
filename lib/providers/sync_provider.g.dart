// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isSyncNeededHash() => r'81f8c1d497f0ac610eb982aef2c9bdcfb1b034ab';

/// See also [isSyncNeeded].
@ProviderFor(isSyncNeeded)
final isSyncNeededProvider = AutoDisposeFutureProvider<bool>.internal(
  isSyncNeeded,
  name: r'isSyncNeededProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isSyncNeededHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSyncNeededRef = AutoDisposeFutureProviderRef<bool>;
String _$lastSyncFormattedHash() => r'd25e0de79a161d1b1f599d3ce46733dfcfb6b4b0';

/// See also [lastSyncFormatted].
@ProviderFor(lastSyncFormatted)
final lastSyncFormattedProvider = AutoDisposeFutureProvider<String>.internal(
  lastSyncFormatted,
  name: r'lastSyncFormattedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastSyncFormattedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LastSyncFormattedRef = AutoDisposeFutureProviderRef<String>;
String _$syncStatusHash() => r'ff2338198c674175c93144c86f37112766741be6';

/// See also [SyncStatus].
@ProviderFor(SyncStatus)
final syncStatusProvider =
    AutoDisposeAsyncNotifierProvider<SyncStatus, DateTime?>.internal(
  SyncStatus.new,
  name: r'syncStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncStatus = AutoDisposeAsyncNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
