import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fast async non-blocking init
  await ApiService.init();
  runApp(const ParkEazyApp());
}

class ParkEazyApp extends StatelessWidget {
  const ParkEazyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.token != null;

    return MaterialApp(
      title: 'ParkEazy - AI Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
    );
  }
}
