import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class ProfileWizardScreen extends StatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nicknameController = TextEditingController();
  int _currentStep = 0;
  bool _isTeamSelected = false;

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_nicknameController.text.trim().isEmpty) {
        _showToast("Please enter a nickname", icon: Icons.badge);
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        username: _nicknameController.text.trim(),
      );
      if (!success) {
        _showToast("Failed to update nickname", icon: Icons.error);
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_isTeamSelected) {
        _showToast("Please select a team to follow", icon: Icons.sports_soccer);
        return;
      }
      context.go('/home');
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
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              backgroundColor: AppColors.cardSurface,
              color: AppColors.accentBlue,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNicknameStep(),
                  _buildTeamSelectionStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: isLoading
                  ? const SpinKitThreeBounce(color: AppColors.accentBlue, size: 30)
                  : GradientButton(
                      text: _currentStep == 1 ? 'Finish' : 'Next',
                      onPressed: _nextStep,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNicknameStep() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: AppColors.accentBlue),
              const SizedBox(height: 24),
              const Text('What should we call you?', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Choose a unique nickname for the community.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              CustomTextField(
                controller: _nicknameController,
                hintText: 'Nickname',
                prefixIcon: Icons.badge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSelectionStep() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTeamSelected ? Icons.check_circle : Icons.shield,
                size: 80,
                color: _isTeamSelected ? AppColors.successGreen : AppColors.accentBlue,
              ),
              const SizedBox(height: 24),
              const Text('Pick your Team', style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Follow your favorite team to get news and match updates.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: () async {
                  if (user == null) return;
                  final result = await context.push<dynamic>('/team-selection', extra: {
                    'userId': user.uid,
                    'subscriptionType': 'FREE',
                    'currentFollowCount': 0,
                    'countryName': null,
                  });
                  if (result != null) {
                    if (!mounted) return;
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.updateProfile(
                      favoriteTeam: (result as dynamic).name as String,
                      favoriteTeamLogo: (result as dynamic).logo as String?,
                    );
                    setState(() => _isTeamSelected = true);
                  }
                },
                icon: const Icon(Icons.search),
                label: Text(_isTeamSelected ? 'Change Team' : 'Select Team'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              if (_isTeamSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Team Selected!',
                    style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
