import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";
import "package:logging/logging.dart";
import "package:sliver_tools/sliver_tools.dart";
import "package:super_sliver_list/super_sliver_list.dart";

// ignore: deprecated_member_use
import "package:test_api/src/backend/invoker.dart" as invoker;

import "fuzzer.dart";
import "sliver_list_configuration.dart";
import "test_logger.dart";

Matcher roughlyEquals(double value) {
  return closeTo(value, precisionErrorTolerance);
}

final _log = Logger("super_sliver_list_test");

class _SimpleExtentPrecalculatePolicy extends ExtentPrecalculationPolicy {
  final bool precalculate;

  _SimpleExtentPrecalculatePolicy({required this.precalculate});

  @override
  bool shouldPrecalculateExtents(_) => precalculate;
}

class _TestLayoutBudget extends SuperSliverListLayoutBudget {
  double _count = 0;
  static const limit = 8;

  @override
  void reset() {
    _count = 0;
  }

  @override
  void beginLayout() {}

  @override
  void endLayout() {}

  @override
  bool shouldLayoutNextItem() {
    ++_count;
    return _count <= limit;
  }
}

class _KeepAliveWidget extends StatefulWidget {
  const _KeepAliveWidget({
    super.key,
    this.wantKeepAlive = false,
    required this.child,
  });

  final bool wantKeepAlive;
  final Widget child;

  @override
  State<StatefulWidget> createState() => _KeepAliveWidgetState();
}

class _KeepAliveWidgetState extends State<_KeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // https://github.com/flutter/flutter/issues/145291
    updateKeepAlive();
    return widget.child;
  }

  @override
  bool get wantKeepAlive => widget.wantKeepAlive;
}

