import "dart:math" as math;

import "package:context_watch/context_watch.dart";
import "package:example/shell/buttons.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter/material.dart" show Colors;
import "package:flutter_lorem/flutter_lorem.dart";
import "package:provider/provider.dart";
import "package:super_sliver_list/super_sliver_list.dart";

import "../shell/slider.dart";
import "../util/show_on_screen.dart";
import "../shell/app_settings.dart";
import "../shell/example_page.dart";
import "layout_info_overlay.dart";

const _kMaxSlivers = 10;
const _kItemsPerSliver = [1, 9, 27, 80, 200, 1000, 2500, 7000];

class SuperReadingOrderTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    invalidateScopeData(currentNode.nearestScope!);
    return super.inDirection(currentNode, direction);
  }
}

class _ItemListSettings {
  final sliverCount = ValueNotifier(1);
  final itemsPerSliver = ValueNotifier(_kItemsPerSliver.last);
}

class Item extends StatefulWidget {
  final String text;
  final int sliver;
  final int index;

  const Item({
    super.key,
    required this.text,
    required this.sliver,
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => _ItemState();
}

class _ItemState extends State<Item> with AutomaticKeepAliveClientMixin {
  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey != LogicalKeyboardKey.pageUp &&
              event.logicalKey != LogicalKeyboardKey.pageDown &&
              event.logicalKey != LogicalKeyboardKey.home &&
              event.logicalKey != LogicalKeyboardKey.end) {
            final renderObject = context.findRenderObject();
            renderObject!.safeShowOnScreen(context);
          }
        }
        return KeyEventResult.ignored;
      },
    );
    _focusNode.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTapDown: (_) {
        _focusNode.requestFocus();
      },
      child: Focus.withExternalFocusNode(
        focusNode: _focusNode,
        child: Container(
          color: _focusNode.hasFocus ? Colors.blue : Colors.transparent,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Sliver ${widget.sliver}, Paragraph ${widget.index}",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(widget.text),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => _focusNode.hasFocus;
}

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<StatefulWidget> createState() => _ItemListPageState();
}

class _Item {
  _Item({
    required this.index,
  });

  final int index;

  String get text {
    // final random = math.Random(index).nextInt(100);
    final length = (Object.hash(index, null) % 20 * 10) + 2;
    return _text ??= lorem(paragraphs: 1, words: length);
  }

  String? _text;
}

class _SliverData {
  final String title;
  final items = <_Item>[];

  _SliverData({
    required this.title,
  });

  void ensureItemCount(int count) {
    while (items.length > count) {
      items.removeLast();
    }
    while (items.length < count) {
      items.add(_Item(index: items.length));
    }
  }
}

class _ItemListPageState extends ExamplePageState {
  final _sliverData = <_SliverData>[];

  final List<ExtentController> _extentControllers = [];
  late ScrollController _scrollController;

