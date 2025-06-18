import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const String _defaultCurrency = '\$';

  // Comprehensive currency symbols from around the world
  static const Map<String, String> supportedCurrencies = {
    // Major currencies
    '\$': 'US Dollar',
    '€': 'Euro',
    '£': 'British Pound',
    '¥': 'Japanese Yen',
    'C\$': 'Canadian Dollar',
    'A\$': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'kr': 'Swedish Krona',
    'NZ\$': 'New Zealand Dollar',
    'S\$': 'Singapore Dollar',
    'HK\$': 'Hong Kong Dollar',

    // Asian currencies
    '₹': 'Indian Rupee',
    '₨': 'Pakistani Rupee',
    '৳': 'Bangladeshi Taka',
    '₦': 'Nigerian Naira',
    '₩': 'South Korean Won',
    '₱': 'Philippine Peso',
    '₫': 'Vietnamese Dong',
    'RS': 'Sri Lankan / Nepalese Rupee',
    'Rp': 'Indonesian Rupiah',
    'RM': 'Malaysian Ringgit',
    '฿': 'Thai Baht',
    '₭': 'Lao Kip',
    '៛': 'Cambodian Riel',
    'MMK': 'Myanmar Kyat',
    '₮': 'Mongolian Tugrik',
    '₾': 'Georgian Lari',
    '₼': 'Azerbaijani Manat',
    '₸': 'Kazakhstani Tenge',
    'сом': 'Kyrgyzstani Som',
    'ТЖС': 'Tajikistani Somoni',
    'TMT': 'Turkmenistani Manat',
    '؋': 'Afghan Afghani',
    '﷼': 'Saudi Riyal',
    'د.إ': 'UAE Dirham',
    'د.ك': 'Kuwaiti Dinar',
    'ر.ق': 'Qatari Riyal',
    'ر.ع': 'Omani Rial',
    'ر.س': 'Saudi Riyal',
    'ل.ل': 'Lebanese Pound',
    'ل.د': 'Libyan Dinar',
    'ج.م': 'Egyptian Pound',
    'د.ج': 'Algerian Dinar',
    'د.م': 'Moroccan Dirham',
    'د.ت': 'Tunisian Dinar',
    '₪': 'Israeli Shekel',
    'ر.ي': 'Yemeni Rial',
    'ر.أ': 'Jordanian Dinar',
    'ل.س': 'Syrian Pound',
    'د.ع': 'Iraqi Dinar',

    // European currencies
    '₽': 'Russian Ruble',
    '₴': 'Ukrainian Hryvnia',
    'zł': 'Polish Zloty',
    'Kč': 'Czech Koruna',
    'Ft': 'Hungarian Forint',
    'lei': 'Romanian Leu',
    'лв': 'Bulgarian Lev',
    'kn': 'Croatian Kuna',
    'RSD': 'Serbian Dinar',
    'MKD': 'North Macedonian Denar',
    'ALL': 'Albanian Lek',
    'BAM': 'Bosnia and Herzegovina Convertible Mark',
    'MDL': 'Moldovan Leu',
    'RON': 'Romanian Leu',
    'TRY': 'Turkish Lira',

    // African currencies
    'R': 'South African Rand',
    '₵': 'Ghanaian Cedi',
    'E': 'Swazi Lilangeni',
    'L': 'Lesotho Loti',
    'P': 'Botswana Pula',
    'N\$': 'Namibian Dollar',
    'USh': 'Ugandan Shilling',
    'KSh': 'Kenyan Shilling',
    'TSh': 'Tanzanian Shilling',
    'Br': 'Ethiopian Birr',
    'LE': 'Egyptian Pound',
    'DA': 'Algerian Dinar',
    'MAD': 'Moroccan Dirham',
    'CFA': 'West African CFA Franc',
    'XAF': 'Central African CFA Franc',
    'Ar': 'Malagasy Ariary',
    'MRU': 'Mauritanian Ouguiya',
    'CV\$': 'Cape Verdean Escudo',
    'Db': 'São Tomé and Príncipe Dobra',
    'FG': 'Guinean Franc',
    'GHS': 'Ghanaian Cedi',
    'SLL': 'Sierra Leonean Leone',
    'LRD': 'Liberian Dollar',
    'CDF': 'Congolese Franc',
    'RWF': 'Rwandan Franc',
    'BIF': 'Burundian Franc',
    'DJF': 'Djiboutian Franc',
    'ERN': 'Eritrean Nakfa',
    'ETB': 'Ethiopian Birr',
    'SOS': 'Somali Shilling',
    'SSP': 'South Sudanese Pound',
    'SDG': 'Sudanese Pound',
    'CLP': 'Chilean Peso',
    'ARS': 'Argentine Peso',
    'UYU': 'Uruguayan Peso',
    'PYG': 'Paraguayan Guarani',
    'BOB': 'Bolivian Boliviano',
    'PEN': 'Peruvian Sol',
    'COP': 'Colombian Peso',
    'VED': 'Venezuelan Bolívar',
    'GYD': 'Guyanese Dollar',
    'SRD': 'Surinamese Dollar',
    'BRL': 'Brazilian Real',
    'R\$': 'Brazilian Real',

    // North American currencies
    'MX\$': 'Mexican Peso',
    'GT': 'Guatemalan Quetzal',
    'HNL': 'Honduran Lempira',
    'NIO': 'Nicaraguan Córdoba',
    '₡': 'Costa Rican Colón',
    'PAB': 'Panamanian Balboa',
    'DOP': 'Dominican Peso',
    'HTG': 'Haitian Gourde',
    'JMD': 'Jamaican Dollar',
    'KYD': 'Cayman Islands Dollar',
    'BSD': 'Bahamian Dollar',
    'BBD': 'Barbadian Dollar',
    'XCD': 'East Caribbean Dollar',
    'TTD': 'Trinidad and Tobago Dollar',
    'BZD': 'Belize Dollar',

    // Oceania currencies
    'FJD': 'Fijian Dollar',
    'TOP': 'Tongan Paʻanga',
    'WST': 'Samoan Tala',
    'VUV': 'Vanuatu Vatu',
    'SBD': 'Solomon Islands Dollar',
    'PGK': 'Papua New Guinean Kina',
    'TVD': 'Tuvaluan Dollar',
    'KID': 'Kiribati Dollar',
    'MOP': 'Macanese Pataca',
    'BND': 'Brunei Dollar',
    'XPF': 'CFP Franc',

    // Others
    'XDR': 'Special Drawing Rights',
    'XAU': 'Gold Ounce',
    'XAG': 'Silver Ounce',
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
  };

  /// Get the currently selected currency symbol
  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? _defaultCurrency;
  }

  /// Set the selected currency symbol
  static Future<void> setSelectedCurrency(String currencySymbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencySymbol);
  }

  /// Get currency display name
  static String getCurrencyName(String symbol) {
    return supportedCurrencies[symbol] ?? 'Unknown Currency';
  }

  /// Format a number with the selected currency
  static Future<String> formatCurrency(double amount, {int decimalPlaces = 2}) async {
    final currency = await getSelectedCurrency();
    return '$currency${amount.toStringAsFixed(decimalPlaces)}';
  }

  /// Format a number with a specific currency
  static String formatCurrencyWith(String currencySymbol, double amount, {int decimalPlaces = 2}) {
    return '$currencySymbol${amount.toStringAsFixed(decimalPlaces)}';
  }

  /// Check if a currency symbol is supported
  static bool isSupportedCurrency(String symbol) {
    return supportedCurrencies.containsKey(symbol);
  }

  /// Get all supported currency symbols as a list
  static List<String> getAllCurrencies() {
    return supportedCurrencies.keys.toList();
  }
}
