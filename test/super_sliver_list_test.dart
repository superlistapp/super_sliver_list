import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";
import "package:logging/logging.dart";
import "package:super_sliver_list/super_sliver_list.dart";

// ignore: deprecated_member_use
import "package:test_api/src/backend/invoker.dart" as invoker;

import "test_logger.dart";

Matcher roughlyEquals(double value) {
  return closeTo(value, precisionErrorTolerance);
}

final _log = Logger("magic_sliver_list_test");

enum _LayoutMode {
  /// Wait until entire layout is complete before doing the test.
  preciseWaitUntilComplete,

  /// Run the test while layout is still in progress. Extent precalculation
  /// and testing will run in parallel.
  preciseNoWait,

  /// No extent precalculation.
  estimated,
}

class _SimpleExtentPrecalculatePolicy extends ExtentPrecalculationPolicy {
  final bool precalculate;

  _SimpleExtentPrecalculatePolicy({required this.precalculate});

  @override
  bool shouldPrecaculateExtents(_) => precalculate;
}

class _FuzzerConfiguration {
  final int iterations;
  final int seed;
  final int maxSlivers;
  final int maxItemsPerSliver;
  final int maxItemHeight;
  final int? minItemHeight;
  final double viewportHeight;

  _FuzzerConfiguration({
    required this.iterations,
    required this.seed,
    required this.maxSlivers,
    required this.maxItemsPerSliver,
    required this.maxItemHeight,
    required this.viewportHeight,
    this.minItemHeight = 1,
  });

  double nextItemHeight(math.Random random) {
    return random.nextInt(maxItemHeight - (minItemHeight ?? 0)).toDouble() +
        (minItemHeight ?? 0);
  }

  static const int _kFuzzerIterations = 100;

  static final List<_FuzzerConfiguration> testConfigurations = [
    _FuzzerConfiguration(
      iterations: _kFuzzerIterations,
      maxSlivers: 2,
      seed: 256,
      maxItemsPerSliver: 10,
      maxItemHeight: 700,
      viewportHeight: 500,
    ),
    _FuzzerConfiguration(
      iterations: _kFuzzerIterations,
      maxSlivers: 2,
      seed: 256,
      maxItemsPerSliver: 100,
      maxItemHeight: 700,
      viewportHeight: 500,
    ),
    _FuzzerConfiguration(
      iterations: _kFuzzerIterations,
      maxSlivers: 10,
      seed: 256,
      maxItemsPerSliver: 30,
      maxItemHeight: 700,
      viewportHeight: 500,
    ),
    _FuzzerConfiguration(
      iterations: _kFuzzerIterations,
      maxSlivers: 20,
      seed: 256,
      maxItemsPerSliver: 30,
      maxItemHeight: 300,
      minItemHeight: 1,
      viewportHeight: 500,
    ),
    _FuzzerConfiguration(
      iterations: _kFuzzerIterations,
      maxSlivers: 30,
      seed: 256,
      maxItemsPerSliver: 1,
      maxItemHeight: 500,
      minItemHeight: 1,
      viewportHeight: 500,
    )
  ];
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

