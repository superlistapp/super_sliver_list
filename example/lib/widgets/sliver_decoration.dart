import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";

const _colors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.cyan,
  Colors.lime,
  Colors.amber,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

class SliverDecoration extends StatelessWidget {
  final Widget sliver;
  final int index;

  const SliverDecoration({
    required this.sliver,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _colors[index % _colors.length].withOpacity(0.1),
            width: 8,
          ),
        ),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: sliver,
      ),
    );
  }
}
