import 'package:flutter/material.dart';
import 'package:headless_widgets/headless_widgets.dart';

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
    return Button(
      hitTestBehavior: HitTestBehavior.opaque,
      onPressed: onPressed,
      builder: buildFlatButton,
      child: child,
    );
  }
}

Widget buildFlatButton(BuildContext context, ButtonState state, Widget? child) {
  const tint = Colors.black;
  final background =
      switch ((state.selected, state.focused, state.hovered, state.pressed)) {
    (SelectionState.on, _, _, _) => tint.withOpacity(0.4),
    (_, _, _, true) => tint.withOpacity(0.3),
    (_, _, true, _) => tint.withOpacity(0.15),
    (_, _, _, _) => Colors.transparent,
  };
  return Container(
    decoration: BoxDecoration(
      color: background,
    ),
    padding: const EdgeInsets.all(4),
    child: child!,
  );
}
