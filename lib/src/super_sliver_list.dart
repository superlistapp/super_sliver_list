import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "animate_to_item.dart";
import "element.dart";
import "extent_manager.dart";
import "layout_budget.dart";
import "render_object.dart";

class ExtentController extends ChangeNotifier {
  ExtentController({
    this.onAttached,
    this.onDetached,
  });

  final VoidCallback? onAttached;
  final VoidCallback? onDetached;

  bool get isAttached => _delegate != null;

  int get numberOfItems {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.numberOfItems;
  }

  (double, bool isEstimated) extentForIndex(int index) {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.extentForIndex(index);
  }

  double get totalExtent {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.totalExtent;
  }

  int get estimatedExtentsCount {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.estimatedExtentsCount;
  }

  bool get isLocked {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.isLocked;
  }

  void jumpToItem({
    required int index,
    required ScrollController scrollController,
    required double alignment,
    Rect? rect,
  }) {
    assert(_delegate != null, "ExtentController is not attached.");
    final offset = getOffsetToReveal(index, alignment, rect: rect);
    scrollController.jumpTo(offset);
  }

  void animateToItem({
    required int index,
    required ScrollController scrollController,
    required double alignment,
    required Duration duration,
    required Curve curve,
    Rect? rect,
  }) {
    assert(_delegate != null, "ExtentController is not attached.");
    for (final position in scrollController.positions) {
      AnimateToItem(
        extentManager: _delegate!,
        index: index,
        alignment: alignment,
        rect: rect,
        position: position,
        curve: curve,
        duration: duration,
      ).animate();
    }
  }

  void invalidateExtent(int index) {
    assert(_delegate != null, "ExtentController is not attached.");
    _delegate!.invalidateExtent(index);
  }

  void invalidateAllExtents() {
    assert(_delegate != null, "ExtentController is not attached.");
    _delegate!.invalidateAllExtents();
  }

  void addItem(int index) {
    assert(_delegate != null, "ExtentController is not attached.");
    _delegate!.addItem(index);
  }

  void removeItem(int index) {
    assert(_delegate != null, "ExtentController is not attached.");
    _delegate!.removeItem(index);
  }

  @override
  void dispose() {
    if (_delegate != null) {
      unsetDelegate(_delegate!);
    }
    super.dispose();
  }

  ExtentManager? _delegate;

  void setDelegate(ExtentManager delegate) {
    if (_delegate == delegate) {
      return;
    }
    if (_delegate != null) {
      onDetached?.call();
    }
    _delegate?.removeListener(notifyListeners);
    _delegate = delegate;
    _delegate?.addListener(notifyListeners);
    if (_delegate != null) {
      onAttached?.call();
    }
  }

  void unsetDelegate(ExtentManager delegate) {
    if (_delegate == delegate) {
      _delegate?.removeListener(notifyListeners);
      _delegate = null;
      onDetached?.call();
    }
  }

  @visibleForTesting
  double getOffsetToReveal(int index, double alignment, {Rect? rect}) {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.getOffsetToReveal(
      index,
      alignment,
      rect: rect,
      estimationOnly: false,
    );
  }
}

typedef ExtentEstimationProvider = double Function(
  int index,
  double crossAxisExtent,
);

abstract class ExtentPrecalculationPolicyDelegate {
  void valueDidChange();
}

class ExtentPrecalculationContext {
  ExtentPrecalculationContext({
    required this.viewportMainAxisExtent,
    required this.contentTotalExtent,
    required this.numberOfItems,
    required this.estimatedExtentsCount,
  });

  /// The main axis extent of the viewport.
  final double viewportMainAxisExtent;

  /// The main axis extent of the content. May not be available initially.
  final double? contentTotalExtent;

  /// Number of items in the sliver.
  final int numberOfItems;

  /// Number of items in the sliver with estimated extents.
  final int estimatedExtentsCount;
}

abstract class ExtentPrecalculationPolicy {
  void onAttached() {}
  void onDetached() {}
  bool shouldPrecaculateExtents(ExtentPrecalculationContext context);

