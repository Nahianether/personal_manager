import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../models/user.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      print('🔍 Checking authentication status...');
      final isLoggedIn = await _authService.isLoggedIn();
      print('📊 Is logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        print('🔐 User appears to be logged in, validating token...');
        final isValid = await _authService.validateToken();
        print('✅ Token validation result: $isValid');
        
        if (isValid) {
          final userData = await _authService.getUserData();
          print('📱 Retrieved user data: $userData');
          
          if (userData['id'] != null && userData['name'] != null && userData['email'] != null) {
            final user = User(
              id: userData['id']!,
              name: userData['name']!,
              email: userData['email']!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              user: user,
            );
            print('✅ User authenticated successfully: ${user.name}');
            
            // Download user data from server in background
            _downloadUserDataFromServer().catchError((error) {
              print('❌ Background data download failed: $error');
            });
          } else {
            print('❌ Incomplete user data, signing out');
            await _authService.signout();
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: false,
              user: null,
            );
          }
        } else {
          print('❌ Token validation failed, signing out');
          await _authService.signout();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
          );
        }
      } else {
        print('📤 User not logged in, showing signin screen');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
        );
      }
    } catch (e) {
      print('❌ Error during auth check: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _authService.signup(
        name: name,
        email: email,
        password: password,
      );
      
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _authService.signin(
        email: email,
        password: password,
      );
      
      if (success) {
        final userData = await _authService.getUserData();
        print('📊 Retrieved user data: $userData');
        
        if (userData['id'] != null && userData['name'] != null && userData['email'] != null) {
          final user = User(
            id: userData['id']!,
            name: userData['name']!,
            email: userData['email']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: user,
          );
          
          print('✅ Authentication state updated: isAuthenticated = ${state.isAuthenticated}');
          
          // Download user data from server in background (don't block navigation)
          _downloadUserDataFromServer().catchError((error) {
            print('❌ Background data download failed: $error');
            // Don't change auth state on download failure - user can still use app
          });
        } else {
          print('❌ User data is incomplete: $userData');
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
            error: 'User data is incomplete',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> signout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      print('🔄 Starting signout process...');
      
      // Clear authentication data
      await _authService.signout();
      
      // Clear ALL local data (server-sync approach)
      await _clearAllLocalData();
      
      // Update auth state
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: null,
      );
      
      print('✅ Signout completed successfully');
    } catch (e) {
      print('❌ Error during signout: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> _clearAllLocalData() async {
    try {
      print('🗑️ Clearing all local data (server-sync approach)...');
      
      // Dispose sync service to prevent stream errors
      SyncService().dispose();
      
      // Clear ALL local data - will be re-downloaded on next login
      final DatabaseService databaseService = DatabaseService();
      await databaseService.deleteAllData();
      
      print('✅ All local data cleared');
    } catch (e) {
      print('❌ Error clearing local data: $e');
      // Don't throw here, just log the error
    }
  }
  
  Future<void> _downloadUserDataFromServer() async {
    try {
      print('📥 Downloading user data from server...');

      final syncService = SyncService();
      await syncService.downloadAllServerData();

      print('✅ User data download completed');
    } catch (e) {
      print('❌ Error downloading user data: $e');
      // Don't throw here, just log the error
      // User can still use app, data will sync when server is available
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});