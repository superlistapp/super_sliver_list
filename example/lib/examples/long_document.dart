import "package:context_watch/context_watch.dart";
import "package:flutter/material.dart" show Colors;
import "package:pixel_snap/widgets.dart";
import "package:provider/provider.dart";
import "package:super_sliver_list/super_sliver_list.dart";
import "package:super_sliver_list_example_data/sherlock.dart" as sherlock;

import "../shell/app_settings.dart";
import "../shell/example_page.dart";
import "../shell/sidebar.dart";
import "../widgets/jump_widget.dart";
import "../widgets/layout_info_overlay.dart";
import "../widgets/list_header.dart";
import "../widgets/number_picker.dart";

const _kMaxSlivers = 10;

class _SliverDecoration extends StatelessWidget {
  final Widget sliver;

  const _SliverDecoration({
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: sliver,
    );
  }
}

class LongDocumentPage extends StatefulWidget {
  const LongDocumentPage({super.key});

  @override
  State<StatefulWidget> createState() => _LogDocumentPageState();
}

class _LogDocumentPageState extends ExamplePageState<LongDocumentPage> {
  final _scrollController = ScrollController();

  final List<ExtentController> _extentControllers = [];

  void _ensureExtentContollers(int count) {
    while (_extentControllers.length > count) {
      _extentControllers.last.dispose();
      _extentControllers.removeLast();
    }
    while (_extentControllers.length < count) {
      _extentControllers.add(ExtentController());
    }
  }

  final sliverCount = ValueNotifier(1);

  @override
  Widget build(BuildContext context) {
    final options = context.watch<AppSettings>();
    final showSliverList = options.showSliverList.watch(context);
    final sliverCount = this.sliverCount.watch(context);
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutInfoOverlay(
            extentControllers: _extentControllers,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: ListHeader(
                    title: Text("SuperSliverList"),
                    primary: true,
                  ),
                ),
                for (int i = 0; i < sliverCount; ++i)
                  _SliverDecoration(
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
                  const SliverToBoxAdapter(
                    child: ListHeader(
                      title: Text("SliverList"),
                      primary: false,
                    ),
                  ),
                  for (int i = 0; i < sliverCount; ++i)
                    _SliverDecoration(
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
      sliverCount: sliverCount,
      itemCount: sherlock.paragraphs.length,
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

class _SidebarWidget extends StatelessWidget {
  final ValueNotifier<int> sliverCount;
  final int itemCount;
  final void Function(int sliver, int item, double alignment) onJumpRequested;

  const _SidebarWidget({
    required this.sliverCount,
    required this.itemCount,
    required this.onJumpRequested,
  });

  @override
  Widget build(BuildContext context) {
    final sliverCount = this.sliverCount.watch(context);
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
                this.sliverCount.value = value;
              },
            ),
          ],
        ),
        JumpWidget(
          numSlivers: sliverCount,
          numItemsPerSliver: itemCount,
          onJumpRequested: onJumpRequested,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade300,
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
