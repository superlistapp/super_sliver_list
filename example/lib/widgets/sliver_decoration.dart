import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";

import "sticky_header/sliver_sticky_header.dart";

const _colors = [
  Colors.blue,
  Colors.purple,
  Colors.green,
  Colors.red,
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
  final bool stickyHeader;

  const SliverDecoration({
    required this.sliver,
    required this.index,
    this.stickyHeader = false,
  });

  Color get _color => _colors[index % _colors.length];

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      header: stickyHeader
          ? Container(
              color: _color.withOpacity(0.9),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              alignment: Alignment.centerLeft,
              child: Text(
                "Sliver $index",
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _color.withOpacity(0.1),
              width: 8,
            ),
          ),
        ),
        sliver: SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: sliver,
        ),
      ),
    );
  }
}
