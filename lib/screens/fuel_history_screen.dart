import 'package:flutter/material.dart';
import '../models/fuel_entry.dart';
import '../services/fuel_storage_service.dart';

class FuelHistoryScreen extends StatefulWidget {
  const FuelHistoryScreen({super.key});

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  List<FuelEntry> _entries = [];
  bool _isLoading = true;
  double _totalCost = 0.0;
  double _totalLiters = 0.0;
  double _averagePrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
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
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Cost Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('\$${_totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.red)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Total Liters', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('${_totalLiters.toStringAsFixed(2)}L', style: const TextStyle(fontSize: 18, color: Colors.blue)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Avg Price/L', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('\$${_averagePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text(
                            'No fuel entries yet.\nAdd your first entry!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.local_gas_station, color: Colors.blue),
                                title: Text('${entry.liters.toStringAsFixed(2)} Liters'),
                                subtitle: Text(
                                  '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year} '
                                  'at ${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}\n'
                                  '\$${entry.pricePerLiter.toStringAsFixed(2)} per liter',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '\$${entry.totalCost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteDialog(entry.id),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteDialog(String entryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this fuel entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntry(entryId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}