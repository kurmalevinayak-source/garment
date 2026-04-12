import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

/// Splash screen shown on app launch.
///
/// Displays the app logo and name, then auto-redirects:
/// - If user is logged in → Dashboard
/// - If not logged in → Login screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate after animation + short delay
    Future.delayed(const Duration(milliseconds: 2200), _navigateNext);
  }

  /// Check auth state and navigate accordingly
  void _navigateNext() {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final nextScreen =
        authService.isLoggedIn ? const DashboardScreen() : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.loginGradient,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(153),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withAlpha(128),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
