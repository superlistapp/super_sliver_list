import 'package:flutter/material.dart' show Colors;
import 'package:headless_widgets/headless_widgets.dart' hide Slider;
import 'package:headless_widgets/headless_widgets.dart' as w show Slider;
import 'package:pixel_snap/widgets.dart';

class Slider extends StatelessWidget {
  const Slider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.onKeyboardAction,
  });

  final double min;
  final double max;
  final double value;
  final ValueChanged<double>? onChanged;
  final void Function(SliderKeyboardAction action)? onKeyboardAction;

  @override
  Widget build(BuildContext context) {
    return w.Slider(
      min: min,
      max: max,
      value: value,
      onChanged: onChanged,
      onKeyboardAction: onKeyboardAction,
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeOutCubic,
      trackConstraints: (state, constraints, thumbSize) {
        if (constraints.maxWidth.isInfinite) {
          // When getting intrinsic size.
          return BoxConstraints.tight(Size.zero);
        }
        return BoxConstraints(
          minWidth: constraints.maxWidth - thumbSize.width,
          maxWidth: constraints.maxWidth - thumbSize.width,
          minHeight: thumbSize.height,
          maxHeight: thumbSize.height,
        );
      },
      geometry: (state, constraints, trackSize, thumbSize) => _geometry(
        state,
        constraints,
        trackSize,
        thumbSize,
        PixelSnap.of(context),
      ),
      thumbBuilder: (context, state) {
        final backgroundColor = switch (state) {
          SliderState(tracked: true) => Colors.blue.shade400,
          SliderState(hovered: true) => Colors.blue.shade50,
          _ => Colors.white,
        };
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: Colors.blueGrey,
              width: 1,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      trackBuilder: (context, state) {
        return Center(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }

  static SliderGeometry _geometry(
    SliderState state,
    BoxConstraints constraints,
    Size thumbSize,
    Size trackSize,
    PixelSnap ps,
  ) {
    return SliderGeometry(
      sliderSize: Size(constraints.maxWidth, thumbSize.height),
      trackPosition: Offset(thumbSize.width / 2.0, 0),
      thumbPosition: Offset(
        ps(
          (constraints.maxWidth - thumbSize.width) * (state.effectiveFraction),
        ),
        0,
      ),
    );
  }
}
