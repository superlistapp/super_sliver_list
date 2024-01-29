import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'element.dart';
import 'extent_manager.dart';
import 'layout_budget.dart';
import 'render_object.dart';

typedef ExtentEstimationProvider = double Function(
  int index,
  double crossAxisExtent,
);

class ExtentController extends ChangeNotifier {
  ExtentController({
    this.onAttached,
    this.onDetached,
  });

  final VoidCallback? onAttached;
  final VoidCallback? onDetached;

  bool get isAttached => _delegate != null;

  int get numberOfItems {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.numberOfItems;
  }

  (double, bool isEstimated) extentForIndex(int index) {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.extentForIndex(index);
  }

  double get totalExtent {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.totalExtent;
  }

  double get fractionComplete {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.fractionComplete;
  }

  bool get isLocked {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.isLocked;
  }

  double getOffsetToReveal(int index, double alignment) {
    assert(_delegate != null, 'ExtentController is not attached.');
    return _delegate!.getOffsetToReveal(index, alignment);
  }

  void invalidateExtent(int index) {
    assert(_delegate != null, 'ExtentController is not attached.');
    _delegate!.invalidateExtent(index);
  }

  void addItem(int index) {
    assert(_delegate != null, 'ExtentController is not attached.');
    _delegate!.addItem(index);
  }

  void removeItem(int index) {
    assert(_delegate != null, 'ExtentController is not attached.');
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

double _defaultEstimateExtent(int index, double crossAxisExtent) {
  return 100.0;
}

bool _defaultPrecalculateExtents() {
  return false;
}

class SuperSliverList extends SliverMultiBoxAdaptorWidget {
  const SuperSliverList({
    super.key,
    required super.delegate,
    this.precalculateExtents,
    this.extentController,
    this.extentEstimation,
  });

  final ExtentController? extentController;
  final ExtentEstimationProvider? extentEstimation;
  final ValueGetter<bool>? precalculateExtents;

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
      precalculateExtents: precalculateExtents ?? _defaultPrecalculateExtents,
      estimateExtent: extentEstimation ?? _defaultEstimateExtent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    super.updateRenderObject(context, renderObject);
    final renderSliverList = renderObject as RenderSuperSliverList;
    renderSliverList.precalculateExtents =
        precalculateExtents ?? _defaultPrecalculateExtents;
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
