import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/auth_splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    
    ref.read(syncProvider);
    
    return MaterialApp(
      title: 'Personal Manager',
      theme: themeState.themeData,
      home: authState.isLoading 
          ? const AuthSplashScreen()
          : authState.isAuthenticated 
              ? const HomeScreen()
              : const SigninScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
