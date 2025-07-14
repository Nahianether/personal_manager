import 'package:dio/dio.dart';
import '../config/api_config.dart';

class BackendTestService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.defaultHeaders,
  ));

  static Future<Map<String, dynamic>> testAllEndpoints() async {
    final results = <String, dynamic>{};
    
    // Test different base URLs first
    final baseUrls = [
      'http://103.51.129.29:3000', // Primary VPS endpoint
      'http://127.0.0.1:3000',
      'http://localhost:3000',
      'http://0.0.0.0:3000',
    ];
    
    print('Testing base URL connectivity...');
    for (final baseUrl in baseUrls) {
      try {
        final testDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        final response = await testDio.get('/');
        results['BASE_URL_$baseUrl'] = {
          'status': 'success',
          'statusCode': response.statusCode,
          'data': 'Connected successfully',
        };
        print('✓ $baseUrl - Connected successfully');
        break; // If we found a working URL, use it
      } catch (e) {
        results['BASE_URL_$baseUrl'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('✗ $baseUrl - Failed: $e');
      }
    }
    
    // List of endpoints to test (matching your backend)
    final endpoints = [
      '/',
      '/health',
      '/accounts',
      '/transactions',
      '/loans',
      '/liabilities',
      '/categories',
    ];
    
    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(endpoint);
        results[endpoint] = {
          'status': 'success',
          'statusCode': response.statusCode,
          'data': response.data.toString().length > 100 
              ? '${response.data.toString().substring(0, 100)}...' 
              : response.data.toString(),
        };
      } catch (e) {
        if (e is DioException) {
          results[endpoint] = {
            'status': 'error',
            'statusCode': e.response?.statusCode,
            'error': e.message,
          };
        } else {
          results[endpoint] = {
            'status': 'error',
            'error': e.toString(),
          };
        }
      }
    }
    
    return results;
  }
  
  static Future<void> printEndpointResults() async {
    print('=== Testing Backend Endpoints ===');
    final results = await testAllEndpoints();
    
    for (final entry in results.entries) {
      print('\n${entry.key}:');
      final result = entry.value;
      print('  Status: ${result['status']}');
      if (result['statusCode'] != null) {
        print('  Status Code: ${result['statusCode']}');
      }
      if (result['data'] != null) {
        print('  Response: ${result['data']}');
      }
      if (result['error'] != null) {
        print('  Error: ${result['error']}');
      }
    }
    print('\n=== End Test Results ===');
  }
}