import "dart:async";

import "package:flutter/material.dart" show Colors;
import "package:headless_widgets/headless_widgets.dart" as w;
import "package:pixel_snap/widgets.dart";
import "package:url_launcher/url_launcher.dart";

import "focus_indicator.dart";

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.child,
    this.tapToFocus = false,
    this.onPressed,
    this.onPressedDown,
    this.keyUpTimeout,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final FutureOr<void> Function()? onPressedDown;
  final bool tapToFocus;
  final Duration? keyUpTimeout;
  final EdgeInsetsGeometry padding;

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
        padding: padding,
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
    const radius = Radius.circular(6.0);
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
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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

class FlatButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;

  const FlatButton({
    super.key,
    this.onPressed,
    this.selected = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return w.Button(
      selected: selected ? w.SelectionState.on : w.SelectionState.off,
      hitTestBehavior: HitTestBehavior.opaque,
      onPressed: onPressed,
      builder: buildFlatButton,
      child: child,
    );
  }
}

Widget buildFlatButton(
    BuildContext context, w.ButtonState state, Widget? child) {
  const tint = Colors.black;
  final background =
      switch ((state.selected, state.focused, state.hovered, state.pressed)) {
    (w.SelectionState.on, _, _, _) => tint.withOpacity(0.4),
    (_, _, _, true) => tint.withOpacity(0.3),
    (_, _, true, _) => tint.withOpacity(0.15),
    (_, _, _, _) => Colors.transparent,
  };
  return Container(
    decoration: BoxDecoration(
      color: background,
    ),
    padding: const EdgeInsets.all(4),
    child: child,
  );
}

class LinkButton extends StatelessWidget {
  final Uri uri;

  const LinkButton({
    super.key,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return w.Button(
      onPressed: () => launchUrl(uri),
      builder: (context, state, child) {
        final textDecoration = state.hovered || state.pressed
            ? TextDecoration.underline
            : TextDecoration.none;
        return DefaultTextStyle.merge(
          style: TextStyle(
            color: Colors.blue,
            decoration: textDecoration,
          ),
          child: child!,
        );
      },
      child: Text(uri.toString()),
    );
  }
}
