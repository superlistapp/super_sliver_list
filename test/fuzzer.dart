import "dart:math" as math;

import "package:logging/logging.dart";

import "sliver_list_configuration.dart";

final _log = Logger("super_sliver_list_test");

enum LayoutMode {
  /// Wait until entire layout is complete before doing the test.
  preciseWaitUntilComplete,

  /// Run the test while layout is still in progress. Extent precalculation
  /// and testing will run in parallel.
  preciseNoWait,

  /// No extent precalculation.
  estimated,
}

abstract class TestConfiguration {
  SliverListConfiguration get configuration;
  LayoutMode get layoutMode;

  int nextInt(int max);
  double nextDouble();
}

abstract class TestConfigurationProvider {
  Iterable<TestConfiguration> nextConfiguration();

  static TestConfigurationProvider createDefaultProvider() {
    return FuzzConfigurationProvider();
  }
}

class _FuzzerConfiguration {
  final int seed;
  final int maxSlivers;
  final int maxItemsPerSliver;
  final int maxItemHeight;
  final int? minItemHeight;
  final double viewportHeight;
  final int maxPinnedHeaderHeight;

  _FuzzerConfiguration({
    required this.seed,
    required this.maxSlivers,
    required this.maxItemsPerSliver,
    required this.maxItemHeight,
    required this.viewportHeight,
    this.minItemHeight = 1,
    this.maxPinnedHeaderHeight = 0,
  });

  double nextItemHeight(math.Random random) {
    return random.nextInt(maxItemHeight + 1 - (minItemHeight ?? 0)).toDouble() +
        (minItemHeight ?? 0);
  }

  double nextPinnedHeaderHeight(math.Random random) {
    return maxPinnedHeaderHeight > 0
        ? random.nextInt(maxPinnedHeaderHeight + 1).toDouble()
        : 0;
  }
}

class _TestConfigurations extends TestConfiguration {
  _TestConfigurations({
    required this.configuration,
    required this.layoutMode,
    required this.random,
  });

  @override
  final SliverListConfiguration configuration;

  @override
  final LayoutMode layoutMode;
  final math.Random random;

  @override
  double nextDouble() {
    return random.nextDouble();
  }

  @override
  int nextInt(int max) {
    return random.nextInt(max);
  }
}

class FuzzConfigurationProvider extends TestConfigurationProvider {
  FuzzConfigurationProvider();

  static const int _maxIterations = 100;
  static const int _customerTestMaxIterations = 5;

  @override
  Iterable<TestConfiguration> nextConfiguration() sync* {
    const isCustomerTest = bool.fromEnvironment("flutter_customer_test");
    const iterations =
        isCustomerTest ? _customerTestMaxIterations : _maxIterations;
    for (final (fcIndex, fc) in _testConfigurations.indexed) {
      final seedRandom = math.Random(fc.seed);
      for (int i = 0; i < iterations; ++i) {
        final seed = seedRandom.nextInt(0xFFFFFFFF);
        next_seed:
        for (final layoutMode in LayoutMode.values) {
          _log.info(
            "Returning configuration ($fcIndex:$i:${layoutMode.name}) with seed $seed",
          );
          final r = math.Random(seed);
          final configuration = SliverListConfiguration.generate(
            slivers: r.nextInt(fc.maxSlivers + 1),
            itemsPerSliver: (_) => r.nextInt(fc.maxItemsPerSliver + 1),
            itemHeight: (_, index) => fc.nextItemHeight(r),
            viewportHeight: fc.viewportHeight,
            addGlobalKey: true,
            pinnedHeaderHeight: (_) => fc.nextPinnedHeaderHeight(r),
          );
          if (configuration.totalItemCount == 0) {
            --i;
            break next_seed;
          }
          yield _TestConfigurations(
            configuration: configuration,
            layoutMode: layoutMode,
            random: r,
          );
        }
      }
    }
  }
}

final List<_FuzzerConfiguration> _testConfigurations = [
  _FuzzerConfiguration(
    maxSlivers: 2,
    seed: 256,
    maxItemsPerSliver: 10,
    maxItemHeight: 700,
    viewportHeight: 500,
    maxPinnedHeaderHeight: 40,
  ),
  _FuzzerConfiguration(
    maxSlivers: 2,
    seed: 256,
    maxItemsPerSliver: 100,
    maxItemHeight: 700,
    viewportHeight: 500,
    maxPinnedHeaderHeight: 50,
  ),
  _FuzzerConfiguration(
    maxSlivers: 10,
    seed: 256,
    maxItemsPerSliver: 30,
    maxItemHeight: 700,
    viewportHeight: 500,
    maxPinnedHeaderHeight: 50,
  ),
  _FuzzerConfiguration(
    maxSlivers: 20,
    seed: 256,
    maxItemsPerSliver: 30,
    maxItemHeight: 300,
    minItemHeight: 1,
    viewportHeight: 500,
    maxPinnedHeaderHeight: 30,
  ),
  _FuzzerConfiguration(
    // TODO: Increase once RenderViewport tracks scroll offset corrections per sliver.
    maxSlivers: 12,
    seed: 256,
    maxItemsPerSliver: 2,
    maxItemHeight: 500,
    minItemHeight: 50,
    viewportHeight: 500,
    maxPinnedHeaderHeight: 20,
  )
];
