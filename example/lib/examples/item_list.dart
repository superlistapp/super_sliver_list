import 'package:context_watch/context_watch.dart';
import 'package:example/shell/buttons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_lorem/flutter_lorem.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../shell/slider.dart';
import '../util/show_on_screen.dart';
import '../shell/app_settings.dart';
import '../shell/example_page.dart';
import 'layout_info_overlay.dart';

class SuperReadingOrderTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    invalidateScopeData(currentNode.nearestScope!);
    return super.inDirection(currentNode, direction);
  }
}

class _ItemListSettings {
  final sliverCount = ValueNotifier(2);
  final itemsPerSliver = ValueNotifier(5);
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
                'Sliver ${widget.sliver}, Paragraph ${widget.index}',
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
  const ItemListPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ItemListPageState();
}

class _Section {
  final String title;
  final items = <String>[];

  _Section({
    required this.title,
  });

  void ensureItemCount(int count) {
    while (items.length > count) {
      items.removeLast();
    }
    while (items.length < count) {
      final index = items.length;
      items.add(
          lorem(paragraphs: 1, words: 15 + index.toString().hashCode % 40));
    }
  }
}

class _ItemListPageState extends ExamplePageState {
  final _sections = <_Section>[];

  final List<ExtentController> _extentControllers = [];
  late ScrollController _scrollController;

  void _updateSections(int sliverCount, int itemsPerSliver) {
    while (_sections.length > sliverCount) {
      _sections.removeLast();
    }
    while (_sections.length < sliverCount) {
      _sections.add(_Section(title: 'Section ${_sections.length}'));
    }
    for (final section in _sections) {
      section.ensureItemCount(itemsPerSliver);
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
    _updateSections(sliverCount, itemsPerSliver);

    final options = context.watch<AppSettings>();
    // final preciseLayout = options.preciseLayout.watch(context);
    bool preciseLayout = false;

    SliverChildBuilderDelegate delegate(int sliver) {
      final section = _sections[sliver];
      return SliverChildBuilderDelegate((context, index) {
        final text = section.items[index];
        return Item(
          text: text,
          sliver: sliver,
          index: index,
        );
      }, childCount: section.items.length);
    }

    _ensureExtentContollers(_sections.length);

    return FocusTraversalGroup(
      policy: SuperReadingOrderTraversalPolicy(),
      child: LayoutInfoOverlay(
        extentControllers: _extentControllers,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            for (int i = 0; i < _sections.length; ++i)
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SuperSliverList(
                  extentController: _extentControllers[i],
                  extentsPrecalculationPolicy: (_) => preciseLayout,
                  delegate: delegate(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? createSidebarWidget() {
    return _SidebarWidget(
      settings: _settings,
      onJumpRequested: (section, item, alignment) {
        final offset = _extentControllers[section].getOffsetToReveal(
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
    required this.numSections,
    required this.numItemsPerSection,
    required this.onJumpRequested,
  });

  final int numSections;
  final int numItemsPerSection;
  final void Function(int section, int item, double alignment) onJumpRequested;

  @override
  State<StatefulWidget> createState() => _JumpWidgetState();
}

class _JumpWidgetState extends State<_JumpWidget> {
  int section = 0;
  int item = 0;
  double alignment = 0;

  @override
  void didUpdateWidget(covariant _JumpWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (section >= widget.numSections) {
      section = widget.numSections - 1;
    }
    if (item >= widget.numItemsPerSection) {
      item = widget.numItemsPerSection - 1;
    }
  }

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Section'),
            const Spacer(),
            Text('Section: $section'),
          ],
        ),
        Slider(
          min: 0,
          max: widget.numSections - 1,
          value: section.toDouble(),
          onChanged: (value) {
            final section = value.round();
            if (section != this.section) {
              setState(() {
                this.section = section;
              });
            }
          },
        ),
        Row(
          children: [
            const Text('Item'),
            const Spacer(),
            Text('$item'),
          ],
        ),
        Slider(
          min: 0,
          max: widget.numItemsPerSection - 1,
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
            const Text('Alignment'),
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
        FlatButton(
          onPressed: () {
            widget.onJumpRequested(section, item, alignment);
          },
          child: const Text('Jump'),
        ),
      ],
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  final void Function(int section, int item, double alignment) onJumpRequested;
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
          title: const Text('Sections'),
          options: List.generate(9, (index) => index + 1),
          value: sliverCount,
          onChanged: (value) {
            settings.sliverCount.value = value;
          },
        ),
        _NumberPicker(
          title: const Text('Items per Section'),
          options: const [1, 9, 27, 80, 200, 1000, 7000],
          value: itemPerSliver,
          onChanged: (value) {
            settings.itemsPerSliver.value = value;
          },
        ),
        _JumpWidget(
          numSections: sliverCount,
          numItemsPerSection: itemPerSliver,
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
