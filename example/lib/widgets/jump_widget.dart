import "dart:math" as math;

import "package:flutter/material.dart" show Icons;
import "package:pixel_snap/widgets.dart";

import "../shell/sidebar.dart";
import "button.dart";
import "labeled_slider.dart";
import "slider.dart";

class JumpWidget extends StatefulWidget {
  const JumpWidget({
    super.key,
    required this.numSlivers,
    required this.numItemsPerSliver,
    required this.onJumpRequested,
    required this.onAnimateRequested,
  });

  final int numSlivers;
  final int numItemsPerSliver;
  final void Function(int sliver, int item, double alignment) onJumpRequested;
  final void Function(int sliver, int item, double alignment)
      onAnimateRequested;

  @override
  State<StatefulWidget> createState() => _JumpWidgetState();
}

class _JumpWidgetState extends State<JumpWidget> {
  int sliver = 0;
  int item = 0;
  double alignment = 0;

  @override
  void didUpdateWidget(covariant JumpWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (sliver >= widget.numSlivers) {
      sliver = widget.numSlivers - 1;
    }
    if (item >= widget.numItemsPerSliver) {
      item = widget.numItemsPerSliver - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarSection(
      title: const Text("Jump to Item"),
      children: [
        LabeledSlider(
          label: const Text("Sliver Index"),
          value: Text("$sliver"),
          slider: Slider(
            min: 0,
            max: widget.numSlivers - 1,
            value: sliver.toDouble(),
            onKeyboardAction: (action) {
              final sliver = (this.sliver + action.signInt)
                  .clamp(0, widget.numSlivers - 1);
              if (sliver != this.sliver) {
                setState(() {
                  this.sliver = sliver;
                });
              }
            },
            onChanged: (value) {
              final sliver = value.round();
              if (sliver != this.sliver) {
                setState(() {
                  this.sliver = sliver;
                });
              }
            },
          ),
        ),
        LabeledSlider(
          label: const Text("Item Index"),
          value: Text("$item"),
          slider: Slider(
            min: 0,
            max: widget.numItemsPerSliver - 1,
            value: item.toDouble(),
            onKeyboardAction: (action) {
              final item = (this.item + action.signInt)
                  .clamp(0, widget.numItemsPerSliver - 1);
              if (item != this.item) {
                setState(() {
                  this.item = item;
                });
              }
            },
            onChanged: (value) {
              final item = value.round();
              if (item != this.item) {
                setState(() {
                  this.item = item;
                });
              }
            },
          ),
        ),
        LabeledSlider(
          label: const Text("Alignment in Viewport"),
          value: Text(alignment.toStringAsPrecision(2)),
          slider: Slider(
            min: 0,
            max: 1,
            value: alignment,
            onKeyboardAction: (action) {
              final alignment =
                  (this.alignment + action.sign * 0.1).clamp(0.0, 1.0);
              if (alignment != this.alignment) {
                setState(() {
                  this.alignment = alignment;
                });
              }
            },
            onChanged: (value) {
              value = (value * 100.0).round() / 100.0;
              if (value != alignment) {
                setState(() {
                  alignment = value;
                });
              }
            },
          ),
        ),
        Row(
          children: [
            Button(
              onPressed: () {
                widget.onJumpRequested(sliver, item, alignment);
              },
              child: const Text("Jump"),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () {
                widget.onAnimateRequested(sliver, item, alignment);
              },
              child: const Text("Animate"),
            ),
            const SizedBox(width: 8),
            const Spacer(),
            Button(
              padding: const EdgeInsets.all(4),
              onPressed: () {
                final random = math.Random();
                setState(() {
                  sliver = random.nextInt(widget.numSlivers);
                  item = random.nextInt(widget.numItemsPerSliver);
                });
              },
              child: const Icon(
                Icons.shuffle_rounded,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
