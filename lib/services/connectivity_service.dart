import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static final Connectivity _connectivity = Connectivity();
  
  static StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  static bool _isConnected = false;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  static Stream<bool> get connectivityStream => _connectivityController.stream;
  static bool get isConnected => _isConnected;

  static Future<void> initialize() async {
    _isConnected = await _checkInitialConnectivity();
    _connectivityController.add(_isConnected);
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final bool newConnectivity = await _checkConnectivity(results);
        if (newConnectivity != _isConnected) {
          _isConnected = newConnectivity;
          _connectivityController.add(_isConnected);
        }
      },
    );
  }

  static Future<bool> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _checkConnectivity(result);
    } catch (e) {
      print('Error checking initial connectivity: $e');
      return false;
    }
  }

  static Future<bool> _checkConnectivity(List<ConnectivityResult> results) async {
    if (results.isEmpty) return false;
    
    for (final result in results) {
      if (result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.ethernet) {
        return true;
      }
    }
    return false;
  }

  static Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = await _checkConnectivity(result);
      if (isConnected != _isConnected) {
        _isConnected = isConnected;
        _connectivityController.add(_isConnected);
      }
      return isConnected;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _connectivityController = StreamController<bool>.broadcast();
  }
}