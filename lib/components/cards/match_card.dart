import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../data/models/match_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../utils/helpers/time_helper.dart';
import '../avatars/custom_avatar.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat/${match.id}', extra: match),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.competitionName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: FirestoreService().getActiveUsersCount(match.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0 && !match.isLive) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people, size: 12, color: AppColors.accentBlue),
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.isLive
                          ? AppColors.liveGreen
                          : match.isUpcoming
                              ? AppColors.primaryBlue
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.isLive
                          ? 'LIVE MATCH'
                          : match.isUpcoming
                              ? 'PREMATCH'
                              : 'POSTMATCH',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Match info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.homeLogo),
                            const SizedBox(height: 8),
                            Text(
                              match.homeTeam,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (match.isLive || match.isFinished)
                              Text(match.scoreDisplay, style: AppTextStyles.scoreMedium)
                            else
                              Text('VS', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
                            if (match.isUpcoming) ...[
                              const SizedBox(height: 4),
                              Text(
                                TimeHelper.formatMatchTime(match.matchDate),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (match.isLive || match.isFinished)
                              Text(
                                match.elapsedTime ?? match.statusDisplay,
                                style: AppTextStyles.caption.copyWith(
                                  color: match.isLive ? AppColors.liveGreen : AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildTeamLogo(match.awayLogo),
                            const SizedBox(height: 8),
                            Text(
                              match.awayTeam,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final isJoined = chatProvider.isJoined(match.id);
                      return Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isJoined
                              ? AppColors.primaryLight
                              : match.isLive
                                  ? AppColors.liveGreen
                                  : match.isUpcoming
                                      ? AppColors.primaryBlue
                                      : Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/chat/${match.id}', extra: match),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isJoined ? Icons.play_arrow_rounded : Icons.chat_bubble,
                                  color: AppColors.textWhite,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isJoined
                                      ? 'RESUME MATCH ROOM'
                                      : match.isUpcoming
                                          ? 'JOIN PREMATCH'
                                          : match.isLive
                                              ? 'JOIN LIVE MATCH'
                                              : 'JOIN POSTMATCH',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, color: AppColors.textWhite, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: CustomAvatar(imageUrl: logoUrl, size: 60, placeholder: ''),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.cardSurface),
      child: const Icon(Icons.sports_soccer, color: AppColors.textGray, size: 30),
    );
  }
}