void main() async {
  initTestLogging();
  setUp(() {
    SuperSliverList.layoutBudget = _TestLayoutBudget();
    resetTestLog();
    final onError = invoker.Invoker.current!.liveTest.onError;
    onError.listen((event) {
      printTestLog();
    });
  });

  group("SuperSliverList", () {
    testWidgets("reverse children (with keys)", (tester) async {
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
      );

      final ScrollController controller = ScrollController(
          initialScrollOffset: configuration.bottomScrollOffsetInitial);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildSliverList(
        configuration,
        preciseLayout: true,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(controller.offset, roughlyEquals(configuration.maxScrollExtent));
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);

      final reversed = configuration.copyWith(
        slivers: [
          Sliver(
            configuration.slivers.first.items.reversed.toList(),
            pinnedHeaderHeight: 0,
          ),
        ],
        viewportHeight: configuration.viewportHeight,
      );

      await tester.pumpWidget(_buildSliverList(
        reversed,
        preciseLayout: true,
        controller: controller,
      ));
      final int frames = await tester.pumpAndSettle();
      // ensures that there is no (animated) bouncing of the scrollable
      expect(frames, 1);

      expect(controller.offset, roughlyEquals(configuration.maxScrollExtent));
      expect(find.text("Tile 0:19"), findsNothing);
      expect(find.text("Tile 0:18"), findsNothing);
      expect(find.text("Tile 0:1"), findsOneWidget);
      expect(find.text("Tile 0:0"), findsOneWidget);

      controller.jumpTo(0.0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);
      expect(find.text("Tile 0:19"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:0"), findsNothing);
    });

    testWidgets("replace children (with keys)", (tester) async {
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        itemValue: (_, index) => index,
        viewportHeight: 500,
      );

      final ScrollController controller = ScrollController(
          initialScrollOffset: configuration.bottomScrollOffsetInitial);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildSliverList(
        configuration,
        preciseLayout: true,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      expect(controller.offset, roughlyEquals(configuration.maxScrollExtent));
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);

      final configuration2 = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        itemValue: (_, index) => index + 100,
        viewportHeight: 500,
      );

      await tester.pumpWidget(_buildSliverList(
        configuration2,
        controller: controller,
        preciseLayout: true,
      ));
      final int frames = await tester.pumpAndSettle();
      // ensures that there is no (animated) bouncing of the scrollable
      expect(frames, 1);

      expect(controller.offset, roughlyEquals(configuration2.maxScrollExtent));
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:18"), findsNothing);
      expect(find.text("Tile 0:19"), findsNothing);

      expect(find.text("Tile 0:100"), findsNothing);
      expect(find.text("Tile 0:101"), findsNothing);
      expect(find.text("Tile 0:118"), findsOneWidget);
      expect(find.text("Tile 0:119"), findsOneWidget);

      controller.jumpTo(0.0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
      expect(find.text("Tile 0:100"), findsOneWidget);
      expect(find.text("Tile 0:101"), findsOneWidget);
      expect(find.text("Tile 0:118"), findsNothing);
      expect(find.text("Tile 0:119"), findsNothing);
    });

    testWidgets("replace with shorter children list (with keys)",
        (tester) async {
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
      );

      final ScrollController controller = ScrollController(
          initialScrollOffset: configuration.bottomScrollOffsetInitial);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildSliverList(
        configuration,
        controller: controller,
        preciseLayout: true,
      ));
      await tester.pumpAndSettle();

      expect(controller.offset, roughlyEquals(configuration.maxScrollExtent));
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:17"), findsNothing);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);

      final configuration2 = configuration.copyWith(slivers: [
        configuration.slivers.first.copyWith(
          items: configuration.slivers.first.items.sublist(0, 19),
        ),
      ]);

      await tester.pumpWidget(_buildSliverList(
        configuration2,
        controller: controller,
        preciseLayout: true,
      ));
      final int frames = await tester.pumpAndSettle();
      expect(frames, 1); // No animation when content shrinks suddenly.

      expect(controller.offset, roughlyEquals(configuration2.maxScrollExtent));
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:1"), findsNothing);
      expect(find.text("Tile 0:17"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsNothing);
    });

    testWidgets("should layout first child in case of child reordering",
        (tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/35904.
      List<String> items = <String>["1", "2"];
      final ScrollController controller1 = ScrollController();
      addTearDown(controller1.dispose);
      await tester.pumpWidget(
        _buildSliverListRenderWidgetChild(items, controller1),
      );
      await tester.pumpAndSettle();

      expect(find.text("Tile 1"), findsOneWidget);
      expect(find.text("Tile 2"), findsOneWidget);

      items = items.reversed.toList();
      final ScrollController controller2 = ScrollController();
      addTearDown(controller2.dispose);
      await tester
          .pumpWidget(_buildSliverListRenderWidgetChild(items, controller2));
      await tester.pumpAndSettle();

      expect(find.text("Tile 1"), findsOneWidget);
      expect(find.text("Tile 2"), findsOneWidget);
    });

    testWidgets("should recalculate inaccurate layout offset case 1",
        (tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/42142.

      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 50,
        viewportHeight: 200,
      );
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text("Tile 0:2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, 800.0);
      expect(find.text("Tile 0:15"), findsNothing);
      expect(find.text("Tile 0:16"), findsOneWidget);
      expect(find.text("Tile 0:17"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);

      // Prepends item to the list.
      configuration.slivers.first.items.insert(
        0,
        configuration.slivers.first.items.first.copyWith(value: -1),
      );
      await tester.pumpWidget(
        _buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: true,
        ),
      );
      await tester.pump();
      // We need second pump to ensure the scheduled animation gets run.
      await tester.pumpAndSettle();
      // Scroll offset should stay the same, and the items in viewport should be
      // shifted by one.
      expect(controller.offset, 800.0);
      expect(find.text("Tile 0:14"), findsNothing);
      expect(find.text("Tile 0:15"), findsOneWidget);
      expect(find.text("Tile 0:16"), findsOneWidget);
      expect(find.text("Tile 0:17"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsNothing);

      // Drags back to beginning and newly added item is visible.
      await tester.drag(find.text("Tile 0:16"), const Offset(0.0, 1000.0));
      await tester.pumpAndSettle();
      expect(controller.offset, 0.0);
      expect(find.text("Tile 0:-1"), findsOneWidget);
      expect(find.text("Tile 0:0"), findsOneWidget);
      expect(find.text("Tile 0:1"), findsOneWidget);
      expect(find.text("Tile 0:2"), findsOneWidget);
      expect(find.text("Tile 0:3"), findsNothing);
    });

    testWidgets("should recalculate inaccurate layout offset case 2",
        (tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/42142.
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 50,
        viewportHeight: 195,
      );
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text("Tile 0:2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, roughlyEquals(805.0));
      expect(find.text("Tile 0:15"), findsNothing);
      expect(find.text("Tile 0:16"), findsOneWidget);
      expect(find.text("Tile 0:17"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);

      // Reorders item to the front. This should make item 19 to be first child
      // with layout offset = null.
      final items = configuration.slivers.first.items;
      final swap = items[19];
      items[19] = items[3];
      items[3] = swap;
      final configuration2 = configuration.copyWith(
        viewportHeight: 200,
      );

      await tester.pumpWidget(
        _buildSliverList(
          configuration2,
          controller: controller,
          preciseLayout: true,
        ),
      );
      await tester.pump();
      // We need second pump to ensure the scheduled animation gets run.
      await tester.pumpAndSettle();
      // Scroll offset should stay the same
      expect(controller.offset, 800.0);
      expect(find.text("Tile 0:14"), findsNothing);
      expect(find.text("Tile 0:15"), findsNothing);
      expect(find.text("Tile 0:16"), findsOneWidget);
      expect(find.text("Tile 0:17"), findsOneWidget);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:3"), findsOneWidget);
    });

    testWidgets(
        "should start to perform layout from the initial child when there is no valid offset",
        (tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/66198.
      bool isShow = true;
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      Widget buildSliverList(ScrollController controller) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              height: 200,
              child: CustomScrollView(
                controller: controller,
                slivers: <Widget>[
                  SuperSliverList(
                    extentPrecalculationPolicy:
                        _SimpleExtentPrecalculatePolicy(precalculate: true),
                    delegate: SliverChildListDelegate(
                      [
                        if (isShow)
                          for (int i = 0; i < 20; i++)
                            SizedBox(
                              height: 50,
                              child: Text("Tile 0:$i"),
                            ),
                        const SizedBox(), // Use this widget to occupy the position where the offset is 0 when rebuild
                        const SizedBox(key: Key("key0"), height: 50.0),
                        const SizedBox(key: Key("key1"), height: 50.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildSliverList(controller));
      await tester.pumpAndSettle();

      // Scrolling to the bottom.
      await tester.drag(find.text("Tile 0:2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, roughlyEquals(900.0));
      expect(find.text("Tile 0:17"), findsNothing);
      expect(find.text("Tile 0:18"), findsOneWidget);
      expect(find.text("Tile 0:19"), findsOneWidget);
      expect(find.byKey(const Key("key0")), findsOneWidget);
      expect(find.byKey(const Key("key1")), findsOneWidget);

      // Trigger rebuild.
      isShow = false;
      await tester.pumpWidget(buildSliverList(controller));

      // After rebuild, [ContainerRenderObjectMixin] has two children, and
      // neither of them has a valid layout offset.
      // SliverList can layout normally without any assert or dead loop.
      // Only the 'SizeBox' show in the viewport.
      expect(controller.offset, 0.0);
      expect(find.text("Tile 0:0"), findsNothing);
      expect(find.text("Tile 0:19"), findsNothing);
      expect(find.byKey(const Key("key0")), findsOneWidget);
      expect(find.byKey(const Key("key1")), findsOneWidget);
    });

    testWidgets("initially empty list", (tester) async {
      await tester.pumpWidget(
        _buildSliverList(
          SliverListConfiguration.generate(
            itemsPerSliver: (_) => 0,
            itemHeight: (_, __) => 100,
            viewportHeight: 500,
          ),
          preciseLayout: false,
        ),
      );
      await tester.pumpWidget(
        _buildSliverList(
          SliverListConfiguration.generate(
            itemsPerSliver: (_) => 10,
            itemHeight: (_, __) => 100,
            viewportHeight: 500,
          ),
          preciseLayout: false,
        ),
      );
      // Failing this likely means the child manager is not aware of underflow.
      expect(find.text("Tile 0:0"), findsOneWidget);
    });

    testWidgets("shrinkWrap", (tester) async {
      final list = SliverListConfiguration.generate(
        slivers: 3,
        itemsPerSliver: (_) => 1,
        itemHeight: (_, __) => 10,
        viewportHeight: 500,
        pinnedHeaderHeight: (i) => i == 0 ? 100 : 0,
      );
      await tester.pumpWidget(
        _buildSliverList(
          list,
          preciseLayout: false,
          shrinkWrap: true,
        ),
      );
      final frames = await tester.pumpAndSettle();
      expect(frames, 1);
    });

    testWidgets("visible range", (tester) async {
      final list = SliverListConfiguration.generate(
        slivers: 3,
        itemsPerSliver: (_) => 6,
        itemHeight: (_, __) => 100,
        viewportHeight: 500,
        pinnedHeaderHeight: (i) => i == 0 ? 100 : 0,
      );
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildSliverList(
          list,
          controller: controller,
          preciseLayout: false,
        ),
      );
      expect(list.slivers[0].listController.visibleRange, equals((0, 3)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((0, 3)));
      expect(list.slivers[1].listController.visibleRange, isNull);

      controller.jumpTo(100);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((0, 4)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((1, 4)));
      expect(list.slivers[1].listController.visibleRange, isNull);

      controller.jumpTo(199);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((0, 5)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((1, 5)));
      expect(list.slivers[1].listController.visibleRange, isNull);

      controller.jumpTo(200);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((1, 5)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((2, 5)));
      expect(list.slivers[1].listController.visibleRange, isNull);

      controller.jumpTo(299);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((1, 5)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((2, 5)));
      expect(list.slivers[1].listController.visibleRange, equals((0, 0)));
      expect(list.slivers[1].listController.unobstructedVisibleRange,
          equals((0, 0)));

      controller.jumpTo(300);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((2, 5)));
      expect(list.slivers[0].listController.unobstructedVisibleRange,
          equals((3, 5)));
      expect(list.slivers[1].listController.visibleRange, equals((0, 0)));
      expect(list.slivers[1].listController.unobstructedVisibleRange,
          equals((0, 0)));

      controller.jumpTo(600);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, equals((5, 5)));
      expect(list.slivers[0].listController.unobstructedVisibleRange, isNull);
      expect(list.slivers[1].listController.visibleRange, equals((0, 3)));
      expect(list.slivers[1].listController.unobstructedVisibleRange,
          equals((0, 3)));

      controller.jumpTo(700);
      await tester.pump();

      expect(list.slivers[0].listController.visibleRange, isNull);
      expect(list.slivers[0].listController.unobstructedVisibleRange, isNull);
      expect(list.slivers[1].listController.visibleRange, equals((0, 4)));
      expect(list.slivers[1].listController.unobstructedVisibleRange,
          equals((1, 4)));
    });

    testWidgets("kept alive widgets are laid out", (tester) async {
      final key1 = GlobalKey();
      final key2 = GlobalKey();
      final controller = ScrollController();
      Widget build(double width) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 500,
              width: width,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                controller: controller,
                slivers: [
                  SuperSliverList(
                    layoutKeptAliveChildren: true,
                    delayPopulatingCacheArea: false,
                    delegate: SliverChildListDelegate([
                      _KeepAliveWidget(
                        key: key1,
                        wantKeepAlive: true,
                        child: AspectRatio(
                          aspectRatio: 5.0,
                          child: Container(),
                        ),
                      ),
                      _KeepAliveWidget(
                        key: key2,
                        wantKeepAlive: true,
                        child: AspectRatio(
                          aspectRatio: 5.0,
                          child: Container(),
                        ),
                      ),
                      for (int i = 0; i < 100; ++i) const SizedBox(height: 100)
                    ]),
                  )
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(500));
      {
        final renderBox = key2.currentContext!.findRenderObject()! as RenderBox;
        expect(renderBox.size, equals(const Size(500, 100)));
        final position = renderBox.localToGlobal(Offset.zero);
        expect(position, equals(const Offset(0, 100)));
      }
      controller.jumpTo(1000);
      await tester.pump();
      {
        final renderBox = key2.currentContext!.findRenderObject()! as RenderBox;
        final parentData = renderBox.parent!.parent!.parentData!
            as SliverMultiBoxAdaptorParentData;
        expect(parentData.keepAlive, isTrue);
        expect(renderBox.size, equals(const Size(500, 100)));
        final position = renderBox.localToGlobal(Offset.zero);
        expect(position, equals(const Offset(0, -900)));
      }
      await tester.pumpWidget(build(600));
      expect(
          controller.position.pixels, 1040); // Correction for kept alive items
      controller.jumpTo(1000); // undo scroll offset correction
      {
        final renderBox = key2.currentContext!.findRenderObject()! as RenderBox;
        final parentData = renderBox.parent!.parent!.parentData!
            as SliverMultiBoxAdaptorParentData;
        expect(parentData.keepAlive, isTrue);
        expect(renderBox.size, equals(const Size(600, 120)));
        final position = renderBox.localToGlobal(Offset.zero);
        // Shifted slightly because the item before is 20px taller.
        expect(position, equals(const Offset(0, -920)));
      }
    });

    testWidgets("delay populating cache area enabled", (tester) async {
      final keys0 = List.generate(50, (index) => GlobalKey());
      final keys1 = List.generate(1, (index) => GlobalKey());
      final controller = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              height: 500,
              child: CustomScrollView(
                cacheExtent: 200,
                physics: const ClampingScrollPhysics(),
                controller: controller,
                slivers: [
                  SuperSliverList(
                    delayPopulatingCacheArea: true,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SizedBox(
                          key: keys0[index],
                          height: 100,
                          child: Text("Tile 0:$index"),
                        );
                      },
                      childCount: keys0.length,
                    ),
                  ),
                  SuperSliverList(
                    delayPopulatingCacheArea: true,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SizedBox(
                          key: keys1[index],
                          height: 100,
                          child: Text("Tile 0:$index"),
                        );
                      },
                      childCount: keys1.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(keys0[0].currentContext, isNotNull);

      // Cache area
      expect(keys0[5].currentContext, isNotNull);
      expect(keys0[6].currentContext, isNotNull);
      // After cache area
      expect(keys0[7].currentContext, isNull);

      // All items replaced, cache area should not be populated
      controller.jumpTo(2000);
      await tester.pump();

      // Items removed
      expect(keys0[0].currentContext, isNull);
      expect(keys0[6].currentContext, isNull);
      // Visible content
      expect(keys0[20].currentContext, isNotNull);
      expect(keys0[24].currentContext, isNotNull);
      // Cache area
      expect(keys0[19].currentContext, isNull);
      expect(keys0[25].currentContext, isNull);

      // Cache area of next sliver - must not be populated
      expect(keys1[0].currentContext, isNull);

      await tester.pump();
      // Cache area should now be populated
      expect(keys0[19].currentContext, isNotNull);
      expect(keys0[25].currentContext, isNotNull);

      // Cache area of next sliver - must not be populated
      expect(keys1[0].currentContext, isNull);

      controller.dispose();
    });

    testWidgets("delay populating cache area disabled", (tester) async {
      final keys = List.generate(50, (index) => GlobalKey());
      final controller = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              height: 500,
              child: CustomScrollView(
                cacheExtent: 200,
                physics: const ClampingScrollPhysics(),
                controller: controller,
                slivers: [
                  SuperSliverList(
                    delayPopulatingCacheArea: false,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SizedBox(
                          key: keys[index],
                          height: 100,
                          child: Text("Tile 0:$index"),
                        );
                      },
                      childCount: keys.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(keys[0].currentContext, isNotNull);

      // Cache area
      expect(keys[5].currentContext, isNotNull);
      expect(keys[6].currentContext, isNotNull);
      // After cache area
      expect(keys[7].currentContext, isNull);

      // All items replaced, cache area should immediately be populated
      controller.jumpTo(2000);
      await tester.pump();

      // Items removed
      expect(keys[0].currentContext, isNull);
      expect(keys[6].currentContext, isNull);
      // Visible content
      expect(keys[20].currentContext, isNotNull);
      expect(keys[24].currentContext, isNotNull);
      // Cache area
      expect(keys[19].currentContext, isNotNull);
      expect(keys[25].currentContext, isNotNull);
      controller.dispose();
    });

    testWidgets("does not exceed layout cycles", (tester) async {
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 50,
        itemHeight: (_, __) => 30,
        viewportHeight: 500,
      );
      final ScrollController controller =
          ScrollController(initialScrollOffset: 0);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildSliverList(
        configuration,
        preciseLayout: false,
        controller: controller,
        extentEstimation: (_, __) => 200,
        delayPopulatingCacheArea: false,
      ));
      await tester.pumpAndSettle();

      // This must not cause maximum layout cycle exceeded exception.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
    });
  });
  group("Fuzzer", () {
    testWidgets("layout multiple slivers scrolling down", (tester) async {
      Future<void> testConfiguration(
        SliverListConfiguration configuration, {
        required LayoutMode layoutMode,
      }) async {
        final ScrollController controller =
            ScrollController(initialScrollOffset: 0);

        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != LayoutMode.estimated,
        ));

        if (layoutMode == LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }

        await _checkSmoothScrolling(
          tester: tester,
          configuration: configuration,
          controller: controller,
          step: 150.0,
        );

        // Ensure all items have been laid out.
        expect(
          controller.position.maxScrollExtent,
          roughlyEquals(configuration.maxScrollExtent),
        );

        controller.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final provider = TestConfigurationProvider.createDefaultProvider();
      for (final configuration in provider.nextConfiguration()) {
        if (configuration.configuration.totalExtent == 0.0) {
          continue;
        }
        await testConfiguration(
          configuration.configuration,
          layoutMode: configuration.layoutMode,
        );
        resetTestLog();
      }
    });

    testWidgets("layout multiple slivers scrolling up", (tester) async {
      Future<void> testConfiguration(
        SliverListConfiguration configuration, {
        required LayoutMode layoutMode,
      }) async {
        final ScrollController controller = ScrollController(
            initialScrollOffset: configuration.bottomScrollOffsetInitial);

        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != LayoutMode.estimated,
        ));
        if (layoutMode == LayoutMode.preciseNoWait) {
          await tester.pump();
        } else {
          final frameCount = await tester.pumpAndSettle();
          if (layoutMode == LayoutMode.estimated) {
            expect(frameCount, 1); // No async layout
          } else {
            expect(
                controller.position.extentTotal,
                roughlyEquals(math.max(
                    configuration.totalExtent, configuration.viewportHeight)));
          }

          if (controller.initialScrollOffset > 0) {
            // Ensure it's scrolled to the end. Note that this depends on an behavior
            // in SuperSliverList where it keeps the sliver aligned to the end
            // through scroll correction when anchoredAtEnd && didAddInitialChild.
            expect(controller.position.pixels,
                roughlyEquals(controller.position.maxScrollExtent));
          } else {
            expect(controller.position.pixels, isZero);

            // After first layout the extent might have increased enough so that
            // we can scroll at the end. There is better way to do this
            // (extentManager.getOffsetToReveal) but we don't want that to be part
            // of the test.
            while (controller.position.pixels <
                controller.position.maxScrollExtent) {
              controller.jumpTo(controller.position.maxScrollExtent);
              await tester.pump();
            }
          }
        }

        await _checkSmoothScrolling(
          tester: tester,
          configuration: configuration,
          controller: controller,
          step: -150.0,
        );

        // Ensure all items have been laid out.
        expect(
          controller.position.maxScrollExtent,
          roughlyEquals(configuration.maxScrollExtent),
        );

        controller.dispose();

        await tester.pumpWidget(const SizedBox.shrink());
      }

      final provider = TestConfigurationProvider.createDefaultProvider();
      for (final configuration in provider.nextConfiguration()) {
        if (configuration.configuration.totalExtent == 0.0) {
          continue;
        }
        await testConfiguration(
          configuration.configuration,
          layoutMode: configuration.layoutMode,
        );
        resetTestLog();
      }
    });
    testWidgets("jump to bottom", (tester) async {
      Future<void> testConfiguration(SliverListConfiguration configuration,
          {required LayoutMode layoutMode}) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != LayoutMode.estimated,
        ));
        if (layoutMode == LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }
        final lastSliver = configuration.slivers.last;
        final offset = lastSliver.listController.getOffsetToReveal(
          lastSliver.items.length - 1,
          1.0,
        );
        if (offset < 0) {
          return;
        }
        controller.jumpTo(offset);
        await tester.pump();
        expect(controller.offset,
            roughlyEquals(controller.position.maxScrollExtent));

        controller.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final provider = TestConfigurationProvider.createDefaultProvider();
      for (final configuration in provider.nextConfiguration()) {
        if (configuration.configuration.totalExtent == 0.0 ||
            configuration.configuration.slivers.isEmpty ||
            configuration.configuration.slivers.last.items.isEmpty) {
          continue;
        }
        await testConfiguration(
          configuration.configuration,
          layoutMode: configuration.layoutMode,
        );
        resetTestLog();
      }
    });
    testWidgets("jump to item", (tester) async {
      Future<void> testConfiguration(
        SliverListConfiguration configuration, {
        required LayoutMode layoutMode,
        required List<(int, int)> offsets,
        required double alignment,
      }) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != LayoutMode.estimated,
        ));
        expect(controller.position.pixels, 0);
        if (layoutMode == LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }
        for (final (sliverIndex, itemIndex) in offsets) {
          final sliver = configuration.slivers[sliverIndex];
          final item = sliver.items[itemIndex];
          final offset = sliver.listController.getOffsetToReveal(
            itemIndex,
            alignment,
          );
          if (offset >= 0) {
            final overscroll = offset > controller.position.maxScrollExtent;

            _log.info("Jumping to offset $offset");
            controller.jumpTo(offset);
            await tester.pump();

            double viewportTop = tester.getTopLeft(find.byType(Viewport)).dy;
            double viewportHeight = configuration.viewportHeight;

            // Expected top of the content, adjusted for pinned headers.
            for (int i = 0; i <= sliverIndex; ++i) {
              final pinnedHeader = find.text("PinnedHeader $i");
              if (pinnedHeader.evaluate().isNotEmpty) {
                final height = tester.getBottomLeft(pinnedHeader).dy -
                    tester.getTopLeft(pinnedHeader).dy;
                viewportTop += height;
                viewportHeight -= height;
              }
            }

            final positionWithinViewport = tester
                    .getTopLeft(find.text("Tile $sliverIndex:${item.value}"))
                    .dy -
                viewportTop;

            // If item height is less than viewport it must not start above the top.
            if (configuration.maxItemHeight <= viewportHeight) {
              expect(positionWithinViewport >= 0, isTrue);
            }

            // When out of bounds we have at least checked that the item is present
            // but the position is not guaranteed.
            if (!overscroll &&
                controller.position.pixels <
                    controller.position.maxScrollExtent) {
              final expectedTop = (viewportHeight - item.height) * alignment;
              expect(positionWithinViewport, roughlyEquals(expectedTop));
            }
          } else {
            _log.info("Skipping jump to offset $offset");
          }
        }

        controller.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final provider = TestConfigurationProvider.createDefaultProvider();
      for (final configuration in provider.nextConfiguration()) {
        if (configuration.configuration.totalExtent == 0.0 ||
            configuration.configuration.totalItemCount == 0) {
          continue;
        }
        final alignment = configuration.nextDouble();
        const int maxOffsetsToJump = 5;
        final offsets = List.generate(
          maxOffsetsToJump,
          (_) {
            while (true) {
              final sliver = configuration
                  .nextInt(configuration.configuration.slivers.length);
              if (configuration.configuration.slivers[sliver].items.isEmpty) {
                continue;
              }
              return sliver;
            }
          },
        ).map((sliverIndex) {
          final sliver = configuration.configuration.slivers[sliverIndex];
          return (sliverIndex, configuration.nextInt(sliver.items.length));
        }).toList();
        await testConfiguration(
          configuration.configuration,
          layoutMode: configuration.layoutMode,
          offsets: offsets,
          alignment: alignment,
        );
        resetTestLog();
      }
    });
  });

  group("ListController", () {
    testWidgets("attach / detach", (tester) async {
      int attached = 0;
      int detached = 0;
      final controller = ListController(
        onAttached: () {
          ++attached;
        },
        onDetached: () {
          ++detached;
        },
      );
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration,
        listController: controller,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();
      expect(attached, 1);
      expect(detached, 0);
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(attached, 1);
      expect(detached, 1);
      expect(controller.isAttached, false);
    });
    testWidgets("replace widget", (tester) async {
      int attached = 0;
      int detached = 0;
      final controller = ListController(
        onAttached: () {
          ++attached;
        },
        onDetached: () {
          ++detached;
        },
      );
      final configuration1 = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration1,
        listController: controller,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();
      expect(attached, 1);
      expect(detached, 0);
      expect(controller.isAttached, isTrue);

      final configuration2 = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true, // different global key
      );

      await tester.pumpWidget(_buildSliverList(
        configuration2,
        listController: controller,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();

      expect(attached, 2);
      expect(detached, 1);
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(attached, 2);
      expect(detached, 2);
      expect(controller.isAttached, false);
    });
    testWidgets("remove widget mid animation", (tester) async {
      final scrollController = ScrollController();

      int attached = 0;
      int detached = 0;
      final controller = ListController(
        onAttached: () {
          ++attached;
        },
        onDetached: () {
          ++detached;
        },
      );
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration,
        listController: controller,
        preciseLayout: false,
        controller: scrollController,
      ));
      await tester.pumpAndSettle();
      expect(attached, 1);
      expect(detached, 0);
      expect(controller.isAttached, isTrue);

      controller.animateToItem(
        index: () => 10,
        scrollController: scrollController,
        alignment: 0.5,
        duration: (estimatedDistance) => const Duration(milliseconds: 1000),
        curve: (estimatedDistance) => Curves.linear,
      );

      await tester.pump(const Duration(milliseconds: 500));

      // will throw if there are any leaked Tickers
      await tester.pumpWidget(const SizedBox.shrink());
      expect(attached, 1);
      expect(detached, 1);
      expect(controller.isAttached, false);
    });
    testWidgets("replace controller", (tester) async {
      int attached1 = 0;
      int detached1 = 0;
      final controller1 = ListController(
        onAttached: () {
          ++attached1;
        },
        onDetached: () {
          ++detached1;
        },
      );
      final configuration = SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration,
        listController: controller1,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();
      expect(attached1, 1);
      expect(detached1, 0);
      expect(controller1.isAttached, isTrue);

      int attached2 = 0;
      int detached2 = 0;
      final controller2 = ListController(
        onAttached: () {
          ++attached2;
        },
        onDetached: () {
          ++detached2;
        },
      );

      await tester.pumpWidget(_buildSliverList(
        configuration,
        listController: controller2,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();

      expect(attached1, 1);
      expect(detached1, 1);
      expect(controller1.isAttached, isFalse);
      expect(attached2, 1);
      expect(detached2, 0);
      expect(controller2.isAttached, isTrue);
    });
  });
}

