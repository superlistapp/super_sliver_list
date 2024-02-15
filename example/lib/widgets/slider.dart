import "package:flutter/material.dart" show Colors;
import "package:headless_widgets/headless_widgets.dart" hide Slider;
import "package:headless_widgets/headless_widgets.dart" as w show Slider;
import "package:pixel_snap/widgets.dart";

class _TrackClipper extends CustomClipper<Rect> {
  final double value;
  final bool inverse;

  _TrackClipper({
    super.reclip,
    required this.value,
    required this.inverse,
  });

  @override
  Rect getClip(Size size) {
    if (inverse) {
      return Rect.fromLTWH(size.width * value, 0, size.width, size.height);
    } else {
      return Rect.fromLTWH(0, 0, size.width * value, size.height);
    }
  }

  @override
  bool shouldReclip(covariant _TrackClipper oldClipper) {
    return oldClipper.value != value;
  }
}

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
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
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
              color: Colors.blueGrey.shade300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
      trackBuilder: (context, state) {
        return Center(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              ClipRect(
                clipper: _TrackClipper(
                  value: state.effectiveFraction,
                  inverse: false,
                ),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.blueGrey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              ),
              ClipRect(
                clipper: _TrackClipper(
                  value: state.effectiveFraction,
                  inverse: true,
                ),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    // color: Colors.blueGrey.shade50.withOpacity(0.5),
                    border: Border.all(
                      color: Colors.blueGrey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
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
      trackPosition: Offset.zero,
      thumbPosition: Offset(
        ps(
          (constraints.maxWidth - thumbSize.width) * (state.effectiveFraction),
        ),
        0,
      ),
    );
  }
}
