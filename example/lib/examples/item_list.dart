import "package:context_watch/context_watch.dart";
import "package:flutter/material.dart" show Colors;
import "package:flutter/services.dart";
import "package:flutter_lorem/flutter_lorem.dart";
import "package:pixel_snap/widgets.dart";
import "package:provider/provider.dart";
import "package:super_sliver_list/super_sliver_list.dart";

import "../shell/app_settings.dart";
import "../shell/example_page.dart";
import "../shell/sidebar.dart";
import "../util/show_on_screen.dart";
import "../widgets/jump_widget.dart";
import "../widgets/layout_info_overlay.dart";
import "../widgets/list_header.dart";
import "../widgets/number_picker.dart";
import "../widgets/sliver_decoration.dart";
import "../widgets/sliver_list_disclaimer.dart";

const _kMaxSlivers = 10;
const _kItemsPerSliver = [1, 9, 27, 80, 200, 1000, 2500, 7000, 20000];

class _ReadingOrderTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // For list traversal the history flutter keeps have weird behavior.
    invalidateScopeData(currentNode.nearestScope!);
    return super.inDirection(currentNode, direction);
  }
}

class _ItemListSettings {
  final sliverCount = ValueNotifier(5);
  final itemsPerSliver = ValueNotifier(1000);
  final maxLength = ValueNotifier(6);
}

class ItemWidget extends StatefulWidget {
  final String text;
  final int sliver;
  final int index;

  const ItemWidget({
    super.key,
    required this.text,
    required this.sliver,
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
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
    final bool selected = _focusNode.hasFocus;
    return GestureDetector(
      onTapDown: (_) {
        _focusNode.requestFocus();
      },
      child: Focus.withExternalFocusNode(
        focusNode: _focusNode,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected ? Colors.blue : Colors.transparent,
          ),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Sliver ${widget.sliver}, Item ${widget.index}",
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.text,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
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
    required this.maxLength,
  });

  final int index;
  final int maxLength;

  String get text {
    final length = (Object.hash(index, null) % 20 * maxLength) + 2;
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

  int? _maxLength;

  void ensureItemCount(int count, int maxLength) {
    if (_maxLength != maxLength) {
      _maxLength = maxLength;
      items.clear();
    } else {
      while (items.length > count) {
        items.removeLast();
      }
    }
    while (items.length < count) {
      items.add(_Item(
        index: items.length,
        maxLength: maxLength,
      ));
    }
  }
}

class _ItemListPageState extends ExamplePageState {
  final _sliverData = <_SliverData>[];

  final List<ExtentController> _extentControllers = [];
  late ScrollController _scrollController;

  int? _maxLength;

  void _updateSliverData(int sliverCount, int itemsPerSliver, int maxLength) {
    while (_sliverData.length > sliverCount) {
      _sliverData.removeLast();
    }
    while (_sliverData.length < sliverCount) {
      _sliverData.add(_SliverData(title: "Sliver ${_sliverData.length}"));
    }
    for (final sliver in _sliverData) {
      sliver.ensureItemCount(itemsPerSliver, maxLength);
    }
    if (_maxLength != maxLength) {
      _maxLength = maxLength;
      for (final controller in _extentControllers) {
        controller.invalidateAllExtents();
      }
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
    final int maxLength = _settings.maxLength.watch(context);
    _updateSliverData(
      sliverCount,
      itemsPerSliver,
      maxLength,
    );

    final options = context.watch<AppSettings>();
    final showSliverList = options.showSliverList.watch(context);

    SliverChildBuilderDelegate delegate(int sliverIndex) {
      final sliver = _sliverData[sliverIndex];
      return SliverChildBuilderDelegate((context, index) {
        final item = sliver.items[index];
        return ItemWidget(
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
            policy: _ReadingOrderTraversalPolicy(),
            child: LayoutInfoOverlay(
              extentControllers: _extentControllers,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  const ListHeader(
                    title: Text("SuperSliverList"),
                    primary: true,
                  ),
                  for (int i = 0; i < _sliverData.length; ++i)
                    SliverDecoration(
                      index: i,
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
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.blueGrey.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: FocusTraversalGroup(
                policy: _ReadingOrderTraversalPolicy(),
                child: CustomScrollView(
                  slivers: [
                    const ListHeader(
                      title: Text("SliverList"),
                      primary: false,
                    ),
                    if (itemsPerSliver * sliverCount > 5000)
                      SliverListDisclaimer(),
                    for (int i = 0; i < _sliverData.length; ++i)
                      SliverDecoration(
                        index: i,
                        sliver: SliverList(
                          delegate: delegate(i),
                        ),
                      ),
                  ],
                ),
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
        _extentControllers[sliver].jumpToItem(
          index: item,
          scrollController: _scrollController,
          alignment: alignment,
        );
      },
      onAnimateRequested: (sliver, item, alignment) {
        _extentControllers[sliver].animateToItem(
          index: item,
          scrollController: _scrollController,
          alignment: alignment,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  final void Function(int sliver, int item, double alignment) onJumpRequested;
  final void Function(int sliver, int item, double alignment)
      onAnimateRequested;
  final _ItemListSettings settings;

  const _SidebarWidget({
    required this.onJumpRequested,
    required this.onAnimateRequested,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final sliverCount = settings.sliverCount.watch(context);
    final itemPerSliver = settings.itemsPerSliver.watch(context);
    final maxLength = settings.maxLength.watch(context);

    return SidebarOptions(
      sections: [
        SidebarSection(
          title: const Text("Contents"),
          children: [
            NumberPicker(
              title: const Text("Slivers"),
              options: List.generate(_kMaxSlivers - 1, (index) => index + 1),
              value: sliverCount,
              onChanged: (value) {
                settings.sliverCount.value = value;
              },
            ),
            NumberPicker(
              title: const Text("Items per Sliver"),
              options: _kItemsPerSliver,
              value: itemPerSliver,
              onChanged: (value) {
                settings.itemsPerSliver.value = value;
              },
            ),
            NumberPicker(
              title: const Text("Maximum Item Length"),
              options: List.generate(15, (index) => index + 1),
              value: maxLength,
              onChanged: (value) {
                settings.maxLength.value = value;
              },
            ),
          ],
        ),
        JumpWidget(
          numSlivers: sliverCount,
          numItemsPerSliver: itemPerSliver,
          onJumpRequested: onJumpRequested,
          onAnimateRequested: onAnimateRequested,
        ),
        const AppSettingsWidget(),
      ],
    );
  }
}
