import "package:flutter/material.dart";
import "package:headless_widgets/headless_widgets.dart";

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
      selected: selected ? SelectionState.on : SelectionState.off,
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          FlatButton(
            onPressed: () => onSelected?.call(i),
            selected: i == selectedIndex,
            child: children[i],
          ),
      ],
    );
  }
}
