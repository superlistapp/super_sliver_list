import "package:flutter/material.dart" show Colors;
import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class LayoutInfoOverlay extends StatefulWidget {
  final List<ListController> listControllers;
  final Widget child;

  const LayoutInfoOverlay({
    super.key,
    required this.listControllers,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _LayoutInfoOverlayState();
}

extension on ListController {
  double get fractionComplete =>
      (numberOfItems - numberOfItemsWithEstimatedExtent) / numberOfItems;
}

class _LayoutInfoOverlayState extends State<LayoutInfoOverlay> {
  @override
  void initState() {
    super.initState();
    for (final controller in widget.listControllers) {
      controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final controller in widget.listControllers) {
      controller.removeListener(_update);
    }
  }

  @override
  void didUpdateWidget(covariant LayoutInfoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final controller in oldWidget.listControllers) {
      controller.removeListener(_update);
    }
    for (final controller in widget.listControllers) {
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
        final progress = widget.listControllers
                .map((e) => e.isAttached ? e.fractionComplete : 0)
                .reduce((a, b) => a + b) /
            widget.listControllers.length;
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
