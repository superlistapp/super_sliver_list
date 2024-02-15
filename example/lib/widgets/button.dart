import "dart:async";

import "package:flutter/material.dart" show Colors;
import "package:headless_widgets/headless_widgets.dart" as w;
import "package:pixel_snap/widgets.dart";

import "focus_indicator.dart";

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.child,
    this.tapToFocus = false,
    this.onPressed,
    this.onPressedDown,
    this.keyUpTimeout,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final FutureOr<void> Function()? onPressedDown;
  final bool tapToFocus;
  final Duration? keyUpTimeout;

  Widget _builder(
    BuildContext context,
    w.ButtonState state,
    Widget? child,
  ) {
    final borderColor = switch (state) {
      w.ButtonState(enabled: false) => Colors.blue.shade200,
      w.ButtonState(pressed: true) => Colors.blue.shade400,
      _ => Colors.blue.shade300,
    };
    final backgroundColor = switch (state) {
      w.ButtonState(pressed: true) => Colors.blue.shade400,
      w.ButtonState(hovered: true) ||
      w.ButtonState(tracked: true) =>
        Colors.blue.shade50,
      _ => Colors.white,
    };
    final textColor = switch (state) {
      w.ButtonState(enabled: false) => Colors.grey.shade400,
      w.ButtonState(pressed: true) => Colors.white,
      _ => Colors.black,
    };
    final shadowOpacity = switch (state) {
      w.ButtonState(enabled: false) => 0.2,
      w.ButtonState(focused: true) => 0.0,
      w.ButtonState(pressed: true) => 0.15,
      _ => 0.2,
    };
    return FocusIndicator(
      focused: state.focused,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: borderColor, width: 1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          boxShadow: [
            BoxShadow(
              blurStyle: BlurStyle.outer,
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: 3,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(backgroundColor, Colors.white, 0.2)!,
              backgroundColor,
            ],
          ),
        ),
        child: Container(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              height: 1.17,
              color: textColor,
            ),
            child: child!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return w.Button(
      tapToFocus: tapToFocus,
      onPressed: onPressed,
      onPressedDown: onPressedDown,
      keyUpTimeout: keyUpTimeout,
      builder: _builder,
      child: child,
    );
  }
}

class SegmentedButton extends StatelessWidget {
  final List<Widget> children;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const SegmentedButton({
    super.key,
    required this.children,
    required this.selectedIndex,
    this.onSelected,
  });

  Widget _builder(
    BuildContext context,
    w.ButtonState state,
    Widget? child,
    int index,
  ) {
    final borderColor = switch (state) {
      w.ButtonState(enabled: false) => Colors.blue.shade200,
      w.ButtonState(pressed: true) => Colors.blue.shade400,
      _ => Colors.blue.shade300,
    };
    final backgroundColor = switch (state) {
      w.ButtonState(selected: w.SelectionState.on) => Colors.blue.shade300,
      w.ButtonState(pressed: true) => Colors.blue.shade400,
      w.ButtonState(hovered: true) ||
      w.ButtonState(tracked: true) =>
        Colors.blue.shade50,
      _ => Colors.white,
    };
    final textColor = switch (state) {
      w.ButtonState(selected: w.SelectionState.on) => Colors.white,
      w.ButtonState(enabled: false) => Colors.grey.shade400,
      w.ButtonState(pressed: true) => Colors.white,
      _ => Colors.black,
    };
    final first = index == 0;
    final last = index == children.length - 1;
    final radius = Radius.circular(6.0);
    final borderSide = BorderSide(color: borderColor, width: 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          left: first ? borderSide : BorderSide.none,
          right: last ? borderSide : BorderSide.none,
          top: borderSide,
          bottom: borderSide,
        ),
        borderRadius: BorderRadius.only(
          topLeft: first ? radius : Radius.zero,
          bottomLeft: first ? radius : Radius.zero,
          topRight: last ? radius : Radius.zero,
          bottomRight: last ? radius : Radius.zero,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(backgroundColor, Colors.white, 0.2)!,
            backgroundColor,
          ],
        ),
      ),
      child: FocusIndicator(
        focused: state.focused,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              height: 1.17,
              color: textColor,
            ),
            child: child!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: [
          BoxShadow(
            blurStyle: BlurStyle.outer,
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
          ),
        ],
      ),
      child: FocusTraversalGroup(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++)
              w.Button(
                builder: (context, state, child) =>
                    _builder(context, state, child, i),
                onPressed: () => onSelected?.call(i),
                selected: i == selectedIndex
                    ? w.SelectionState.on
                    : w.SelectionState.off,
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}
