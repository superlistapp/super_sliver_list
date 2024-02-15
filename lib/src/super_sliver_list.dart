import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

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

  double getOffsetToReveal(int index, double alignment, {Rect? rect}) {
    assert(_delegate != null, "ExtentController is not attached.");
    return _delegate!.getOffsetToReveal(index, alignment, rect: rect);
  }

  void invalidateExtent(int index) {
    assert(_delegate != null, "ExtentController is not attached.");
    _delegate!.invalidateExtent(index);
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
    required this.numberOfItem,
    required this.estimatedExtentsCount,
  });

  /// The main axis extent of the viewport.
  final double viewportMainAxisExtent;

  /// The main axis extent of the content. May not be available initially.
  final double? contentTotalExtent;

  /// Number of items in the sliver.
  final int numberOfItem;

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

class SuperSliverList extends SliverMultiBoxAdaptorWidget {
  const SuperSliverList({
    super.key,
    required super.delegate,
    this.extentPrecalculationPolicy,
    this.extentController,
    this.extentEstimation,
  });

  final ExtentController? extentController;
  final ExtentEstimationProvider? extentEstimation;
  final ExtentPrecalculationPolicy? extentPrecalculationPolicy;

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