  void valueDidChange() {
    for (final delegate in _delegates) {
      delegate.valueDidChange();
    }
  }

  void addDelegate(ExtentPrecalculationPolicyDelegate? value) {
    _delegates.add(value!);
    if (_delegates.length == 1) {
      onAttached();
    }
  }

  void removeDelegate(ExtentPrecalculationPolicyDelegate? value) {
    _delegates.remove(value);
    if (_delegates.isEmpty) {
      onDetached();
    }
  }

  final _delegates = <ExtentPrecalculationPolicyDelegate>{};
}

/// Drop-in replacement for [SliverList] that can handle arbitrary large amount
/// of items with variable extent.
///
/// Through [extentController] it [SuperSliverList] also provides a way to
/// jump to any item in the list, even if the item is not currently visible
/// or has not been laid out.
class SuperSliverList extends SliverMultiBoxAdaptorWidget {
  const SuperSliverList({
    super.key,
    required super.delegate,
    this.extentPrecalculationPolicy,
    this.extentController,
    this.extentEstimation,
    this.delayPopulatingCacheArea = true,
  });

  /// When set provides access to extents of individual children.
  /// [ExtentController] can also be used to jump to a specific item in the list.
  final ExtentController? extentController;

  /// Optional method that can be used to override default estimated extent for
  /// each item. Initially all extents are estimated and then as the items are laid
  /// out, either through scrolling or [extentPrecalculationPolicy], the actual
  /// extents are calculated and the scroll offset is adjusted to account for
  /// the difference between estimated and actual extents.
  final ExtentEstimationProvider? extentEstimation;

  /// Optional policy that can be used to asynchronously precalculate the extents
  /// of the items in the list. This can be useful allow precise scrolling on small
  /// lists where the difference between estimated and actual extents may be noticeable
  /// when interacting with the scrollbar. For larger lists precalculating extent
  /// has diminished benefits since the error for each item does not impact the
  /// overall scroll position as much.
  final ExtentPrecalculationPolicy? extentPrecalculationPolicy;

  /// Whether the items in cache area should be built delayed.
  /// This is an optimization that kicks in during fast scrolling, when
  /// all items are being replaced on every frame.
  /// With [delayPopulatingCacheArea] set to `true`, the items in cache area
  /// are only built after the scrolling slows down.
  final bool delayPopulatingCacheArea;

  static SuperSliverListLayoutBudget layoutBudget =
      _TimeSuperSliverListLayoutBudget(
    budget: const Duration(milliseconds: 3),
  );

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SuperSliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final element = context as SuperSliverMultiBoxAdaptorElement;
    return RenderSuperSliverList(
      childManager: element,
      extentPrecalculationPolicy: extentPrecalculationPolicy,
      estimateExtent: extentEstimation ?? _defaultEstimateExtent,
      delayPopulatingCacheArea: delayPopulatingCacheArea,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    final renderSliverList = renderObject as RenderSuperSliverList;
    renderSliverList.extentPrecalculationPolicy = extentPrecalculationPolicy;
    renderSliverList.estimateExtent =
        extentEstimation ?? _defaultEstimateExtent;
    renderSliverList.delayPopulatingCacheArea = delayPopulatingCacheArea;
  }
}

class _TimeSuperSliverListLayoutBudget extends SuperSliverListLayoutBudget {
  _TimeSuperSliverListLayoutBudget({
    required this.budget,
  });

  @override
  void reset() {
    _stopwatch.reset();
  }

  @override
  void beginLayout() {
    _stopwatch.start();
  }

  @override
  void endLayout() {
    _stopwatch.stop();
  }

  @override
  bool shouldLayoutNextItem() {
    return _stopwatch.elapsed < budget;
  }

  final _stopwatch = Stopwatch();

  final Duration budget;
}

double _defaultEstimateExtent(int index, double crossAxisExtent) {
  return 100.0;
}
