import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  static const String _ratesKey = 'exchange_rates';
  static const String _ratesTimestampKey = 'exchange_rates_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Map<String, double>? _cachedRates;
  DateTime? _cachedTimestamp;

  bool get isCacheStale {
    if (_cachedTimestamp == null) return true;
    return DateTime.now().difference(_cachedTimestamp!) > _cacheExpiry;
  }

  DateTime? get lastUpdated => _cachedTimestamp;

  Future<Map<String, double>> getRates() async {
    // 1. Return in-memory cache if fresh
    if (_cachedRates != null && !isCacheStale) {
      return _cachedRates!;
    }

    // 2. Try SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_ratesTimestampKey);
    if (timestampStr != null) {
      final savedTimestamp = DateTime.tryParse(timestampStr);
      if (savedTimestamp != null && DateTime.now().difference(savedTimestamp) < _cacheExpiry) {
        final ratesJson = prefs.getString(_ratesKey);
        if (ratesJson != null) {
          _cachedRates = Map<String, double>.from(
            (jsonDecode(ratesJson) as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
          );
          _cachedTimestamp = savedTimestamp;
          return _cachedRates!;
        }
      }
    }

    // 3. Fetch from API
    try {
      final response = await _dio.get(_apiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final rates = <String, double>{};
        if (data is Map && data['rates'] is Map) {
          for (final entry in (data['rates'] as Map).entries) {
            rates[entry.key.toString()] = (entry.value as num).toDouble();
          }
        }
        // Save to caches
        _cachedRates = rates;
        _cachedTimestamp = DateTime.now();
        await prefs.setString(_ratesKey, jsonEncode(rates));
        await prefs.setString(_ratesTimestampKey, _cachedTimestamp!.toIso8601String());
        return rates;
      }
    } catch (e) {
      print('Exchange rate fetch failed: $e');
    }

    // 4. Fallback: return stale cache or empty
    if (_cachedRates != null) return _cachedRates!;

    // Try loading any stale cache from prefs
    final staleJson = prefs.getString(_ratesKey);
    if (staleJson != null) {
      _cachedRates = Map<String, double>.from(
        (jsonDecode(staleJson) as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
      final staleTs = prefs.getString(_ratesTimestampKey);
      if (staleTs != null) _cachedTimestamp = DateTime.tryParse(staleTs);
      return _cachedRates!;
    }

    return {};
  }

  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final rates = await getRates();
    if (rates.isEmpty) return amount;
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return amount * (toRate / fromRate);
  }

  Future<void> refreshRates() async {
    _cachedRates = null;
    _cachedTimestamp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratesKey);
    await prefs.remove(_ratesTimestampKey);
    await getRates();
  }
}
