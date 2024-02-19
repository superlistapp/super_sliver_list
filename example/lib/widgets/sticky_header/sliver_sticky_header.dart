import "dart:math" as math;
import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

// This is a stripped-down minimal version of flutter_sticky_header from
// https://github.com/letsar/flutter_sticky_headers
// adapted to use child obstruction extent.
// Copyright (c) 2018 Romain Rastel

/// A sliver that displays a header before its sliver.
/// The header scrolls off the viewport only when the sliver does.
///
/// Place this widget inside a [CustomScrollView] or similar.
class SliverStickyHeader extends RenderObjectWidget {
  const SliverStickyHeader({
    super.key,
    this.header,
    this.sliver,
  });

  /// The header to display before the sliver.
  final Widget? header;

  /// The sliver to display after the header.
  final Widget? sliver;

  @override
  RenderSliverStickyHeader createRenderObject(BuildContext context) {
    return RenderSliverStickyHeader();
  }

  @override
  SliverStickyHeaderRenderObjectElement createElement() =>
      SliverStickyHeaderRenderObjectElement(this);
}

class SliverStickyHeaderRenderObjectElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  SliverStickyHeaderRenderObjectElement(SliverStickyHeader super.widget);

  @override
  SliverStickyHeader get widget => super.widget as SliverStickyHeader;

  Element? _header;

  Element? _sliver;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_sliver != null) visitor(_sliver!);
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);
    if (child == _header) _header = null;
    if (child == _sliver) _sliver = null;
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _header = updateChild(_header, widget.header, 0);
    _sliver = updateChild(_sliver, widget.sliver, 1);
  }

  @override
  void update(SliverStickyHeader newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _header = updateChild(_header, widget.header, 0);
    _sliver = updateChild(_sliver, widget.sliver, 1);
  }

  @override
  void insertRenderObjectChild(RenderObject child, int? slot) {
    final RenderSliverStickyHeader renderObject =
        this.renderObject as RenderSliverStickyHeader;
    if (slot == 0) renderObject.header = child as RenderBox?;
    if (slot == 1) renderObject.child = child as RenderSliver?;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, Object? slot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final RenderSliverStickyHeader renderObject =
        this.renderObject as RenderSliverStickyHeader;
    if (renderObject.header == child) renderObject.header = null;
    if (renderObject.child == child) renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

/// A sliver with a [RenderBox] as header and a [RenderSliver] as child.
///
/// The [header] stays pinned when it hits the start of the viewport until
/// the [child] scrolls off the viewport.
class RenderSliverStickyHeader extends RenderSliver with RenderSliverHelpers {
  RenderSliverStickyHeader({
    RenderObject? header,
    RenderSliver? child,
  }) {
    this.header = header as RenderBox?;
    this.child = child;
  }

  /// The render object's header
  RenderBox? get header => _header;
  RenderBox? _header;

  set header(RenderBox? value) {
    if (_header != null) dropChild(_header!);
    _header = value;
    if (_header != null) adoptChild(_header!);
  }

  /// The render object's unique child
  RenderSliver? get child => _child;
  RenderSliver? _child;

  set child(RenderSliver? value) {
    if (_child != null) dropChild(_child!);
    _child = value;
    if (_child != null) adoptChild(_child!);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _header?.attach(owner);
    _child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    _header?.detach();
    _child?.detach();
  }

  @override
  void redepthChildren() {
    if (_header != null) {
      redepthChild(_header!);
    }
    if (_child != null) {
      redepthChild(_child!);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final result = <DiagnosticsNode>[];
    if (header != null) {
      result.add(header!.toDiagnosticsNode(name: "header"));
    }
    if (child != null) {
      result.add(child!.toDiagnosticsNode(name: "child"));
    }
    return result;
  }

  double get _headerExtent {
    if (header == null) {
      return 0.0;
    }
    assert(header!.hasSize);
    switch (constraints.axis) {
      case Axis.vertical:
        return header!.size.height;
      case Axis.horizontal:
        return header!.size.width;
    }
  }

  double get _headerPosition {
    final double childScrollExtent = child?.geometry?.scrollExtent ?? 0.0;
    final res = math.min(math.max(constraints.overlap, 0.0),
        childScrollExtent - constraints.scrollOffset);
    return res;
  }

  @override
  void performLayout() {
    final header = this.header;
    final child = this.child;

    if (header == null && child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    if (header != null) {
      header.layout(
        constraints.asBoxConstraints(),
        parentUsesSize: true,
      );
    }

    // Compute the header extent only one time.
    final headerExtent = _headerExtent;
    final double headerPaintExtent =
        calculatePaintOffset(constraints, from: 0.0, to: headerExtent);
    final double headerCacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: headerExtent);

    final axisDirection = applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection);

    if (child == null) {
      geometry = SliverGeometry(
        scrollExtent: headerExtent,
        maxPaintExtent: headerExtent,
        paintExtent: headerPaintExtent,
        cacheExtent: headerCacheExtent,
        hitTestExtent: headerPaintExtent,
        hasVisualOverflow: headerExtent > constraints.remainingPaintExtent ||
            constraints.scrollOffset > 0.0,
      );
    } else {
      child.layout(
        constraints.copyWith(
          scrollOffset: math.max(0.0, constraints.scrollOffset - headerExtent),
          cacheOrigin: math.min(0.0, constraints.cacheOrigin + headerExtent),
          overlap: math.min(headerExtent, constraints.scrollOffset) +
              constraints.overlap,
          remainingPaintExtent:
              constraints.remainingPaintExtent - headerPaintExtent,
          remainingCacheExtent:
              constraints.remainingCacheExtent - headerCacheExtent,
        ),
        parentUsesSize: true,
      );
      final SliverGeometry childLayoutGeometry = child.geometry!;
      if (childLayoutGeometry.scrollOffsetCorrection != null) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
        );
        return;
      }

      final double paintExtent = math.min(
        headerPaintExtent +
            math.max(childLayoutGeometry.paintExtent,
                childLayoutGeometry.layoutExtent),
        constraints.remainingPaintExtent,
      );

      geometry = SliverGeometry(
        scrollExtent: headerExtent + childLayoutGeometry.scrollExtent,
        paintExtent: paintExtent,
        layoutExtent: math.min(
            headerPaintExtent + childLayoutGeometry.layoutExtent, paintExtent),
        cacheExtent: math.min(
            headerCacheExtent + childLayoutGeometry.cacheExtent,
            constraints.remainingCacheExtent),
        maxPaintExtent: headerExtent + childLayoutGeometry.maxPaintExtent,
        hitTestExtent: math.max(
            headerPaintExtent + childLayoutGeometry.paintExtent,
            headerPaintExtent + childLayoutGeometry.hitTestExtent),
        hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
      ).withChildObstructionExtent(
        ChildObstructionExtent(leading: headerExtent, trailing: 0),
      );

      final SliverPhysicalParentData? childParentData =
          child.parentData as SliverPhysicalParentData?;
      switch (axisDirection) {
        case AxisDirection.up:
          childParentData!.paintOffset = Offset.zero;
        case AxisDirection.right:
          childParentData!.paintOffset = Offset(
              calculatePaintOffset(constraints, from: 0.0, to: headerExtent),
              0.0);
        case AxisDirection.down:
          childParentData!.paintOffset = Offset(0.0,
              calculatePaintOffset(constraints, from: 0.0, to: headerExtent));
        case AxisDirection.left:
          childParentData!.paintOffset = Offset.zero;
      }
    }

    if (header != null) {
      final SliverPhysicalParentData? headerParentData =
          header.parentData as SliverPhysicalParentData?;

      final headerPosition = _headerPosition;

      switch (axisDirection) {
        case AxisDirection.up:
          headerParentData!.paintOffset = Offset(
              0.0, geometry!.paintExtent - headerPosition - _headerExtent);
        case AxisDirection.down:
          headerParentData!.paintOffset = Offset(0.0, headerPosition);
        case AxisDirection.left:
          headerParentData!.paintOffset = Offset(
              geometry!.paintExtent - headerPosition - _headerExtent, 0.0);
        case AxisDirection.right:
          headerParentData!.paintOffset = Offset(headerPosition, 0.0);
      }
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    assert(geometry!.hitTestExtent > 0.0);
    final header = this.header;
    final child = this.child;

    final headerPosition = _headerPosition;

    if (header != null &&
        (mainAxisPosition - headerPosition) <= _headerExtent) {
      final didHitHeader = hitTestBoxChild(
        BoxHitTestResult.wrap(SliverHitTestResult.wrap(result)),
        header,
        mainAxisPosition:
            mainAxisPosition - childMainAxisPosition(header) - headerPosition,
        crossAxisPosition: crossAxisPosition,
      );

      if (didHitHeader) {
        return didHitHeader;
      }
    }
    if (child != null && child.geometry!.hitTestExtent > 0.0) {
      return child.hitTest(result,
          mainAxisPosition: mainAxisPosition - childMainAxisPosition(child),
          crossAxisPosition: crossAxisPosition);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderObject? child) {
    if (child == header) {
      return 0.0;
    }
    if (child == this.child) {
      return calculatePaintOffset(constraints, from: 0.0, to: _headerExtent);
    }
    return 0;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    if (child == this.child) {
      return _headerExtent;
    } else {
      return super.childScrollOffset(child);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final SliverPhysicalParentData childParentData =
        child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final header = this.header;
    if (geometry!.visible) {
      if (child != null && child.geometry!.visible) {
        final SliverPhysicalParentData childParentData =
            child.parentData! as SliverPhysicalParentData;
        context.paintChild(child, offset + childParentData.paintOffset);
      }

      // The header must be drawn over the sliver.
      if (header != null) {
        final SliverPhysicalParentData headerParentData =
            header.parentData! as SliverPhysicalParentData;
        context.paintChild(header, offset + headerParentData.paintOffset);
      }
    }
  }
}
