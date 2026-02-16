import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalDigits = 2,
  });
}

class CurrencyUtils {
  static const Map<String, CurrencyInfo> supportedCurrencies = {
    'BDT': CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    'USD': CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
    'EUR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    'GBP': CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    'INR': CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    'JPY': CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', decimalDigits: 0),
    'CAD': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    'AUD': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    'SAR': CurrencyInfo(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    'AED': CurrencyInfo(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    'MYR': CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    'SGD': CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    'CNY': CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    'KRW': CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean Won', decimalDigits: 0),
    'CHF': CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    'THB': CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    'PKR': CurrencyInfo(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    'TRY': CurrencyInfo(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    'QAR': CurrencyInfo(code: 'QAR', symbol: 'QR', name: 'Qatari Riyal'),
    'KWD': CurrencyInfo(code: 'KWD', symbol: 'KD', name: 'Kuwaiti Dinar', decimalDigits: 3),
  };

  static String getSymbol(String code) {
    return supportedCurrencies[code]?.symbol ?? code;
  }

  static String getName(String code) {
    return supportedCurrencies[code]?.name ?? code;
  }

  static int getDecimalDigits(String code) {
    return supportedCurrencies[code]?.decimalDigits ?? 2;
  }

  static List<String> get codes => supportedCurrencies.keys.toList();

  static String formatCurrency(double amount, String currencyCode) {
    final info = supportedCurrencies[currencyCode];
    return NumberFormat.currency(
      symbol: info?.symbol ?? '$currencyCode ',
      decimalDigits: info?.decimalDigits ?? 2,
    ).format(amount);
  }

  static NumberFormat getFormatter(String currencyCode) {
    final info = supportedCurrencies[currencyCode];
    return NumberFormat.currency(
      symbol: info?.symbol ?? '$currencyCode ',
      decimalDigits: info?.decimalDigits ?? 2,
    );
  }
}
