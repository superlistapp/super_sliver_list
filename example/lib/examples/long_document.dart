import "package:context_plus/context_plus.dart";
import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";
import "package:super_sliver_list_example_data/sherlock.dart" as sherlock;

import "../shell/app_settings.dart";
import "../shell/example_page.dart";
import "../shell/sidebar.dart";
import "../widgets/check_box.dart";
import "../widgets/jump_widget.dart";
import "../widgets/layout_info_overlay.dart";
import "../widgets/list_header.dart";
import "../widgets/number_picker.dart";
import "../widgets/sliver_decoration.dart";
import "../widgets/sliver_list_disclaimer.dart";

const _kMaxSlivers = 10;

class LongDocumentPage extends StatefulWidget {
  const LongDocumentPage({super.key});

  @override
  State<StatefulWidget> createState() => _LogDocumentPageState();
}

class _LogDocumentPageState extends ExamplePageState<LongDocumentPage> {
  final _scrollController = ScrollController();

  final List<ListController> _listControllers = [];

  void _ensureExtentContollers(int count) {
    while (_listControllers.length > count) {
      _listControllers.last.dispose();
      _listControllers.removeLast();
    }
    while (_listControllers.length < count) {
      _listControllers.add(ListController());
    }
  }

  final sliverCount = ValueNotifier(1);
  final stickyHeaders = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final options = appSettings.of(context);
    final showSliverList = options.showSliverList.watchValue(context);
    final sliverCount = this.sliverCount.watchValue(context);
    final stickyHeaders = this.stickyHeaders.watchValue(context);

    const paragraphs = sherlock.paragraphs;
    SliverChildBuilderDelegate delegate(int sliver) =>
        SliverChildBuilderDelegate((context, index) {
          final paragraph = sherlock.paragraphs[index];
          return _ParagraphWidget(
            index: index,
            sliver: sliver,
            paragraph: paragraph,
          );
        }, childCount: paragraphs.length);
    _ensureExtentContollers(sliverCount);
    return SafeArea(
      top: false,
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutInfoOverlay(
              listControllers: _listControllers,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  const ListHeader(
                    title: Text("SuperSliverList"),
                    primary: true,
                  ),
                  for (int i = 0; i < sliverCount; ++i)
                    SliverDecoration(
                      stickyHeader: stickyHeaders,
                      index: i,
                      sliver: SuperSliverList(
                        listController: _listControllers[i],
                        extentPrecalculationPolicy:
                            options.extentPrecalculationPolicy,
                        delegate: delegate(i),
                      ),
                    ),
                  const ListFooter(),
                ],
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
                child: CustomScrollView(
                  slivers: [
                    const ListHeader(
                      title: Text("SliverList"),
                      primary: false,
                    ),
                    if (sliverCount > 1) SliverListDisclaimer(),
                    for (int i = 0; i < sliverCount; ++i)
                      SliverDecoration(
                        stickyHeader: stickyHeaders,
                        index: i,
                        sliver: SliverList(
                          delegate: delegate(i),
                        ),
                      ),
                    const ListFooter(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget? createSidebarWidget() {
    return _SidebarWidget(
      sliverCount: sliverCount,
      stickyHeaders: stickyHeaders,
      itemCount: sherlock.paragraphs.length,
      onJumpRequested: (sliver, item, alignment) {
        _listControllers[sliver].jumpToItem(
          index: item,
          scrollController: _scrollController,
          alignment: alignment,
        );
      },
      onAnimateRequested: (sliver, item, alignment) {
        _listControllers[sliver].animateToItem(
          index: item,
          scrollController: _scrollController,
          alignment: alignment,
          duration: (_) => const Duration(milliseconds: 300),
          curve: (_) => Curves.easeOutCubic,
        );
      },
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  final ValueNotifier<int> sliverCount;
  final ValueNotifier<bool> stickyHeaders;
  final int itemCount;
  final void Function(int sliver, int item, double alignment) onJumpRequested;
  final void Function(int sliver, int item, double alignment)
      onAnimateRequested;

  const _SidebarWidget({
    required this.sliverCount,
    required this.stickyHeaders,
    required this.itemCount,
    required this.onJumpRequested,
    required this.onAnimateRequested,
  });

  @override
  Widget build(BuildContext context) {
    final sliverCount = this.sliverCount.watchValue(context);
    final stickyHeaders = this.stickyHeaders.watchValue(context);
    return SidebarOptions(
      sections: [
        SidebarSection(
          title: const Text("Contents"),
          children: [
            NumberPicker(
              title: const Text("Slivers"),
              options: List.generate(_kMaxSlivers, (index) => index + 1),
              value: sliverCount,
              onChanged: (value) {
                this.sliverCount.value = value;
              },
            ),
            CheckBox(
              checked: stickyHeaders,
              child: const Text("Sticky headers"),
              onChanged: (value) => this.stickyHeaders.value = value,
            ),
          ],
        ),
        JumpWidget(
          numSlivers: sliverCount,
          numItemsPerSliver: itemCount,
          onJumpRequested: onJumpRequested,
          onAnimateRequested: onAnimateRequested,
        ),
        const AppSettingsWidget(),
      ],
    );
  }
}

class _ParagraphWidget extends StatelessWidget {
  final String paragraph;
  final int sliver;
  final int index;

  const _ParagraphWidget({
    required this.paragraph,
    required this.sliver,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sliver $sliver, Paragraph $index",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(paragraph),
          ],
        ),
      ),
    );
  }
}
