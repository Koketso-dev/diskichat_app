import 'package:flutter/material.dart';
import '../utils/themes/app_colors.dart';
import '../utils/themes/text_styles.dart';
import '../utils/routes.dart';
import '../components/buttons/gradient_button.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import 'auth/welcome_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      image: 'lib/assets/images/onboarding1.webp',
      title: 'The Ultimate\nSecond Screen',
      description: 'Engage live during matches. The perfect companion for every football fan.',
    ),
    OnboardingPage(
      image: 'lib/assets/images/onboarding2.jpg',
      title: 'Join the\nBanter Rooms',
      description: 'Troll your rivals, celebrate with your team. Where the real conversation happens.',
    ),
    OnboardingPage(
      image: 'lib/assets/images/onboarding3.jpg',
      title: 'Peer-to-Peer\nBetting',
      description: 'Challenge friends with Diski Points. Predict the score, winner takes the pot!',
    ),
    OnboardingPage(
      image: 'lib/assets/images/onboarding4.jpg',
      title: 'Join the\nCommunity',
      description: 'Connect with fans worldwide. Your voice matters in the beautiful game.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Page Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          
          // Skip Button
          Positioned(
            top: 50,
            right: 24,
            child: TextButton(
              onPressed: _goToAuth,
              child: Text(
                'Skip',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Button
                _currentPage == _pages.length - 1
                    ? GradientButton(
                        text: 'Join Diskichat',
                        onPressed: _goToAuth,
                      )
                    : GradientButton(
                        text: 'Next',
                        onPressed: _nextPage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Column(
      children: [
        // Image Section (40% Height)
        Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  page.image,
                  fit: BoxFit.cover,
                ),
                // Gradient Fade to White
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0], 
                      colors: [
                        Colors.transparent,
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
        
        // Text Section (60% Height approx, actually remaining space)
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  page.title,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.black, // Dark text for white background
                    fontSize: 32,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  page.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.black54, // Darker gray for white background
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentPage == index
            ? AppColors.accentBlue
            : AppColors.textGray.withValues(alpha:0.3),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToAuth() async {
    // Analytics
    await AnalyticsService().logSignUp();

    // Mark onboarding as done
    await StorageService().setOnboardingDone(true);
    if (!mounted) return;
    AppRoutes.navigateReplace(context, const WelcomeAuthScreen());
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}