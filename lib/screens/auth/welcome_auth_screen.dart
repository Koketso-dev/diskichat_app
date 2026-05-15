import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

import '../../providers/auth_provider.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../components/buttons/gradient_button.dart';
import '../../components/inputs/custom_text_field.dart';
import '../profile_setup/profile_wizard_screen.dart';
import '../home_screen.dart';

class WelcomeAuthScreen extends StatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  final TextEditingController _mobileController = TextEditingController();

  void _handleRegistration() async {
    final mobile = _mobileController.text.trim();
    debugPrint('DEBUG: _handleRegistration called with mobile: $mobile');

    if (mobile.length < 10) {
      _showToast("Please enter a valid mobile number", icon: Icons.error);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('DEBUG: Calling signInWithMobile...');
    final success = await authProvider.signInWithMobile(mobile);
    debugPrint('DEBUG: signInWithMobile returned: $success');

    if (success) {
      if (!mounted) {
        debugPrint('DEBUG: Widget not mounted after login!');
        return;
      }
      
      final profile = authProvider.userProfile;
      debugPrint('DEBUG: User Profile: $profile');
      debugPrint('DEBUG: Favorite Team: ${profile?.favoriteTeam}');

      // Check if profile is incomplete (e.g. no favorite team)
      if (profile?.favoriteTeam == null) {
        debugPrint('DEBUG: Navigating to ProfileWizardScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileWizardScreen()),
        );
      } else {
        debugPrint('DEBUG: Navigating to HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      debugPrint('DEBUG: showing error toast: ${authProvider.errorMessage}');
      if (!mounted) return;
      _showToast(authProvider.errorMessage ?? "Login failed", icon: Icons.error);
    }
  }

  void _showToast(String message, {IconData icon = Icons.info}) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: Icon(icon, size: 28, color: AppColors.textWhite),
        title: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textWhite),
        ),
        color: AppColors.cardSurface,
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo
               Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'lib/assets/images/diskichat_icon.png',
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                'Get Started',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your mobile number to start',
                style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              CustomTextField(
                controller: _mobileController,
                hintText: 'Mobile Number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_android,
              ),

              const SizedBox(height: 24),

              if (isLoading)
                const SpinKitThreeBounce(
                  color: AppColors.accentBlue,
                  size: 30.0,
                )
              else
                GradientButton(
                  text: 'Continue',
                  onPressed: _handleRegistration,
                ),
                
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
