import 'package:flutter/material.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/currency_service.dart';
import '../widgets/widgets.dart';

class FuelHistoryScreen extends StatefulWidget {
  const FuelHistoryScreen({super.key});

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> with TickerProviderStateMixin {
  List<FuelEntry> _entries = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  double _totalCost = 0.0;
  double _totalLiters = 0.0;
  double _averagePrice = 0.0;
  String _currency = '\$';

  late AnimationController _syncAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _syncRotation;
  late Animation<double> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _cardAnimationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _syncRotation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _syncAnimationController, curve: Curves.linear));
    _cardSlideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutCubic));
    _loadData();
    _loadCurrency();
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getSelectedCurrency();
    if (mounted) {
      setState(() {
        _currency = currency;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await FuelStorageService.getFuelEntries();
      final totalCost = await FuelStorageService.getTotalFuelCost();
      final totalLiters = await FuelStorageService.getTotalLiters();
      final averagePrice = await FuelStorageService.getAveragePricePerLiter();

      setState(() {
        _entries = entries..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _totalCost = totalCost;
        _totalLiters = totalLiters;
        _averagePrice = averagePrice;
      });

      _cardAnimationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await FuelStorageService.deleteFuelEntry(id);

      // Try to delete from server if user is authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      if (isAuthenticated) {
        try {
          await SyncService.deleteEntryFromServer(id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entry deleted locally and from server!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Entry deleted locally. Server delete failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted locally! Sign in to sync deletion with server.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Fuel History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SyncFAB(
        isSyncing: _isSyncing,
        onPressed: _syncData,
        syncRotation: _syncRotation,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: const Color(0xFF667eea),
                            strokeWidth: 4,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading fuel data...',
                          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we fetch your data',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _cardSlideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _cardSlideAnimation.value)),
                          child: Opacity(
                            opacity: _cardSlideAnimation.value,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width < 400 ? 12 : 16,
                                vertical: MediaQuery.of(context).size.width < 400 ? 12 : 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    offset: const Offset(0, 15),
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 20 : 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                                            ),
                                            child: Icon(
                                              Icons.analytics_rounded,
                                              color: Colors.white,
                                              size: MediaQuery.of(context).size.width < 400 ? 24 : 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Summary',
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width < 400 ? 22 : 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              Text(
                                                'Your fuel statistics',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FuelSummaryStats(
                                      totalCost: _totalCost,
                                      totalLiters: _totalLiters,
                                      averagePrice: _averagePrice,
                                      currency: _currency,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 12 : 16),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Entries',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (_entries.isNotEmpty)
                            Text(
                              '${_entries.length} entries',
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  _entries.isEmpty
                      ? SliverFillRemaining(
                          child: EmptyStateWidget(
                            icon: Icons.local_gas_station_rounded,
                            title: 'No fuel entries yet',
                            subtitle: 'Add your first fuel entry to start\ntracking your fuel costs!',
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final entry = _entries[index];
                            return FuelEntryCard(
                              entry: entry,
                              currency: _currency,
                              onDelete: () => _showDeleteDialog(entry.id),
                              index: index,
                              animation: _cardSlideAnimation,
                            );
                          }, childCount: _entries.length),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
    );
  }







  void _showDeleteDialog(String entryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          onConfirm: () => _deleteEntry(entryId),
        );
      },
    );
  }


  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    _syncAnimationController.repeat();

    try {
      final isAuthenticated = await AuthService.isAuthenticated();
      if (isAuthenticated) {
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Successfully synced with server!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Please sign in to sync with server'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Sync failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      _syncAnimationController.stop();
      setState(() {
        _isSyncing = false;
      });
    }
  }
}
