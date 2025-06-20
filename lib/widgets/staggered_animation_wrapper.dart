import 'package:flutter/material.dart';

class StaggeredAnimationWrapper extends StatelessWidget {
  final Widget child;
  final int index;
  final double delay;
  final Animation<double> animation;

  const StaggeredAnimationWrapper({
    super.key,
    required this.child,
    required this.index,
    required this.animation,
    this.delay = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final od = index * delay;
        final odv = (animation.value - od).clamp(0.0, 1.0);

        final opv = (animation.value - .1).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - odv)),
          child: Opacity(opacity: opv, child: child),
        );
      },
    );
  }
}
