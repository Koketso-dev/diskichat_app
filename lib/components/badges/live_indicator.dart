import 'package:flutter/material.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';

class LiveIndicator extends StatefulWidget {
  final double size;
  final bool showText;

  const LiveIndicator({
    super.key,
    this.size = 8,
    this.showText = true,
  });

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: AppColors.liveGreen.withValues(alpha: _animation.value),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        if (widget.showText) ...[
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.liveGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}