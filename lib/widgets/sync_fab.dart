import 'package:flutter/material.dart';

class SyncFAB extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback? onPressed;
  final Animation<double> syncRotation;

  const SyncFAB({
    super.key,
    required this.isSyncing,
    required this.onPressed,
    required this.syncRotation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: syncRotation,
      builder: (context, child) {
        return FloatingActionButton.extended(
          onPressed: isSyncing ? null : onPressed,
          backgroundColor: isSyncing ? colorScheme.surfaceContainerHighest : colorScheme.primary,
          foregroundColor: isSyncing ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
          elevation: 8,
          icon: Transform.rotate(
            angle: syncRotation.value * 2 * 3.14159,
            child: Icon(isSyncing ? Icons.sync : Icons.cloud_sync_rounded, size: 24),
          ),
          label: Text(
            isSyncing ? 'Syncing...' : 'Sync Now',
            style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        );
      },
    );
  }
}