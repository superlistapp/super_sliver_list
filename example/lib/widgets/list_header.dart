import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";
import "package:sliver_tools/sliver_tools.dart";

class ListHeader extends StatelessWidget {
  const ListHeader({
    super.key,
    required this.title,
    required this.primary,
  });

  final Widget title;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: Container(
        color: primary
            ? const Color(0xFFF84F39).withOpacity(0.9)
            : Colors.blueGrey.shade300.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: title,
        ),
      ),
    );
  }
}
