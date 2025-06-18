import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final String selectedCurrency;
  final Function(String) onCurrencySelected;

  const CurrencySelectionDialog({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyService.getAllCurrencies();
    final filteredCurrencies = currencies.where((currency) {
      final currencyName = CurrencyService.getCurrencyName(currency).toLowerCase();
      final currencySymbol = currency.toLowerCase();
      final query = searchQuery.toLowerCase();
      return currencyName.contains(query) || currencySymbol.contains(query);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attach_money, color: Color(0xFF2196F3), size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            // Search field
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                  filled: true,
                  fillColor: const Color(0xFF2196F3).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            // Currency list
            Expanded(
              child: filteredCurrencies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No currencies found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = filteredCurrencies[index];
                        final currencyName = CurrencyService.getCurrencyName(currency);
                        final isSelected = currency == widget.selectedCurrency;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  currency,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              currencyName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                              ),
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2196F3)) : null,
                            onTap: () {
                              widget.onCurrencySelected(currency);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}