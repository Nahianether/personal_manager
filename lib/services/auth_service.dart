import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late final Dio _dio;
  
  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
    ));
    
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ User registered successfully');
        return true;
      } else {
        print('⚠️ Signup failed with status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        print('❌ User already exists');
        throw Exception('User with this email already exists');
      } else if (e.response?.statusCode == 400) {
        print('❌ Invalid signup data: ${e.response?.data}');
        throw Exception('Invalid signup data');
      } else {
        print('❌ Signup failed: ${e.response?.statusCode} - ${e.message}');
        throw Exception('Signup failed. Please try again.');
      }
    } catch (e) {
      print('❌ Unexpected error during signup: $e');
      throw Exception('Signup failed. Please try again.');
    }
  }

  Future<bool> signin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Save user data and token
        await _saveUserData(
          token: data['token'],
          userId: data['user']['id'],
          userName: data['user']['name'],
          userEmail: data['user']['email'],
        );
        
        print('✅ User signed in successfully');
        return true;
      } else {
        print('⚠️ Signin failed with status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print('❌ Invalid credentials');
        throw Exception('Invalid email or password');
      } else if (e.response?.statusCode == 400) {
        print('❌ Invalid signin data: ${e.response?.data}');
        throw Exception('Invalid signin data');
      } else {
        print('❌ Signin failed: ${e.response?.statusCode} - ${e.message}');
        throw Exception('Signin failed. Please try again.');
      }
    } catch (e) {
      print('❌ Unexpected error during signin: $e');
      throw Exception('Signin failed. Please try again.');
    }
  }

  Future<void> _saveUserData({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    await prefs.setString('user_email', userEmail);
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> signout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);
    print('✅ User signed out successfully');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    print('📊 SharedPreferences is_logged_in: $loggedIn');
    return loggedIn;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'token': prefs.getString('auth_token'),
    };
  }

  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No token found');
        return false;
      }

      print('🔍 Validating token...');
      
      // For now, just check if token exists and user data is available
      // In a production app, you'd want to validate against the server
      final userData = await getUserData();
      if (userData['id'] != null && userData['name'] != null && userData['email'] != null) {
        print('✅ Token validation successful (offline)');
        return true;
      } else {
        print('❌ Token validation failed - incomplete user data');
        return false;
      }
      
      // Optional: Try server validation if needed
      // final response = await _dio.get('/auth/validate', 
      //   options: Options(
      //     headers: {'Authorization': 'Bearer $token'},
      //   ),
      // );
      // return response.statusCode == 200;
    } catch (e) {
      print('❌ Token validation failed: $e');
      return false;
    }
  }

  void addAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await signout();
        }
        handler.next(error);
      },
    ));
  }
}