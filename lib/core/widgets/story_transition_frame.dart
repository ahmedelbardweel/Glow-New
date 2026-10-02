import 'package:flutter/material.dart';

import '../models/story_timeline.dart';

/// Applies a timeline transition to the character without touching the 3D scene.
class StoryTransitionFrame extends StatelessWidget {
  final StoryTransitionPose pose;
  final Widget child;

  const StoryTransitionFrame({
    super.key,
    required this.pose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Opacity(
        opacity: pose.opacity.clamp(0.0, 1.0),
        child: FractionalTranslation(
          translation: Offset(pose.slide, pose.jump),
          child: Transform.scale(
            scale: pose.scale,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}
