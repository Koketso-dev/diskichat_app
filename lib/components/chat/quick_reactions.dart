import 'package:flutter/material.dart';
import '../../utils/themes/app_colors.dart';

class QuickReactions extends StatelessWidget {
  final Function(String) onReactionTap;

  const QuickReactions({
    super.key,
    required this.onReactionTap,
  });

  final List<String> reactions = const [
    '⚽',
    '🔥',
    '😂',
    '💔',
    '🎉',
    '👏',
    '⚠️',
    '🟥',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: reactions.map((reaction) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onReactionTap(reaction),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reaction,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}