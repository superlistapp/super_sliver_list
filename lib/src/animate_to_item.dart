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
    required this.whenCompleteOrCancel,
  });

  final ExtentManager extentManager;
  final ValueGetter<int?> index;
  final double alignment;
  final Rect? rect;
  final ScrollPosition position;
  final Duration Function(double estimatedDistance) duration;
  final Curve Function(double estimatedDistance) curve;
  final void Function() whenCompleteOrCancel;

  double lastPosition = 0.0;

  late AnimationController _controller;
  late CurvedAnimation _animation;

  bool _mustDispose = false;

  void dispose() {
    if (_mustDispose) {
      _mustDispose = false;
      _controller.dispose();
      _animation.dispose();
      whenCompleteOrCancel();
    }
  }

  void animate() {
    _mustDispose = true;

    final index = this.index();
    if (index == null) {
      return;
    }
    final start = position.pixels;
    final estimatedTarget = extentManager.getOffsetToReveal(
      index,
      alignment,
      rect: rect,
      estimationOnly: true,
    );
    final estimatedDistance = (estimatedTarget - start).abs();
    _controller = AnimationController(
      vsync: position.context.vsync,
      duration: duration(estimatedDistance),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: curve(estimatedDistance),
    );
    _animation.addListener(() {
      final value = _animation.value;
      final index = this.index();
      if (index == null) {
        dispose();
        return;
      }
      var targetPosition = extentManager.getOffsetToReveal(
        index,
        alignment,
        rect: rect,
        estimationOnly: value < 1.0,
      );
      if (value < 1.0) {
        // Clamp position during animation to prevent overscroll.
        targetPosition = targetPosition.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
      }
      final jumpPosition = lerpDouble(start, targetPosition, value)!;
      lastPosition = jumpPosition;
      if ((jumpPosition <= position.minScrollExtent &&
              position.pixels == position.minScrollExtent) ||
          (jumpPosition >= position.maxScrollExtent &&
              position.pixels == position.maxScrollExtent)) {
        // Do not jump when already at the edge. This prevents scrollbar handle artifacts.
        return;
      }
      position.jumpTo(jumpPosition);
    });
    _controller.forward().whenCompleteOrCancel(dispose);
  }
}
