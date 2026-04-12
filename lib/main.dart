import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (connect to production Firebase)
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }

  // 3. Run the app
  runApp(const SiddhivinayakGarmentsApp());
}

/// Root widget of the application.
class SiddhivinayakGarmentsApp extends StatelessWidget {
  const SiddhivinayakGarmentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provide AuthService to the entire widget tree
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Siddhivinayak Garments',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Follow system theme
        home: const SplashScreen(),
      ),
    );
  }
}
