import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/themes/app_colors.dart';
import '../utils/themes/text_styles.dart';
import '../utils/helpers/rank_helper.dart';
import '../utils/constants/rank_constants.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../components/badges/rank_badge.dart';
import '../components/avatars/custom_avatar.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('PROFILE', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final userProfile = authProvider.userProfile;

          if (user == null || userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 80, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Not logged in', style: AppTextStyles.h3),
                ],
              ),
            );
          }

          final rank = RankHelper.getRankFromString(userProfile.rank);
          final rankProgress = RankHelper.getRankProgress(userProfile.points, rank);
          final pointsToNext = RankConstants.getPointsToNextRank(userProfile.points);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CustomAvatar(imageUrl: userProfile.avatarUrl, size: 100),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: RankBadge(rank: rank),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(userProfile.displayName, style: AppTextStyles.h2),
                      const SizedBox(height: 4),
                      Text(
                        '@${userProfile.username}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem(
                            icon: Icons.sports_soccer,
                            label: 'Diskis',
                            value: userProfile.points.toString(),
                          ),
                          const SizedBox(width: 32),
                          _buildStatItem(
                            icon: Icons.emoji_events,
                            label: 'Rank',
                            value: RankHelper.getRankDisplayName(rank),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (rank != UserRank.goat) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress to ${RankHelper.getRankDisplayName(RankConstants.getNextRank(rank)!)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  '$pointsToNext Diskis',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: rankProgress,
                                minHeight: 8,
                                backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentBlue,
                          side: const BorderSide(color: AppColors.accentBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildMenuItem(
                  icon: Icons.feedback,
                  title: 'Feedback',
                  onTap: () => context.push('/settings/feedback'),
                ),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () => context.push('/settings/help'),
                ),
                _buildMenuItem(
                  icon: Icons.info,
                  title: 'About',
                  onTap: () => context.push('/settings/about'),
                ),
                _buildMenuItem(
                  icon: Icons.share,
                  title: 'Invite a Friend',
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out Diskichat! The ultimate app for soccer fans. Download it now: https://diskichat.app',
                        subject: 'Join me on Diskichat!',
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Subscription Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cardSurface, AppColors.cardSurface.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subscription', style: AppTextStyles.h3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: userProfile.subscriptionType == 'premium'
                                  ? AppColors.liveGreen.withValues(alpha: 0.2)
                                  : AppColors.textGray.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: userProfile.subscriptionType == 'premium'
                                    ? AppColors.liveGreen
                                    : AppColors.textGray,
                              ),
                            ),
                            child: Text(
                              userProfile.subscriptionType == 'premium' ? 'PREMIUM' : 'FREE',
                              style: AppTextStyles.caption.copyWith(
                                color: userProfile.subscriptionType == 'premium'
                                    ? AppColors.liveGreen
                                    : AppColors.textGray,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (userProfile.subscriptionType != 'premium') ...[
                        Text(
                          'Unlock full access to matches and features.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildPlanOption(context, 'Weekly', 'R19', () => _showSubscriptionModal(context, 'Weekly', user.uid))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPlanOption(context, 'Monthly', 'R49', () => _showSubscriptionModal(context, 'Monthly', user.uid), isPopular: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPlanOption(context, 'Annual', 'R499', () => _showSubscriptionModal(context, 'Annual', user.uid))),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.liveGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have full access to all matches and premium features.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => authProvider.updateProfile(subscriptionType: 'basic'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textGray,
                              side: const BorderSide(color: AppColors.textGray),
                            ),
                            child: const Text('Cancel Subscription'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: textColor ?? AppColors.textWhite),
        title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: textColor ?? AppColors.textWhite)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGray),
        tileColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, String title, String price, VoidCallback onTap, {bool isPopular = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isPopular ? AppColors.primaryBlue : Colors.transparent,
          border: Border.all(
            color: isPopular ? AppColors.primaryBlue : AppColors.textGray.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (isPopular) ...[
              Text(
                'BEST VALUE',
                style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isPopular ? Colors.white : AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isPopular ? Colors.white : AppColors.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionModal(BuildContext context, String plan, String userId) {
    AnalyticsService().logUpgradeClick(fromScreen: 'profile_screen');
    FirestoreService().logSubscriptionAttempt(userId, plan);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Coming Soon!', style: TextStyle(color: AppColors.textWhite)),
        content: const Text(
          'Premium subscriptions are not yet active. Please enjoy the FULL version of Diskichat for FREE for now!',
          style: TextStyle(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Awesome!', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }
}
