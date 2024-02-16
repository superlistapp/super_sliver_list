import "package:flutter/material.dart" show Colors;
import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class LayoutInfoOverlay extends StatefulWidget {
  final List<ExtentController> extentControllers;
  final Widget child;

  const LayoutInfoOverlay({
    super.key,
    required this.extentControllers,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _LayoutInfoOverlayState();
}

extension on ExtentController {
  double get fractionComplete =>
      (numberOfItems - estimatedExtentsCount) / numberOfItems;
}

class _LayoutInfoOverlayState extends State<LayoutInfoOverlay> {
  @override
  void initState() {
    super.initState();
    for (final controller in widget.extentControllers) {
      controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final controller in widget.extentControllers) {
      controller.removeListener(_update);
    }
  }

  @override
  void didUpdateWidget(covariant LayoutInfoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final controller in oldWidget.extentControllers) {
      controller.removeListener(_update);
    }
    for (final controller in widget.extentControllers) {
      controller.addListener(_update);
    }
  }

  double _currentProgress = 0;

  var _updateScheduled = false;

  void _update() {
    if (!_updateScheduled) {
      _updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        final progress = widget.extentControllers
                .map((e) => e.isAttached ? e.fractionComplete : 0)
                .reduce((a, b) => a + b) /
            widget.extentControllers.length;
        if (progress != _currentProgress) {
          setState(() {
            _currentProgress = progress;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_currentProgress > 0)
            Positioned(
              bottom: 0,
              left: 0,
              width: constraints.maxWidth * _currentProgress,
              height: _currentProgress > 0.01 && _currentProgress < 1 ? 2 : 0,
              child: Container(
                color: Colors.blue,
              ),
            ),
        ],
      );
    });
  }
}
