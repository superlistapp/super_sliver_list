import "package:pixel_snap/widgets.dart";

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.slider,
  });

  final Widget label;
  final Widget value;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DefaultTextStyle.merge(
              child: label,
              style: const TextStyle(fontSize: 12),
            ),
            const Spacer(),
            DefaultTextStyle.merge(
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              child: value,
            ),
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        slider,
      ],
    );
  }
}
