import "package:flutter/material.dart";

class SliverListDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade200,
        child: Text(
            "Warning: Scrolling large SliverList using the scroll bar can make the UI unresponsive.",
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}
