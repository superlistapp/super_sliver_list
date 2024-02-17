import "package:pixel_snap/widgets.dart";

import "labeled_slider.dart";
import "slider.dart";

class NumberPicker extends StatelessWidget {
  final Widget title;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  int _getIndexForNearestValue() {
    int index = 0;
    int minDiff = (options.first - value).abs();
    for (int i = 1; i < options.length; ++i) {
      final diff = (options[i] - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        index = i;
      }
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return LabeledSlider(
      label: title,
      value: Text(value.toString()),
      slider: Slider(
        min: 0,
        max: options.length - 1,
        value: _getIndexForNearestValue().toDouble(),
        onChanged: (value) {
          final int v = options[value.round()];
          onChanged(v);
        },
        onKeyboardAction: (action) {
          final currentIndex = _getIndexForNearestValue();
          final newIndex =
              (currentIndex + action.signInt).clamp(0, options.length - 1);
          if (currentIndex != newIndex) {
            onChanged(options[newIndex]);
          }
        },
      ),
    );
  }
}
