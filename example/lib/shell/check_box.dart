import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/widgets.dart';
import 'package:headless_widgets/headless_widgets.dart';

class CheckboxTheme {
  final Color? color;
  final Color? checkColor;
  final double? size;

  const CheckboxTheme({
    this.color,
    this.checkColor,
    this.size,
  });
}

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
      tapToFocus: true,
      onPressed: () => onChanged?.call(!checked),
      builder: _buildCheckBox,
      child: child,
    );
  }

  Widget _buildCheckBox(
    BuildContext context,
    ButtonState state,
    Widget? child,
  ) {
    return ColoredBox(
      color: state.focused ? Colors.yellow : Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: const Color(0xFFCCCCCC),
                width: 1,
              ),
              color:
                  checked ? const Color(0xFFCCCCCC) : const Color(0xFFEEEEEE),
            ),
            child: Center(
              child: checked
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                height: 1.17,
                // color: textColor,
              ),
              child: child!,
            ),
          ),
        ],
      ),
    );
  }
}
