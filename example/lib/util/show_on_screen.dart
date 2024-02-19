import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

extension RenderObjectShowOnScreen on RenderObject {
  /// showOnScreen alternative that doesn't scroll if the widget is already
  /// visible and offers more customization.
  void safeShowOnScreen(
    BuildContext context, {
    /// Extra spacing for around the widget in percent of the viewport (0.05 being 5%)
    double extraSpacingPercent = 0.0,
    bool allowScrollingDown = true,
    bool allowScrollingUp = true,
  }) {
    if (!context.mounted) return;

    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport == null) return;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final minOffset =
        viewport.getOffsetToRevealExt(this, extraSpacingPercent).offset;

    final position = scrollable.position;

    if (position.pixels > minOffset && allowScrollingDown) {
      scrollable.position.moveTo(minOffset);
    } else {
      final maxOffset =
          viewport.getOffsetToRevealExt(this, 1.0 - extraSpacingPercent).offset;
      if (position.pixels < maxOffset && allowScrollingUp) {
        scrollable.position.moveTo(maxOffset);
      }
    }
  }
}
