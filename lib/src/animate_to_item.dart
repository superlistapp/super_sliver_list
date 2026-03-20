import 'dart:ui';
import 'package:flutter/widgets.dart';

import 'extent_manager.dart';

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
  final ValueGetter<int?> index;
  final double alignment;
  final Rect? rect;
  final ScrollPosition position;
  final Duration Function(double estimatedDistance) duration;
  final Curve Function(double estimatedDistance) curve;

  double lastPosition = 0.0;

  void animate() {
    final targetIndex = index();
    if (targetIndex == null) return;

    final scrollContext = position.context;
    final buildContext = scrollContext.storageContext;

    if (!buildContext.mounted) return;

    double estimatedTarget;
    try {
      estimatedTarget = extentManager.getOffsetToReveal(
        targetIndex,
        alignment,
        rect: rect,
        estimationOnly: true,
      );
    } catch (_) {
      return;
    }

    final start = position.pixels;
    final estimatedDistance = (estimatedTarget - start).abs();

    final controller = AnimationController(
      vsync: scrollContext.vsync,
      duration: duration(estimatedDistance),
    );

    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      controller.stop();
      controller.dispose();
    }

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        finish();
      }
    });

    final animation = CurvedAnimation(
      parent: controller,
      curve: curve(estimatedDistance),
    );

    animation.addListener(() {
      if (finished) return;

      final currentContext = position.context.storageContext;
      if (!currentContext.mounted) {
        finish();
        return;
      }

      final currentIndex = index();
      if (currentIndex == null) {
        finish();
        return;
      }

      double targetPosition;
      try {
        targetPosition = extentManager.getOffsetToReveal(
          currentIndex,
          alignment,
          rect: rect,
          estimationOnly: animation.value < 1.0,
        );
      } catch (_) {
        finish();
        return;
      }

      if (animation.value < 1.0) {
        targetPosition = targetPosition.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
      }

      final jumpPosition = lerpDouble(start, targetPosition, animation.value);
      if (jumpPosition == null) {
        finish();
        return;
      }

      lastPosition = jumpPosition;

      final atMin = position.pixels == position.minScrollExtent;
      final atMax = position.pixels == position.maxScrollExtent;

      if ((jumpPosition <= position.minScrollExtent && atMin) ||
          (jumpPosition >= position.maxScrollExtent && atMax)) {
        return;
      }

      try {
        position.jumpTo(jumpPosition);
      } catch (_) {
        finish();
      }
    });

    controller.forward();
  }
}