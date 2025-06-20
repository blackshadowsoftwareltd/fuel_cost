import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/sync_service.dart';

class SyncButton extends StatelessWidget {
  final bool isSyncing;
  final bool isAuthenticated;
  final VoidCallback? onPressed;
  final DateTime? lastSyncTime;

  const SyncButton({
    super.key, 
    required this.isSyncing, 
    required this.isAuthenticated, 
    required this.onPressed,
    this.lastSyncTime,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF9800);
    final buttonText = isSyncing
        ? 'Syncing...'
        : isAuthenticated
        ? 'Sync Now'
        : 'Sign In for Sync';
    final subtitle = isSyncing
        ? 'Please wait while syncing'
        : isAuthenticated
        ? 'Last sync: ${SyncService.formatLastSyncTime(lastSyncTime)}'
        : 'Authenticate to sync data';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSyncing ? null : onPressed,
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container with Cupertino style
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: isSyncing
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Icon(
                          isAuthenticated ? Icons.cloud_sync_rounded : Icons.login_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cupertino-style chevron or sync icon
                if (!isSyncing)
                  Icon(
                    isAuthenticated ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
