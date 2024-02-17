import "dart:ui";

import "package:flutter/widgets.dart";

import "extent_manager.dart";

class AnimateToItem {
  AnimateToItem({
    required this.extentManager,
    required this.index,
    required this.alignment,
    required this.rect,
    required this.position,
    required this.duration,
    required this.curve,
  });

  final ExtentManager extentManager;
  final int index;
  final double alignment;
  final Rect? rect;
  final ScrollPosition position;
  final Duration duration;
  final Curve curve;

  void animate() {
    final controller = AnimationController(
      vsync: position.context.vsync,
      duration: duration,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    final start = position.pixels;
    animation.addListener(() {
      final value = animation.value;
      final targetPosition = extentManager.getOffsetToReveal(
        index,
        alignment,
        rect: rect,
        estimationOnly: value < 1.0,
      );
      final jumpPosition = lerpDouble(start, targetPosition, value)!;
      position.jumpTo(jumpPosition);
    });
    controller.forward();
  }
}
