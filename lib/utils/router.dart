import 'package:go_router/go_router.dart';

import '../data/models/match_model.dart';
import '../data/models/post_model.dart';
import '../screens/auth/welcome_auth_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/video_player_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding/team_selection_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_setup/profile_wizard_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/feature_request_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/social/create_post_screen.dart';
import '../screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const WelcomeAuthScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileWizardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat/:matchId',
      builder: (context, state) {
        final match = state.extra as MatchModel;
        return ChatRoomScreen(match: match);
      },
    ),
    GoRoute(
      path: '/video-player',
      builder: (context, state) {
        final url = state.extra as String;
        return VideoPlayerScreen(videoUrl: url);
      },
    ),
    GoRoute(
      path: '/create-post',
      builder: (context, state) =>
          CreatePostScreen(postToEdit: state.extra as PostModel?),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/team-selection',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>;
        return TeamSelectionScreen(
          userId: params['userId'] as String,
          subscriptionType: params['subscriptionType'] as String,
          currentFollowCount: params['currentFollowCount'] as int,
          countryName: params['countryName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/settings/feedback',
      builder: (context, state) => const FeatureRequestScreen(),
    ),
    GoRoute(
      path: '/settings/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
