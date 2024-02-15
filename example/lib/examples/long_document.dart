import "package:context_watch/context_watch.dart";
import "package:example/shell/app_settings.dart";
import "package:example/shell/buttons.dart";
import "package:example/shell/check_box.dart";
import "package:example/shell/example_page.dart";
import "package:flutter/material.dart" show Icons, Colors;
import "package:flutter/widgets.dart";
import "package:provider/provider.dart";
import "package:super_sliver_list/super_sliver_list.dart";

import "../data/sherlock.dart" as sherlock;
import "layout_info_overlay.dart";

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

  final removeTrailingItemCount = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    final options = context.watch<AppSettings>();
    final showSliverList = options.showSliverList.watch(context);
    final sliverCount = this.sliverCount.watch(context);
    final removeTraling = removeTrailingItemCount.watch(context);
    const paragraphs = sherlock.paragraphs;
    SliverChildBuilderDelegate delegate(int sliver) =>
        SliverChildBuilderDelegate((context, index) {
          final paragraph = sherlock.paragraphs[index];
          return _ParagraphWidget(
            index: index,
            sliver: sliver,
            paragraph: paragraph,
          );
        },
            childCount: (paragraphs.length - removeTraling)
                .clamp(0, paragraphs.length));
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
                for (int i = 0; i < sliverCount; ++i)
                  SuperSliverList(
                    extentController: _extentControllers[i],
                    extentPrecalculationPolicy: options.extentPrecalculationPolicy,
                    delegate: delegate(i),
                  ),
              ],
            ),
          ),
        ),
        if (showSliverList)
          Expanded(
            child: CustomScrollView(
              slivers: [
                for (int i = 0; i < sliverCount; ++i)
                  SliverList(
                    delegate: delegate(i),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget? createSidebarWidget() {
    return _SidebarWidget(
      sliverCount: sliverCount,
      removeTrailingItemCount: removeTrailingItemCount,
      onInvalidateLayout: () {
        for (final c in _extentControllers) {
          for (int i = 0; i < c.numberOfItems; ++i) {
            c.invalidateExtent(i);
          }
        }
      },
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  final VoidCallback onInvalidateLayout;
  final ValueNotifier<int> sliverCount;
  final ValueNotifier<int> removeTrailingItemCount;

  const _SidebarWidget({
    super.key,
    required this.onInvalidateLayout,
    required this.sliverCount,
    required this.removeTrailingItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    return Column(
      children: [
        _NumberPicker(value: sliverCount, min: 1, max: 10),
        _NumberPicker(value: removeTrailingItemCount, min: 0, max: 100),
        FlatButton(
            child: Text("Invalidate"),
            onPressed: () {
              onInvalidateLayout();
            })
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final ValueNotifier<int> value;
  final int min;
  final int max;

  const _NumberPicker({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlatButton(
          onPressed: () {
            if (value.value > min) {
              value.value--;
            }
          },
          child: const Icon(Icons.remove),
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: value,
            builder: (context, value, child) {
              return Text(
                "$value",
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
        FlatButton(
          onPressed: () {
            if (value.value < max) {
              value.value++;
            }
          },
          child: const Icon(Icons.add),
        ),
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
    return Container(
      padding: const EdgeInsets.all(8.0),
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
          Text(paragraph),
        ],
      ),
    );
  }
}
