import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

/// A premium gold shimmer/glow animation widget.
/// Wraps any child with an animated gold glow effect.
class ShimmerGlow extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double glowRadius;
  final Color glowColor;

  const ShimmerGlow({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.glowRadius = 20,
    this.glowColor = AppColors.primary,
  });

  @override
  State<ShimmerGlow> createState() => _ShimmerGlowState();
}

class _ShimmerGlowState extends State<ShimmerGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_glowAnimation.value),
                blurRadius: widget.glowRadius,
                spreadRadius: widget.glowRadius * 0.3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