  group("SliverList", () {
    testWidgets("reverse children (with keys)", (tester) async {
      final configuration = _SliverListConfiguration.generate(
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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);

      final reversed = configuration.copyWith(
        slivers: [
          _Sliver(
            configuration.slivers.first.items.reversed.toList(),
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
      expect(find.text("Tile 19"), findsNothing);
      expect(find.text("Tile 18"), findsNothing);
      expect(find.text("Tile 1"), findsOneWidget);
      expect(find.text("Tile 0"), findsOneWidget);

      controller.jumpTo(0.0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);
      expect(find.text("Tile 19"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 0"), findsNothing);
    });

    testWidgets("replace children (with keys)", (tester) async {
      final configuration = _SliverListConfiguration.generate(
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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);

      final configuration2 = _SliverListConfiguration.generate(
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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 18"), findsNothing);
      expect(find.text("Tile 19"), findsNothing);

      expect(find.text("Tile 100"), findsNothing);
      expect(find.text("Tile 101"), findsNothing);
      expect(find.text("Tile 118"), findsOneWidget);
      expect(find.text("Tile 119"), findsOneWidget);

      controller.jumpTo(0.0);
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
      expect(find.text("Tile 100"), findsOneWidget);
      expect(find.text("Tile 101"), findsOneWidget);
      expect(find.text("Tile 118"), findsNothing);
      expect(find.text("Tile 119"), findsNothing);
    });

    testWidgets("replace with shorter children list (with keys)",
        (tester) async {
      final configuration = _SliverListConfiguration.generate(
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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 17"), findsNothing);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);

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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 1"), findsNothing);
      expect(find.text("Tile 17"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsNothing);
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

      final configuration = _SliverListConfiguration.generate(
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

      await tester.drag(find.text("Tile 2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, 800.0);
      expect(find.text("Tile 15"), findsNothing);
      expect(find.text("Tile 16"), findsOneWidget);
      expect(find.text("Tile 17"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);

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
      expect(find.text("Tile 14"), findsNothing);
      expect(find.text("Tile 15"), findsOneWidget);
      expect(find.text("Tile 16"), findsOneWidget);
      expect(find.text("Tile 17"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsNothing);

      // Drags back to beginning and newly added item is visible.
      await tester.drag(find.text("Tile 16"), const Offset(0.0, 1000.0));
      await tester.pumpAndSettle();
      expect(controller.offset, 0.0);
      expect(find.text("Tile -1"), findsOneWidget);
      expect(find.text("Tile 0"), findsOneWidget);
      expect(find.text("Tile 1"), findsOneWidget);
      expect(find.text("Tile 2"), findsOneWidget);
      expect(find.text("Tile 3"), findsNothing);
    });

    testWidgets("should recalculate inaccurate layout offset case 2",
        (tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/42142.
      final configuration = _SliverListConfiguration.generate(
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

      await tester.drag(find.text("Tile 2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, roughlyEquals(805.0));
      expect(find.text("Tile 15"), findsNothing);
      expect(find.text("Tile 16"), findsOneWidget);
      expect(find.text("Tile 17"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);

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
      expect(find.text("Tile 14"), findsNothing);
      expect(find.text("Tile 15"), findsNothing);
      expect(find.text("Tile 16"), findsOneWidget);
      expect(find.text("Tile 17"), findsOneWidget);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 3"), findsOneWidget);
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
                              child: Text("Tile $i"),
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
      await tester.drag(find.text("Tile 2"), const Offset(0.0, -1000.0));
      await tester.pumpAndSettle();

      // Viewport should be scrolled to the end of list.
      expect(controller.offset, roughlyEquals(900.0));
      expect(find.text("Tile 17"), findsNothing);
      expect(find.text("Tile 18"), findsOneWidget);
      expect(find.text("Tile 19"), findsOneWidget);
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
      expect(find.text("Tile 0"), findsNothing);
      expect(find.text("Tile 19"), findsNothing);
      expect(find.byKey(const Key("key0")), findsOneWidget);
      expect(find.byKey(const Key("key1")), findsOneWidget);
    });

    testWidgets("initially empty list", (tester) async {
      await tester.pumpWidget(
        _buildSliverList(
          _SliverListConfiguration.generate(
            itemsPerSliver: (_) => 0,
            itemHeight: (_, __) => 100,
            viewportHeight: 500,
          ),
          preciseLayout: false,
        ),
      );
      await tester.pumpWidget(
        _buildSliverList(
          _SliverListConfiguration.generate(
            itemsPerSliver: (_) => 10,
            itemHeight: (_, __) => 100,
            viewportHeight: 500,
          ),
          preciseLayout: false,
        ),
      );
      // Failing this likely means the child manager is not aware of underflow.
      expect(find.text("Tile 0"), findsOneWidget);
    });
    testWidgets("delay populating cache area enabled", (tester) async {
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
                    delayPopulatingCacheArea: true,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SizedBox(
                          key: keys[index],
                          height: 100,
                          child: Text("Tile $index"),
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

      // All items replaced, cache area should not be populated
      controller.jumpTo(2000);
      await tester.pump();

      // Items removed
      expect(keys[0].currentContext, isNull);
      expect(keys[6].currentContext, isNull);
      // Visible content
      expect(keys[20].currentContext, isNotNull);
      expect(keys[24].currentContext, isNotNull);
      // Cache area
      expect(keys[19].currentContext, isNull);
      expect(keys[25].currentContext, isNull);

      await tester.pump();
      // Cache area should now be populated
      expect(keys[19].currentContext, isNotNull);
      expect(keys[25].currentContext, isNotNull);

      controller.dispose();
    });
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
                        child: Text("Tile $index"),
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
  group("Fuzzer", () {
    testWidgets("layout multiple slivers scrolling down", (tester) async {
      Future<void> testConfiguration(
        _SliverListConfiguration configuration, {
        required _LayoutMode layoutMode,
      }) async {
        final ScrollController controller =
            ScrollController(initialScrollOffset: 0);

        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != _LayoutMode.estimated,
        ));

        if (layoutMode == _LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }

        await _checkSmoothScrolling(
          tester: tester,
          configuration: configuration,
          controller: controller,
          step: 100.0,
        );

        // Ensure all items have been laid out.
        expect(
          controller.position.maxScrollExtent,
          roughlyEquals(configuration.maxScrollExtent),
        );

        controller.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      for (final _FuzzerConfiguration fc
          in _FuzzerConfiguration.testConfigurations) {
        final seedRandom = math.Random(fc.seed);
        for (int i = 0; i < fc.iterations; ++i) {
          final seed = seedRandom.nextInt(0xFFFFFFFF);
          resetTestLog();
          _log.info("Starting test $i with seed $seed");
          final r = math.Random(seed);
          final configuration = _SliverListConfiguration.generate(
            slivers: r.nextInt(fc.maxSlivers),
            itemsPerSliver: (_) => r.nextInt(fc.maxItemsPerSliver),
            itemHeight: (_, index) => fc.nextItemHeight(r),
            viewportHeight: fc.viewportHeight,
            addGlobalKey: true,
          );
          if (configuration.totalExtent == 0) {
            continue;
          }
          for (final layoutMode in _LayoutMode.values) {
            await testConfiguration(configuration, layoutMode: layoutMode);
          }
        }
      }
    });

    testWidgets("layout multiple slivers scrolling up", (tester) async {
      Future<void> testConfiguration(
        _SliverListConfiguration configuration, {
        required _LayoutMode layoutMode,
      }) async {
        final ScrollController controller = ScrollController(
            initialScrollOffset: configuration.bottomScrollOffsetInitial);

        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != _LayoutMode.estimated,
        ));
        if (layoutMode == _LayoutMode.preciseNoWait) {
          await tester.pump();
        } else {
          final frameCount = await tester.pumpAndSettle();
          if (layoutMode == _LayoutMode.estimated) {
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
          step: -100.0,
        );

        // Ensure all items have been laid out.
        expect(
          controller.position.maxScrollExtent,
          roughlyEquals(configuration.maxScrollExtent),
        );

        controller.dispose();

        await tester.pumpWidget(const SizedBox.shrink());
      }

      for (final _FuzzerConfiguration fc
          in _FuzzerConfiguration.testConfigurations) {
        final seedRandom = math.Random(fc.seed);
        for (int i = 0; i < fc.iterations; ++i) {
          final seed = seedRandom.nextInt(0xFFFFFFFF);
          resetTestLog();
          _log.info("Starting test $i with seed $seed");
          final r = math.Random(seed);
          final configuration = _SliverListConfiguration.generate(
            slivers: r.nextInt(fc.maxSlivers),
            itemsPerSliver: (_) => r.nextInt(fc.maxItemsPerSliver),
            itemHeight: (_, index) => fc.nextItemHeight(r),
            viewportHeight: fc.viewportHeight,
            addGlobalKey: true,
          );
          if (configuration.totalExtent == 0) {
            continue;
          }
          for (final layoutMode in _LayoutMode.values) {
            await testConfiguration(configuration, layoutMode: layoutMode);
          }
        }
      }
    });
    testWidgets("jump to bottom", (tester) async {
      Future<void> testConfiguration(_SliverListConfiguration configuration,
          {required _LayoutMode layoutMode}) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != _LayoutMode.estimated,
        ));
        if (layoutMode == _LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }
        final lastSliver = configuration.slivers.last;
        final offset = lastSliver.extentController.getOffsetToReveal(
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

      for (final _FuzzerConfiguration fc
          in _FuzzerConfiguration.testConfigurations) {
        final seedRandom = math.Random(fc.seed);
        for (int i = 0; i < fc.iterations; ++i) {
          final seed = seedRandom.nextInt(0xFFFFFFFF);

          resetTestLog();
          _log.info("Starting test $i with seed $seed");
          final r = math.Random(seed);
          final configuration = _SliverListConfiguration.generate(
            slivers: r.nextInt(fc.maxSlivers),
            itemsPerSliver: (_) => math.max(r.nextInt(fc.maxItemsPerSliver), 1),
            itemHeight: (_, index) => fc.nextItemHeight(r),
            viewportHeight: fc.viewportHeight,
            addGlobalKey: true,
          );
          if (configuration.totalExtent == 0) {
            continue;
          }
          for (final mode in _LayoutMode.values) {
            await testConfiguration(configuration, layoutMode: mode);
          }
        }
      }
    });
    testWidgets("jump to offset", (tester) async {
      Future<void> testConfiguration(
        _SliverListConfiguration configuration, {
        required _LayoutMode layoutMode,
        required List<(int, int)> offsets,
        required double alignment,
        required _FuzzerConfiguration fuzzerConfiguration,
      }) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(_buildSliverList(
          configuration,
          controller: controller,
          preciseLayout: layoutMode != _LayoutMode.estimated,
        ));
        expect(controller.position.pixels, 0);
        if (layoutMode == _LayoutMode.preciseWaitUntilComplete) {
          await tester.pumpAndSettle();
        }
        for (final (sliverIndex, itemIndex) in offsets) {
          final sliver = configuration.slivers[sliverIndex];
          final item = sliver.items[itemIndex];
          final offset = sliver.extentController.getOffsetToReveal(
            itemIndex,
            alignment,
          );
          if (offset >= 0) {
            final overscroll = offset > controller.position.maxScrollExtent;

            _log.info("Jumping to offset $offset");
            controller.jumpTo(offset);
            await tester.pump();

            final widget = find.text("Tile ${item.value}");
            expect(widget, findsOneWidget);
            final RenderBox box = tester.renderObject(widget);
            final viewport = tester.renderObject(find.byType(Viewport));
            final transform = box.getTransformTo(viewport);
            final position = MatrixUtils.transformPoint(transform, Offset.zero);

            // If item height is less than viewport it must not start above the top.
            if (fuzzerConfiguration.maxItemHeight <=
                fuzzerConfiguration.viewportHeight) {
              expect(position.dy >= 0, isTrue);
            }

            // When out of bounds we have at least checked that the item is present
            // but the position is not guaranteed.
            if (!overscroll &&
                controller.position.pixels <
                    controller.position.maxScrollExtent) {
              final expectedTop =
                  (configuration.viewportHeight - item.height) * alignment;
              expect(position.dy, roughlyEquals(expectedTop));
            }
          } else {
            _log.info("Skipping jump to offset $offset");
          }
        }

        controller.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }

      for (final _FuzzerConfiguration fc
          in _FuzzerConfiguration.testConfigurations) {
        final seedRandom = math.Random(fc.seed);
        for (int i = 0; i < fc.iterations; ++i) {
          final seed = seedRandom.nextInt(0xFFFFFFFF);
          final r = math.Random(seed);
          final configuration = _SliverListConfiguration.generate(
            slivers: fc.maxSlivers,
            itemsPerSliver: (_) => math.max(r.nextInt(fc.maxItemsPerSliver), 1),
            itemHeight: (_, index) => fc.nextItemHeight(r),
            itemValue: (sliver, index) => sliver * 1000 + index,
            viewportHeight: fc.viewportHeight,
            addGlobalKey: true,
          );
          if (configuration.totalExtent == 0) {
            continue;
          }

          final alignment = r.nextDouble();
          const int maxOffsetsToJump = 5;
          final offsets = List.generate(
            maxOffsetsToJump,
            (_) => r.nextInt(configuration.slivers.length),
          ).map((sliverIndex) {
            final sliver = configuration.slivers[sliverIndex];
            return (sliverIndex, r.nextInt(sliver.items.length));
          }).toList();

          for (final mode in _LayoutMode.values) {
            resetTestLog();
            _log.info("\n\nStarting test $i with seed $seed layoutMode $mode");
            await testConfiguration(
              configuration,
              layoutMode: mode,
              offsets: offsets,
              alignment: alignment,
              fuzzerConfiguration: fc,
            );
          }
        }
      }
    });
  });

  group("ExtentController", () {
    testWidgets("attach / detach", (tester) async {
      int attached = 0;
      int detached = 0;
      final controller = ExtentController(
        onAttached: () {
          ++attached;
        },
        onDetached: () {
          ++detached;
        },
      );
      final configuration = _SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration,
        extentController: controller,
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
      final controller = ExtentController(
        onAttached: () {
          ++attached;
        },
        onDetached: () {
          ++detached;
        },
      );
      final configuration1 = _SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration1,
        extentController: controller,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();
      expect(attached, 1);
      expect(detached, 0);
      expect(controller.isAttached, isTrue);

      final configuration2 = _SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true, // different global key
      );

      await tester.pumpWidget(_buildSliverList(
        configuration2,
        extentController: controller,
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
    testWidgets("replace controller", (tester) async {
      int attached1 = 0;
      int detached1 = 0;
      final controller1 = ExtentController(
        onAttached: () {
          ++attached1;
        },
        onDetached: () {
          ++detached1;
        },
      );
      final configuration = _SliverListConfiguration.generate(
        slivers: 1,
        itemsPerSliver: (_) => 20,
        itemHeight: (_, __) => 300,
        viewportHeight: 500,
        addGlobalKey: true,
      );
      await tester.pumpWidget(_buildSliverList(
        configuration,
        extentController: controller1,
        preciseLayout: false,
      ));
      await tester.pumpAndSettle();
      expect(attached1, 1);
      expect(detached1, 0);
      expect(controller1.isAttached, isTrue);

      int attached2 = 0;
      int detached2 = 0;
      final controller2 = ExtentController(
        onAttached: () {
          ++attached2;
        },
        onDetached: () {
          ++detached2;
        },
      );

      await tester.pumpWidget(_buildSliverList(
        configuration,
        extentController: controller2,
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

class _SliverItem {
  final int value;
  final double height;

  _SliverItem({
    required this.value,
    required this.height,
  });

  _SliverItem copyWith({
    int? value,
    double? height,
  }) {
    return _SliverItem(
      value: value ?? this.value,
      height: height ?? this.height,
    );
  }
}

class _Sliver {
  final List<_SliverItem> items;
  final GlobalKey? key;
  final ExtentController extentController;

  // ignore: unused_element
  _Sliver(
    this.items, {
    this.key,
    ExtentController? extentController,
  }) : extentController = extentController ?? ExtentController();

  _Sliver copyWith({
    List<_SliverItem>? items,
    GlobalKey? key,
    ExtentController? extentController,
  }) {
    return _Sliver(
      items ?? this.items,
      key: key ?? this.key,
      extentController: extentController ?? this.extentController,
    );
  }

  double get height => items.fold(0.0, (v, e) => v + e.height);
}

class _SliverListConfiguration {
  final List<_Sliver> slivers;
  final double viewportHeight;

  _SliverListConfiguration({
    required this.slivers,
    required this.viewportHeight,
  });

  _SliverListConfiguration copyWith({
    List<_Sliver>? slivers,
    double? viewportHeight,
  }) {
    return _SliverListConfiguration(
      slivers: slivers ?? this.slivers,
      viewportHeight: viewportHeight ?? this.viewportHeight,
    );
  }

  static int _defaultItemValue(int sliver, int index) => index;

  static _SliverListConfiguration generate({
    int slivers = 1,
    required int Function(int sliver) itemsPerSliver,
    required double Function(int sliver, int index) itemHeight,
    required double viewportHeight,
    int Function(int sliver, int index) itemValue = _defaultItemValue,
    bool addGlobalKey = false,
  }) {
    final List<_Sliver> sliverList = [];
    for (int i = 0; i < slivers; ++i) {
      final List<_SliverItem> items = [];
      final itemsCount = itemsPerSliver(i);
      for (int j = 0; j < itemsCount; ++j) {
        items.add(
          _SliverItem(
            value: itemValue(i, j),
            height: itemHeight(i, j),
          ),
        );
      }
      sliverList.add(_Sliver(
        items,
        key: addGlobalKey ? GlobalKey() : null,
      ));
    }
    return _SliverListConfiguration(
      slivers: sliverList,
      viewportHeight: viewportHeight,
    );
  }

  static const kItemHeightInitial = 100;

  double get bottomScrollOffsetInitial {
    double initialHeight = 0;
    for (final sliver in slivers) {
      initialHeight += sliver.items.length * kItemHeightInitial;
    }
    return math.max(initialHeight - viewportHeight, 0);
  }

  double get totalExtent {
    double height = 0;
    for (final sliver in slivers) {
      height += sliver.height;
    }
    return height;
  }

  double get maxScrollExtent => math.max(totalExtent - viewportHeight, 0);
}

Widget _buildSliverList(
  _SliverListConfiguration configuration, {
  required bool preciseLayout,
  ScrollController? controller,
  ExtentController? extentController,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(
        height: configuration.viewportHeight,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          controller: controller,
          slivers: <Widget>[
            for (final sliver in configuration.slivers)
              SuperSliverList(
                key: sliver.key,
                extentPrecalculationPolicy: _SimpleExtentPrecalculatePolicy(
                  precalculate: preciseLayout,
                ),
                extentController: extentController ?? sliver.extentController,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) {
                    return SizedBox(
                      key: ValueKey<int>(sliver.items[i].value),
                      height: sliver.items[i].height,
                      child: Text("Tile ${sliver.items[i].value}"),
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
  required _SliverListConfiguration configuration,
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
