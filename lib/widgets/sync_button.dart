import 'package:flutter/material.dart';

class SyncButton extends StatelessWidget {
  final bool isSyncing;
  final bool isAuthenticated;
  final VoidCallback? onPressed;

  const SyncButton({
    super.key,
    required this.isSyncing,
    required this.isAuthenticated,
    required this.onPressed,
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
            ? 'Sync with cloud storage'
            : 'Authenticate to sync data';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isSyncing ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSyncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          isAuthenticated ? Icons.cloud_sync_rounded : Icons.login_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSyncing)
                  Icon(
                    isAuthenticated ? Icons.sync_rounded : Icons.arrow_forward_ios_rounded,
                    size: isAuthenticated ? 20 : 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}