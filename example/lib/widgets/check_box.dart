import "package:flutter/material.dart" show Colors, Icons;
import "package:headless_widgets/headless_widgets.dart";
import "package:pixel_snap/widgets.dart";

import "focus_indicator.dart";

class CheckBox extends StatelessWidget {
  final bool checked;
  final Widget child;
  final ValueChanged<bool>? onChanged;

  const CheckBox({
    super.key,
    required this.checked,
    required this.child,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      hitTestBehavior: HitTestBehavior.opaque,
      onPressed: () => onChanged?.call(!checked),
      selected: checked ? SelectionState.on : SelectionState.off,
      builder: _buildCheckBox,
      child: child,
    );
  }

  Widget _buildCheckBox(
    BuildContext context,
    ButtonState state,
    Widget? child,
  ) {
    final borderColor = switch (state) {
      ButtonState(selected: SelectionState.on) => Colors.blue.shade400,
      ButtonState(enabled: false) => Colors.blue.shade200,
      ButtonState(pressed: true) => Colors.blue.shade400,
      _ => Colors.blue.shade300,
    };
    final backgroundColor = switch (state) {
      ButtonState(selected: SelectionState.on, pressed: true) =>
        Colors.blue.shade500,
      ButtonState(selected: SelectionState.on) => Colors.blue.shade400,
      ButtonState(hovered: true) => Colors.blue.shade50,
      ButtonState(pressed: true) => Colors.blue.shade100,
      _ => Colors.white,
    };
    final iconColor = switch (state) {
      ButtonState(enabled: false) => Colors.grey.shade400,
      ButtonState(selected: SelectionState.on) => Colors.white,
      _ => Colors.black,
    };
    final shadowOpacity = switch (state) {
      ButtonState(enabled: false) => 0.15,
      ButtonState(focused: true) => 0.0,
      ButtonState(pressed: true) => 0.15,
      _ => 0.2,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FocusIndicator(
          readius: 6,
          focused: state.focused,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
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
            child: Center(
              child: checked
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: iconColor,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              height: 1.17,
            ),
            child: child!,
          ),
        ),
      ],
    );
  }
}
