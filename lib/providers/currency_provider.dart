import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/exchange_rate_service.dart';
import '../services/api_service.dart';
import '../utils/currency_utils.dart';

class CurrencyState {
  final String displayCurrency;
  final Map<String, double> exchangeRates;
  final bool isLoading;
  final String? error;
  final DateTime? ratesLastUpdated;

  CurrencyState({
    required this.displayCurrency,
    required this.exchangeRates,
    required this.isLoading,
    this.error,
    this.ratesLastUpdated,
  });

  CurrencyState copyWith({
    String? displayCurrency,
    Map<String, double>? exchangeRates,
    bool? isLoading,
    String? error,
    DateTime? ratesLastUpdated,
  }) {
    return CurrencyState(
      displayCurrency: displayCurrency ?? this.displayCurrency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ratesLastUpdated: ratesLastUpdated ?? this.ratesLastUpdated,
    );
  }

  double convertToDisplay(double amount, String sourceCurrency) {
    if (sourceCurrency == displayCurrency) return amount;
    if (exchangeRates.isEmpty) return amount;
    final fromRate = exchangeRates[sourceCurrency] ?? 1.0;
    final toRate = exchangeRates[displayCurrency] ?? 1.0;
    return amount * (toRate / fromRate);
  }

  String formatInDisplayCurrency(double amount, String sourceCurrency) {
    final converted = convertToDisplay(amount, sourceCurrency);
    return CurrencyUtils.formatCurrency(converted, displayCurrency);
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  final ApiService _apiService = ApiService();

  CurrencyNotifier()
      : super(CurrencyState(
          displayCurrency: 'BDT',
          exchangeRates: {},
          isLoading: false,
        )) {
    _loadPreferences();
  }

  static const String _displayCurrencyKey = 'display_currency';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_displayCurrencyKey) ?? 'BDT';
    state = state.copyWith(displayCurrency: savedCurrency);
    await loadExchangeRates();
  }

  Future<void> setDisplayCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayCurrencyKey, code);
    state = state.copyWith(displayCurrency: code);
    // Sync to backend (fire-and-forget)
    _apiService.updatePreference(code);
  }

  Future<void> syncFromBackend() async {
    try {
      final backendCurrency = await _apiService.getPreference();
      if (backendCurrency != null && backendCurrency != state.displayCurrency) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_displayCurrencyKey, backendCurrency);
        state = state.copyWith(displayCurrency: backendCurrency);
      }
    } catch (e) {
      // Silently fail - local preference takes priority
    }
  }

  Future<void> loadExchangeRates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rates = await _exchangeRateService.getRates();
      state = state.copyWith(
        exchangeRates: rates,
        isLoading: false,
        ratesLastUpdated: _exchangeRateService.lastUpdated,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshRates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _exchangeRateService.refreshRates();
      final rates = await _exchangeRateService.getRates();
      state = state.copyWith(
        exchangeRates: rates,
        isLoading: false,
        ratesLastUpdated: _exchangeRateService.lastUpdated,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  return CurrencyNotifier();
});
