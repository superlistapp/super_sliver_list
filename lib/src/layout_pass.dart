import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';

import 'render_object.dart';

class SliverLayoutState {
  bool didAddInitialChild = false;
  bool didRemoveChildren = false;
  bool didSetPreviousConstraint = false;
  bool? precalculateExtents;
}

class LayoutPass {
  LayoutPass({
    required this.slivers,
    required this.initialScrollPosition,
    required this.childScrollOffsetEstimation,
    required this.sliverWithExtentEstimation,
  });

  bool isNew = true;

  final List<RenderSuperSliverList> slivers;
  final double initialScrollPosition;
  final bool childScrollOffsetEstimation;
  final RenderSuperSliverList? sliverWithExtentEstimation;

  final sliversDuringLayout = <RenderSuperSliverList>[];

  bool sliverIsBeforeSliverWithOffsetEstimation(RenderSuperSliverList s) {
    assert(sliversDuringLayout.contains(s));
    if (sliverWithExtentEstimation == null) {
      return false;
    }
    final index = sliversDuringLayout.indexOf(sliverWithExtentEstimation!);
    return index == -1 // not reached yet
        ||
        index > sliversDuringLayout.indexOf(s);
  }

  SliverLayoutState getLayoutState(RenderSuperSliverList sliver) {
    return _sliverLayoutState.putIfAbsent(sliver, () => SliverLayoutState());
  }

  final _sliverLayoutState = <RenderSuperSliverList, SliverLayoutState>{};

  int correctionCount = 0;
}

final _viewportToLayoutPass = Expando<LayoutPass>();

extension RenderSliverLayoutPass on RenderSliver {
  RenderViewport? getViewport() {
    RenderObject? parent = this.parent;
    while (parent != null) {
      if (parent is RenderViewport) {
        return parent;
      }
      parent = parent.parent;
    }
    return null;
  }

  static void _gatherSliverList(
      List<RenderSuperSliverList> slivers, RenderObject sliver) {
    if (sliver is RenderSuperSliverList) {
      slivers.add(sliver);
    } else {
      sliver.visitChildren((child) {
        if (child is RenderSliver) {
          _gatherSliverList(slivers, child);
        }
      });
    }
  }

  LayoutPass? getLayoutPass(RenderSuperSliverList self) {
    final viewport = getViewport();
    if (viewport == null) {
      return null;
    }
    var pass = _viewportToLayoutPass[viewport];
    if (pass == null) {
      final slivers = <RenderSuperSliverList>[];
      _gatherSliverList(slivers, viewport);
      var sliverWithOffsetEstimation = slivers.firstWhereOrNull(
          (element) => element.hasChildScrollOffsetEstimation);
      if (sliverWithOffsetEstimation != null) {
        sliverWithOffsetEstimation
            .sanitizeChildScrollOffsetEstimation(viewport);
        if (!sliverWithOffsetEstimation.hasChildScrollOffsetEstimation) {
          sliverWithOffsetEstimation = null;
        }
      }
      pass = LayoutPass(
        slivers: slivers,
        // Note: This only works if there are no other sliver being laid out
        // first that do scroll offset correction. Unfortunately there isn't any
        // way in Flutter to get the original (uncorrected) scroll position.
        initialScrollPosition: viewport.offset.pixels,
        childScrollOffsetEstimation: sliverWithOffsetEstimation != null,
        sliverWithExtentEstimation: sliverWithOffsetEstimation,
      );
      _viewportToLayoutPass[viewport] = pass;
      Future.microtask(() {
        _viewportToLayoutPass[viewport] = null;
      });
    }
    if (!pass.sliversDuringLayout.contains(self)) {
      pass.sliversDuringLayout.add(self);
    }
    return pass;
  }
}
