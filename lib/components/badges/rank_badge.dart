import 'package:flutter/material.dart';
import '../../utils/constants/rank_constants.dart';
import '../../utils/helpers/rank_helper.dart';
import '../../utils/themes/text_styles.dart';

class RankBadge extends StatelessWidget {
  final UserRank rank;
  final double size;
  final bool showLabel;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 24,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = RankHelper.getRankColor(rank);
    final icon = RankHelper.getRankIcon(rank);
    final label = RankHelper.getRankDisplayName(rank);

    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: showLabel
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: size * 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      )
          : Text(
        icon,
        style: TextStyle(fontSize: size * 0.8),
      ),
    );
  }
}