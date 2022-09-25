import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SuperSliverList extends SliverMultiBoxAdaptorWidget {
  const SuperSliverList({
    super.key,
    required super.delegate,
  });

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return _RenderSuperSliverList(childManager: element);
  }
}

class _RenderSuperSliverList extends RenderSliverMultiBoxAdaptor {
  _RenderSuperSliverList({required super.childManager});

  /// When true the layout offsets of children are the actual offsets. This
  /// will be true while scrolling from beginning to end without jumping out
  /// of cached area.
  bool _layoutOffsetIsEstimated = false;

  double? _estimateExtent() {
    for (var child = lastChild; child != null; child = childBefore(child)) {
      final offset = childScrollOffset(child);
      if (offset != null) {
        final extent = (offset + paintExtentOf(child)) / (indexOf(child) + 1);
        return extent.roundToDouble();
      }
    }
    return null;
  }

  int? _estimatedOffsetChildIndex;
  double? _estimatedOffset;

  @override
  double? childScrollOffset(covariant RenderObject child) {
    for (var c = firstChild; c != null; c = childAfter(c)) {
      if (child == c) {
        return super.childScrollOffset(child);
      }
    }
    // Trying to query child offset of child that's not currently visible;
    // Assume this is from viewPort.getOffsetToReveal, in which case we'll
    // estimate the offset, but also remember the index and offset so that
    // we can possibly correct scrollOffset in next performLayout call.
    final offset = indexOf(child as RenderBox) * (_estimateExtent() ?? 0.0);
    _estimatedOffsetChildIndex = indexOf(child);
    _estimatedOffset = offset;
    return offset;
  }

