import 'package:dio/dio.dart';

class SimpleConnectivityTest {
  static Future<void> testConnection() async {
    final urls = [
      'http://103.51.129.29:3000', // Primary VPS endpoint
      'http://127.0.0.1:3000',
      'http://localhost:3000', 
      'http://0.0.0.0:3000',
    ];
    
    print('\n=== Simple Connectivity Test ===');
    
    for (final url in urls) {
      print('\nTesting: $url');
      
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        
        // Test root endpoint
        final response = await dio.get('$url/');
        print('✓ SUCCESS - Status: ${response.statusCode}');
        print('  Response length: ${response.data.toString().length} chars');
        
        // Test if it's actually your Rust server
        if (response.data.toString().contains('rust') || 
            response.data.toString().contains('personal') ||
            response.statusCode == 200) {
          print('  🎯 This looks like your Rust backend!');
        }
        
      } catch (e) {
        print('✗ FAILED - Error: $e');
        
        if (e is DioException) {
          print('  Status Code: ${e.response?.statusCode}');
          print('  Message: ${e.message}');
          
          if (e.response?.statusCode == 404) {
            print('  💡 Server is running but no route handler for "/"');
          }
        }
      }
    }
    
    print('\n=== Test Complete ===\n');
  }
}