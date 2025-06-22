import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/fuel_storage_service.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../widgets/widgets.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _selectedCurrency = '\$';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadCurrency();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await AuthService.isAuthenticated();
    String? email;
    if (isAuth) {
      email = await AuthService.getUserEmail();
      debugPrint('Debug: Auth status: $isAuth, Email: $email'); // Debug line
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _userEmail = email;
      });
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) {
      setState(() {
        _selectedCurrency = currency;
      });
    }
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
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Currency changed to $currency (${CurrencyService.getCurrencyName(currency)})'),
                    ],
                  ),
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
    setState(() => _isLoading = true);
    try {
      await FuelStorageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('All fuel data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearFuelEntries() async {
    setState(() => _isLoading = true);
    try {
      await FuelStorageService.clearFuelEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Fuel entries cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing fuel entries: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearOdometerData() async {
    setState(() => _isLoading = true);
    try {
      await FuelStorageService.clearCurrentOdometer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Odometer data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing odometer data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _isLoading = true);
    try {
      await FuelStorageService.clearAllSharedPreferences();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('All cache and preferences cleared'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _userEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Signed out successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with gradient background
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (_isAuthenticated)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => _showConfirmationDialog(
                            title: 'Sign Out',
                            message:
                                'Are you sure you want to sign out? You can sign in again later to sync your data.',
                            confirmText: 'Sign Out',
                            confirmColor: Colors.orange,
                            onConfirm: _signOut,
                          ),
                          tooltip: 'Sign Out',
                        ),
                      ),
                  ],
                ),
              ),

              // Content area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.98), Colors.white.withValues(alpha: 0.92)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 25),
                        spreadRadius: -15,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your account, preferences and data',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Account Section
                                CupertinoSection(
                                  title: 'Account',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: _isAuthenticated
                                          ? CupertinoIcons.checkmark_shield
                                          : CupertinoIcons.person_circle,
                                      title: _isAuthenticated ? 'Signed In' : 'Not Signed In',
                                      subtitle: _isAuthenticated
                                          ? (_userEmail != null && _userEmail!.isNotEmpty)
                                                ? '$_userEmail\nYour data is being synced to the cloud'
                                                : 'Your data is being synced to the cloud'
                                          : 'Sign in to sync your data across devices',
                                      onTap: !_isAuthenticated
                                          ? () async {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const AuthScreen()),
                                              ).then((_) {
                                                _checkAuthStatus();
                                                // Force rebuild after auth
                                                if (mounted) setState(() {});
                                              });
                                            }
                                          : () {},
                                      iconColor: _isAuthenticated ? Colors.green : Colors.orange,
                                      isFirst: true,
                                      isLast: true,
                                      isLoading: _isLoading,
                                      trailing: !_isAuthenticated
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2196F3),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 20),
                                    ),
                                  ],
                                ),
                                // Currency Selection Section
                                CupertinoSection(
                                  title: 'Preferences',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: Icons.currency_exchange,
                                      title: 'Currency',
                                      subtitle:
                                          'Current: $_selectedCurrency (${CurrencyService.getCurrencyName(_selectedCurrency)})',
                                      onTap: _showCurrencyDialog,
                                      iconColor: const Color(0xFF2196F3),
                                      isFirst: true,
                                      isLast: true,
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),

                                // Data Management Section
                                CupertinoSection(
                                  title: 'Data Management',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: Icons.delete_sweep,
                                      title: 'Clear Fuel Entries',
                                      subtitle: 'Remove all fuel entries while keeping odometer data',
                                      onTap: () => _showConfirmationDialog(
                                        title: 'Clear Fuel Entries',
                                        message:
                                            'This will permanently delete all your fuel entries. Your current odometer reading will be preserved.',
                                        confirmText: 'Clear Entries',
                                        confirmColor: Colors.orange,
                                        onConfirm: _clearFuelEntries,
                                      ),
                                      iconColor: Colors.orange,
                                      isFirst: true,
                                      isLoading: _isLoading,
                                    ),
                                    CustomCupertinoListTile(
                                      icon: Icons.speed,
                                      title: 'Clear Odometer Data',
                                      subtitle: 'Reset current odometer reading while keeping fuel entries',
                                      onTap: () => _showConfirmationDialog(
                                        title: 'Clear Odometer Data',
                                        message:
                                            'This will reset your current odometer reading. Your fuel entries will be preserved.',
                                        confirmText: 'Clear Odometer',
                                        confirmColor: Colors.blue,
                                        onConfirm: _clearOdometerData,
                                      ),
                                      iconColor: Colors.blue,
                                      isLoading: _isLoading,
                                    ),
                                    CustomCupertinoListTile(
                                      icon: Icons.delete_forever,
                                      title: 'Clear All Fuel Data',
                                      subtitle: 'Remove all fuel entries and odometer data',
                                      onTap: () => _showConfirmationDialog(
                                        title: 'Clear All Fuel Data',
                                        message:
                                            'This will permanently delete ALL your fuel data including entries and odometer readings. This action cannot be undone.',
                                        confirmText: 'Clear All Data',
                                        confirmColor: Colors.red,
                                        onConfirm: _clearAllData,
                                      ),
                                      iconColor: Colors.red,
                                      isLast: true,
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),

                                // Advanced Section
                                CupertinoSection(
                                  title: 'Advanced',
                                  children: [
                                    CustomCupertinoListTile(
                                      icon: Icons.cleaning_services,
                                      title: 'Clear All Cache & Preferences',
                                      subtitle: 'Reset the entire app to factory settings',
                                      onTap: () => _showConfirmationDialog(
                                        title: 'Clear All Cache',
                                        message:
                                            'This will completely reset the app to its initial state. ALL data and preferences will be lost permanently.',
                                        confirmText: 'Reset App',
                                        confirmColor: Colors.purple,
                                        onConfirm: _clearAllCache,
                                      ),
                                      iconColor: Colors.purple,
                                      isFirst: true,
                                      isLast: true,
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),

                                if (_isLoading)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                          spreadRadius: -2,
                                        ),
                                      ],
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
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
}