Widget _buildSliverListRenderWidgetChild(
    List<String> items, ScrollController controller) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: SizedBox(
          height: 500,
          child: CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              SuperSliverList(
                delegate: SliverChildListDelegate(
                  items.map<Widget>((String item) {
                    return Chip(
                      key: Key(item),
                      label: Text("Tile $item"),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildSliverList(
  SliverListConfiguration configuration, {
  required bool preciseLayout,
  ScrollController? controller,
  ListController? listController,
  bool shrinkWrap = false,
  ExtentEstimationProvider? extentEstimation,
  bool delayPopulatingCacheArea = true,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        color: Colors.blue,
        height: configuration.viewportHeight,
        child: CustomScrollView(
          shrinkWrap: shrinkWrap,
          physics: const ClampingScrollPhysics(),
          controller: controller,
          slivers: <Widget>[
            for (final (sliverIndex, sliver)
                in configuration.slivers.indexed) ...[
              if (sliver.pinnedHeaderHeight > 0)
                SliverPinnedHeader(
                  child: SizedBox(
                    height: sliver.pinnedHeaderHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text("PinnedHeader $sliverIndex"),
                    ),
                  ),
                ),
              SuperSliverList(
                key: sliver.key,
                extentPrecalculationPolicy: _SimpleExtentPrecalculatePolicy(
                  precalculate: preciseLayout,
                ),
                extentEstimation: extentEstimation,
                listController: listController ?? sliver.listController,
                delayPopulatingCacheArea: delayPopulatingCacheArea,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return SizedBox(
                      key: ValueKey<int>(sliver.items[i].value),
                      height: sliver.items[i].height,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: [
                              Colors.green,
                              Colors.yellow,
                              Colors.white
                            ][sliverIndex % 3],
                            width: 2,
                          ),
                        ),
                        child:
                            Text("Tile $sliverIndex:${sliver.items[i].value}"),
                      ),
                    );
                  },
                  findChildIndexCallback: (Key key) {
                    final ValueKey<int> valueKey = key as ValueKey<int>;
                    final int index = sliver.items
                        .indexWhere((v) => v.value == valueKey.value);
                    return index == -1 ? null : index;
                  },
                  childCount: sliver.items.length,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// This will scroll the view by step until reaching the end, ensuring that every render
/// object on screen is visually moving by the same amount.
/// This is to enforce that scroll offset correction does not cause visual jitter.
Future<void> _checkSmoothScrolling({
  required WidgetTester tester,
  required SliverListConfiguration configuration,
  required ScrollController controller,
  required double step,
}) async {
  List<RenderBox> allSliverBoxes() {
    final result = <RenderBox>[];
    for (final sliver in configuration.slivers) {
      final renderObject = sliver.key!.currentContext?.findRenderObject();
      if (renderObject is RenderSliverMultiBoxAdaptor) {
        var c = renderObject.firstChild;
        while (c != null) {
          result.add(c);
          c = renderObject.childAfter(c);
        }
      }
    }
    return result;
  }

  var previousBoxToFrame = <RenderBox, Rect>{};

  while (true) {
    final double scrollDelta;
    {
      final offset = (controller.offset + step).clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent);
      if (offset == controller.offset) {
        break;
      }
      scrollDelta = offset - controller.offset;
      controller.jumpTo(offset);
      await tester.pump();
    }

    final boxes = allSliverBoxes();
    final boxToFrame = <RenderBox, Rect>{};
    for (final box in boxes) {
      if (box.debugNeedsPaint) {
        continue;
      }
      final transform = box.getTransformTo(null);
      final globalRect = MatrixUtils.transformRect(transform, box.paintBounds);
      boxToFrame[box] = globalRect;
      final previousRect = previousBoxToFrame[box];
      if (previousRect != null) {
        final thisOffset = globalRect.top - previousRect.top;
        expect(thisOffset, roughlyEquals(-scrollDelta));
      }
    }
    previousBoxToFrame = boxToFrame;
  }
}
