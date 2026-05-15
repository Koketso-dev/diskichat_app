import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import '../services/storage_service.dart';
import 'auth/welcome_auth_screen.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: SplashScreen initState');
    
    // Rotation Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    debugPrint('DEBUG: Starting _navigateToNext');
    
    // Initialize Storage Service (if not already)
    await StorageService().init();
    
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('DEBUG: Timer completed');

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('DEBUG: Auth check - isAuthenticated: ${authProvider.isAuthenticated}');

    // Check persistence flag first
    final bool isLoggedIn = StorageService().isLoggedIn;
    debugPrint('DEBUG: Persistence check - isLoggedIn: $isLoggedIn');

    if (authProvider.isAuthenticated || isLoggedIn) {
      debugPrint('DEBUG: Navigating to HomeScreen');
      AppRoutes.navigateReplace(context, const HomeScreen());
    } else {
      // Check if onboarding is already done
      final bool onboardingDone = StorageService().isOnboardingDone;
      debugPrint('DEBUG: Onboarding done: $onboardingDone');

      if (onboardingDone) {
        debugPrint('DEBUG: Navigating to WelcomeAuthScreen');
        AppRoutes.navigateReplace(context, const WelcomeAuthScreen());
      } else {
        debugPrint('DEBUG: Navigating to OnboardingScreen');
        AppRoutes.navigateReplace(context, const OnboardingScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: Image.asset(
            'lib/assets/images/diskichat_icon.png',
            width: 150, // Bigger logo
            height: 150,
          ),
        ),
      ),
    );
  }
}