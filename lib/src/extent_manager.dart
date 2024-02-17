import "dart:ui";

import "package:flutter/foundation.dart";

import "extent_list.dart";

abstract class ExtentManagerDelegate {
  const ExtentManagerDelegate();

  void onMarkNeedsLayout();
  double estimateExtentForItem(int index);
  double getOffsetToReveal(
    int index,
    double alignment, {
    required bool estimationOnly,
    Rect? rect,
  });
}

class ExtentManager with ChangeNotifier {
  ExtentManager({required this.delegate});

  double _beforeCorrection = 0.0;
  double _afterCorrection = 0.0;

  final ExtentManagerDelegate delegate;

  double get correctionPercentage => _afterCorrection / _beforeCorrection;

  void setExtent(int index, double extent, {bool isEstimation = false}) {
    if (!isEstimation) {
      _beforeCorrection += _extentList[index];
      _afterCorrection += extent;
    }
    _extentList.setExtent(index, extent, isEstimation: isEstimation);
    _isModified = true;
  }

  void markAllDirty() {
    _afterCorrection = 0.0;
    _beforeCorrection = 0.0;
    _isModified = true;
    _extentList.markAllDirty();
  }

  bool get hasDirtyItems => _extentList.hasDirtyItems;

  double get totalExtent => _extentList.totalExtent;

  int? get cleanRangeStart => _extentList.cleanRangeStart;
  int? get cleanRangeEnd => _extentList.cleanRangeEnd;

  @pragma("vm:prefer-inline")
  double getExtent(int index) => _extentList[index];

  void resize(
    int newSize,
  ) {
    if (newSize == _extentList.length) {
      return;
    }
    _isModified = true;
    _extentList.resize(newSize, delegate.estimateExtentForItem);
  }

  final _extentList = ExtentList();

  int? indexForOffset(double offset) {
    for (int index = 0; index < _extentList.length; ++index) {
      final extent = _extentList[index];
      if (offset < extent) {
        return index;
      }
      offset -= extent;
    }
    return null;
  }

  double offsetForIndex(int index) {
    assert(index >= 0 && index < _extentList.length);
    double offset = 0;
    for (int i = 0; i < index; ++i) {
      offset += _extentList[i];
    }
    return offset;
  }

  (double, bool) extentForIndex(int index) {
    return (_extentList[index], _extentList.isDirty(index));
  }

  bool _layoutInProgress = false;
  bool _isModified = false;

  void beginLayout() {
    assert(!_layoutInProgress);
    _layoutInProgress = true;
    _isModified = false;
    _beforeCorrection = 0.0;
    _afterCorrection = 0.0;
  }

  void endLayout() {
    assert(_layoutInProgress);
    _layoutInProgress = false;
    if (_isModified) {
      notifyListeners();
    }
  }

  int get numberOfItems => _extentList.length;

  int get estimatedExtentsCount => _extentList.estimatedExtentsCount;

  void addItem(int index) {
    _extentList.insertAt(index, delegate.estimateExtentForItem);
    delegate.onMarkNeedsLayout();
  }

  void removeItem(int index) {
    _extentList.removeAt(index);
    delegate.onMarkNeedsLayout();
  }

  void invalidateExtent(int index) {
    _extentList.markDirty(index);
    delegate.onMarkNeedsLayout();
  }

  void invalidateAllExtents() {
    _extentList.markAllDirty();
    delegate.onMarkNeedsLayout();
  }

  bool get isLocked => _layoutInProgress;

  double getOffsetToReveal(
    int index,
    double alignment, {
    Rect? rect,
    required bool estimationOnly,
  }) {
    return delegate.getOffsetToReveal(
      index,
      alignment,
      rect: rect,
      estimationOnly: estimationOnly,
    );
  }

  @override
  String toString() {
    return "ExtentManager ${identityHashCode(this).toRadixString(16)}";
  }
}