  @override
  void performLayout() {
    // Moves the layout offset of this and subsequent children by the given delta.
    void shiftLayoutOffsets(RenderBox? child, double delta) {
      while (child != null) {
        final data = child.parentData! as SliverMultiBoxAdaptorParentData;
        data.layoutOffset = data.layoutOffset! + delta;
        child = childAfter(child);
      }
    }

    final SliverConstraints constraints = this.constraints;
    final BoxConstraints childConstraints = constraints.asBoxConstraints();

    /// Layouts single child. Will return scrollOffset of the child, or `null`
    /// if scroll ofset couldn't have been determined.
    ///
    /// Resets the layoutOffset of the child after.
    double? layoutChild(
      RenderBox child, {
      RenderBox? lastChildWithScrollOffset,
    }) {
      // If child offset can't be determined, there's no point laying out the child.
      if (childScrollOffset(child) == null &&
          lastChildWithScrollOffset == null) {
        return null;
      }
      child.layout(childConstraints, parentUsesSize: true);
      if (childScrollOffset(child) == null) {
        final data = child.parentData! as SliverMultiBoxAdaptorParentData;
        data.layoutOffset = childScrollOffset(lastChildWithScrollOffset!)! +
            paintExtentOf(lastChildWithScrollOffset);
      }
      final nextChild = childAfter(child);
      if (nextChild != null) {
        final nextChildData =
            nextChild.parentData! as SliverMultiBoxAdaptorParentData;
        nextChildData.layoutOffset = null;
      }
      return childScrollOffset(child);
    }

    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final totalChildCount = childManager.childCount;

    // Scroll offset including cache area.
    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;

    final double remainingExtent = constraints.remainingCacheExtent;

    bool addTrailingChild() {
      if (indexOf(lastChild!) < totalChildCount - 1 &&
          childScrollOffset(lastChild!)! + paintExtentOf(lastChild!) <
              scrollOffset + remainingExtent) {
        final newLayoutOffset =
            childScrollOffset(lastChild!)! + paintExtentOf(lastChild!);
        final box = insertAndLayoutChild(childConstraints,
            after: lastChild, parentUsesSize: true);
        if (box == null) {
          return false;
        }
        final data = box.parentData as SliverMultiBoxAdaptorParentData;
        data.layoutOffset = newLayoutOffset;
        return true;
      } else {
        return false;
      }
    }

    void zeroGeometry() {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
    }

    // Estimated extent is never need at the beginning of viewport
    final needExtent = scrollOffset != 0;

    // There are no children, nothing to estimate extent for.
    if (firstChild == null && needExtent) {
      if (!addInitialChild(index: 0, layoutOffset: 0)) {
        return zeroGeometry();
      }
      layoutChild(firstChild!);
      for (var i = 1; i < 20; i++) {
        if (!addTrailingChild()) {
          break;
        }
      }
    }

    // Estimate extent from currently available children.
    final extent = _estimateExtent() ?? 0.0;
    if (needExtent && extent < precisionErrorTolerance) {
      return zeroGeometry();
    }

    // First go through all children, remove those that are no longer
    // in cache area and layout those that are in the cache area.
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    RenderBox? lastChildWithScrollOffset;

    for (var child = firstChild; child != null; child = childAfter(child)) {
      // all items after first trailing garbage are automatically garbage
      if (trailingGarbage > 0) {
        ++trailingGarbage;
      } else {
        final offset = layoutChild(
          child,
          lastChildWithScrollOffset: lastChildWithScrollOffset,
        );
        if (offset == null) {
          // could not determine scroll offset, treat as leading garbage
          ++leadingGarbage;
        } else {
          lastChildWithScrollOffset = child;
          final endOffset = offset + paintExtentOf(child);
          if (offset > scrollOffset + remainingExtent) {
            ++trailingGarbage;
          } else if (endOffset < scrollOffset) {
            ++leadingGarbage;
          }
        }
      }
    }

    collectGarbage(leadingGarbage, trailingGarbage);

    // We're jumping completely over the cache area. All children have been
    // removed.
    if (firstChild == null) {
      if (scrollOffset == 0) {
        if (!addInitialChild(index: 0, layoutOffset: 0)) {
          return zeroGeometry();
        }
        // Layout offset of first child is always 0. No estimation necessary.
        _layoutOffsetIsEstimated = false;
      } else {
        // Put first child at the scroll offset, not the beginning of cached area
        double firstChildScrollOffset = constraints.scrollOffset;
        int firstChildIndex = firstChildScrollOffset ~/ extent;

        if (firstChildIndex >= totalChildCount) {
          // we didn't reach scroll offset
          geometry = SliverGeometry(
            paintExtent: 0,
            maxPaintExtent: totalChildCount * extent,
            scrollExtent: totalChildCount * extent,
          );
          childManager.didFinishLayout();
          return;
        }

        if (!addInitialChild(
          index: firstChildIndex,
          layoutOffset: firstChildIndex * extent,
        )) {
          return zeroGeometry();
        }
        // First child was put to estimated extent
        _layoutOffsetIsEstimated = true;
      }
      firstChild!.layout(childConstraints, parentUsesSize: true);
    }

    // At this point there is at least one child.
    // First we need to create children before current child all the way to the
    // beginning of cached area
    double scrollCorrection = 0;

    while (indexOf(firstChild!) > 0 &&
        childScrollOffset(firstChild!)! > scrollOffset + scrollCorrection) {
      final prevOffset = childScrollOffset(firstChild!)!;
      final box =
          insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (box == null) {
        break;
      }
      final data = box.parentData as SliverMultiBoxAdaptorParentData;
      if (!_layoutOffsetIsEstimated) {
        data.layoutOffset = prevOffset - paintExtentOf(box);
      } else {
        data.layoutOffset = prevOffset - extent;
        double correction = paintExtentOf(box) - extent;
        shiftLayoutOffsets(childAfter(box), correction);
        scrollCorrection += correction;
      }
    }

    // Additional corrections

    // Child is not first but it goes before the very beginning
    if (indexOf(firstChild!) > 0 &&
        childScrollOffset(firstChild!)! < precisionErrorTolerance) {
      _layoutOffsetIsEstimated = true;
      double correctedOffset = indexOf(firstChild!) * extent;
      double correction = correctedOffset - childScrollOffset(firstChild!)!;
      shiftLayoutOffsets(firstChild, correction);
      scrollCorrection += correction;
    }

    // First child is not at the very beginning
    if (indexOf(firstChild!) == 0 && childScrollOffset(firstChild!)! != 0) {
      double correction = -childScrollOffset(firstChild!)!;
      shiftLayoutOffsets(firstChild, correction);
      scrollCorrection += correction;
    }

    if (scrollCorrection != 0) {
      if (_estimatedOffset != null) {
        _estimatedOffset = _estimatedOffset! + scrollCorrection;
      }
      geometry = SliverGeometry(scrollOffsetCorrection: scrollCorrection);
      childManager.didFinishLayout();
      return;
    }

    if (indexOf(firstChild!) == 0) {
      assert(childScrollOffset(firstChild!)! == 0);
      _layoutOffsetIsEstimated = false;
    }

    // Add remaining children to fill the cache area
    while (addTrailingChild()) {}

    // Assume this is viewport trying to reveal particular child that was out of
    // cached are originally. We provided estimated offset for the child, but
    // the actual one might be different. If that's the case, correct the
    // position now.
    if (_estimatedOffsetChildIndex != null) {
      for (var c = firstChild; c != null; c = childAfter(c)) {
        if (_estimatedOffsetChildIndex == indexOf(c)) {
          final o = childScrollOffset(c)!;
          if (o != _estimatedOffset) {
            geometry =
                SliverGeometry(scrollOffsetCorrection: o - _estimatedOffset!);
            childManager.didFinishLayout();
            _estimatedOffsetChildIndex = null;
            _estimatedOffset = null;
            return;
          }
        }
      }
    }

    // Compute scroll extent.

    var endScrollOffset =
        childScrollOffset(lastChild!)! + paintExtentOf(lastChild!);

    final remainingChildrenCount = totalChildCount - indexOf(lastChild!) - 1;
    endScrollOffset += extent * remainingChildrenCount;

    _estimatedOffsetChildIndex = null;
    _estimatedOffset = null;

    geometry = SliverGeometry(
      scrollExtent: endScrollOffset,
      paintExtent: calculatePaintOffset(constraints,
          from: childScrollOffset(firstChild!)!, to: endScrollOffset),
      maxPaintExtent: endScrollOffset,
      cacheExtent: calculateCacheOffset(constraints,
          from: childScrollOffset(firstChild!)!, to: endScrollOffset),
      hasVisualOverflow: endScrollOffset > constraints.remainingPaintExtent,
    );

    childManager.didFinishLayout();
  }
}