  void _updateSliverData(int sliverCount, int itemsPerSliver) {
    while (_sliverData.length > sliverCount) {
      _sliverData.removeLast();
    }
    while (_sliverData.length < sliverCount) {
      _sliverData.add(_SliverData(title: "Sliver ${_sliverData.length}"));
    }
    for (final sliver in _sliverData) {
      sliver.ensureItemCount(itemsPerSliver);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    for (final controller in _extentControllers) {
      controller.dispose();
    }
  }

  void _ensureExtentContollers(int count) {
    while (_extentControllers.length > count) {
      _extentControllers.last.dispose();
      _extentControllers.removeLast();
    }
    while (_extentControllers.length < count) {
      _extentControllers.add(ExtentController());
    }
  }

  final _settings = _ItemListSettings();

  @override
  Widget build(BuildContext context) {
    final sliverCount = _settings.sliverCount.watch(context);
    final itemsPerSliver = _settings.itemsPerSliver.watch(context);
    _updateSliverData(sliverCount, itemsPerSliver);

    final options = context.watch<AppSettings>();
    final showSliverList = options.showSliverList.watch(context);
    // final preciseLayout = options.preciseLayout.watch(context);
    bool preciseLayout = false;

    SliverChildBuilderDelegate delegate(int sliverIndex) {
      final sliver = _sliverData[sliverIndex];
      return SliverChildBuilderDelegate((context, index) {
        final item = sliver.items[index];
        return Item(
          text: item.text,
          sliver: sliverIndex,
          index: index,
        );
      }, childCount: sliver.items.length);
    }

    _ensureExtentContollers(_sliverData.length);

    return Row(
      children: [
        Expanded(
          child: FocusTraversalGroup(
            policy: SuperReadingOrderTraversalPolicy(),
            child: LayoutInfoOverlay(
              extentControllers: _extentControllers,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  for (int i = 0; i < _sliverData.length; ++i)
                    SliverPadding(
                      padding: const EdgeInsets.all(10),
                      sliver: SuperSliverList(
                        extentController: _extentControllers[i],
                        extentPrecalculationPolicy:
                            options.extentPrecalculationPolicy,
                        delegate: delegate(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showSliverList)
          Expanded(
            child: FocusTraversalGroup(
              policy: SuperReadingOrderTraversalPolicy(),
              child: CustomScrollView(
                slivers: [
                  for (int i = 0; i < _sliverData.length; ++i)
                    SliverPadding(
                      padding: const EdgeInsets.all(10),
                      sliver: SliverList(
                        delegate: delegate(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget? createSidebarWidget() {
    return _SidebarWidget(
      settings: _settings,
      onJumpRequested: (sliver, item, alignment) {
        final offset = _extentControllers[sliver].getOffsetToReveal(
          item,
          alignment,
        );
        _scrollController.jumpTo(
          offset,
        );
      },
    );
  }
}

class _JumpWidget extends StatefulWidget {
  const _JumpWidget({
    super.key,
    required this.numSlivers,
    required this.numItemsPerSliver,
    required this.onJumpRequested,
  });

  final int numSlivers;
  final int numItemsPerSliver;
  final void Function(int sliver, int item, double alignment) onJumpRequested;

  @override
  State<StatefulWidget> createState() => _JumpWidgetState();
}

class _JumpWidgetState extends State<_JumpWidget> {
  int sliver = 0;
  int item = 0;
  double alignment = 0;

  @override
  void didUpdateWidget(covariant _JumpWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (sliver >= widget.numSlivers) {
      sliver = widget.numSlivers - 1;
    }
    if (item >= widget.numItemsPerSliver) {
      item = widget.numItemsPerSliver - 1;
    }
  }

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text("Sliver"),
            const Spacer(),
            Text("Sliver: $sliver"),
          ],
        ),
        Slider(
          min: 0,
          max: widget.numSlivers - 1,
          value: sliver.toDouble(),
          onChanged: (value) {
            final sliver = value.round();
            if (sliver != this.sliver) {
              setState(() {
                this.sliver = sliver;
              });
            }
          },
        ),
        Row(
          children: [
            const Text("Item"),
            const Spacer(),
            Text("$item"),
          ],
        ),
        Slider(
          min: 0,
          max: widget.numItemsPerSliver - 1,
          value: item.toDouble(),
          onChanged: (value) {
            final item = value.round();
            if (item != this.item) {
              setState(() {
                this.item = item;
              });
            }
          },
        ),
        Row(
          children: [
            const Text("Alignment"),
            const Spacer(),
            Text(alignment.toStringAsPrecision(2)),
          ],
        ),
        Slider(
          min: 0,
          max: 1,
          value: alignment,
          onChanged: (value) {
            if (value != alignment) {
              setState(() {
                alignment = value;
              });
            }
          },
        ),
        Row(
          children: [
            FlatButton(
              onPressed: () {
                widget.onJumpRequested(sliver, item, alignment);
              },
              child: const Text("Jump"),
            ),
            FlatButton(
              onPressed: () {
                final random = math.Random();
                setState(() {
                  sliver = random.nextInt(widget.numSlivers);
                  item = random.nextInt(widget.numItemsPerSliver);
                });
                print("RANDOM JUMP");
                widget.onJumpRequested(sliver, item, alignment);
              },
              child: const Text("Random jump"),
            ),
          ],
        ),
      ],
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  final void Function(int sliver, int item, double alignment) onJumpRequested;
  final _ItemListSettings settings;

  const _SidebarWidget({
    super.key,
    required this.onJumpRequested,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final sliverCount = settings.sliverCount.watch(context);
    final itemPerSliver = settings.itemsPerSliver.watch(context);

    return Column(
      children: [
        _NumberPicker(
          title: const Text("Slivers"),
          options: List.generate(_kMaxSlivers - 1, (index) => index + 1),
          value: sliverCount,
          onChanged: (value) {
            settings.sliverCount.value = value;
          },
        ),
        SizedBox(
          height: 8,
        ),
        _NumberPicker(
          title: const Text("Items per Sliver"),
          options: _kItemsPerSliver,
          value: itemPerSliver,
          onChanged: (value) {
            settings.itemsPerSliver.value = value;
          },
        ),
        _JumpWidget(
          numSlivers: sliverCount,
          numItemsPerSliver: itemPerSliver,
          onJumpRequested: onJumpRequested,
        ),
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final Widget title;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            title,
            const Spacer(),
            Text(value.toString()),
          ],
        ),
        Slider(
          min: 0,
          max: options.length - 1,
          value: _getIndexForNearestValue().toDouble(),
          onChanged: (value) {
            int v = options[value.round()];
            onChanged(v);
          },
        ),
      ],
    );
  }
}
