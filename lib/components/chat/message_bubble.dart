import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../utils/helpers/time_helper.dart';
import '../../utils/helpers/rank_helper.dart';
import '../badges/rank_badge.dart';
import '../avatars/custom_avatar.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwnMessage;
  final String matchId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage();
    }

    if (message.isGoal) {
      return _buildGoalMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CustomAvatar(
            imageUrl: message.avatarUrl,
            size: 40,
          ),

          const SizedBox(width: 12),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and rank
                Row(
                  children: [
                    Text(
                      message.displayName ?? 'Anonymous',
                      style: AppTextStyles.messageUsername,
                    ),
                    const SizedBox(width: 8),
                    if (message.userRank != null)
                      RankBadge(
                        rank: RankHelper.getRankFromString(message.userRank!),
                        size: 16,
                      ),
                    const Spacer(),
                    Text(
                      TimeHelper.formatMessageTime(message.createdAt),
                      style: AppTextStyles.messageTime,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Message text
                Text(
                  message.message,
                  style: AppTextStyles.messageText,
                ),

                const SizedBox(height: 8),

                // Actions (votes)
                Row(
                  children: [
                    _buildVoteButton(
                      context,
                      icon: Icons.arrow_upward,
                      voteType: 'up',
                      color: AppColors.upvote,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.votes.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildVoteButton(
                      context,
                      icon: Icons.arrow_downward,
                      voteType: 'down',
                      color: AppColors.downvote,
                    ),
                    const SizedBox(width: 16),
                    if (message.isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.push_pin,
                              size: 12,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(
      BuildContext context, {
        required IconData icon,
        required String voteType,
        required Color color,
      }) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final userVote = chatProvider.getUserVote(message.id);
    final isActive = userVote == voteType;

    return GestureDetector(
      onTap: () {
        chatProvider.voteMessage(
          matchId: matchId,
          messageId: message.id,
          voteType: voteType,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha:0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? color : AppColors.textGray,
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withValues(alpha:0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGray,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.liveGreen.withValues(alpha:0.2),
              AppColors.liveGreen.withValues(alpha:0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.liveGreen.withValues(alpha:0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.liveGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: AppColors.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOAL! ⚽',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.liveGreen,
                    ),
                  ),
                  Text(
                    message.message,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}