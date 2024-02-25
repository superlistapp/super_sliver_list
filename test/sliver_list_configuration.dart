import "dart:math" as math;

import "package:flutter/widgets.dart";
import "package:super_sliver_list/src/super_sliver_list.dart";

class SliverItem {
  final int value;
  final double height;

  SliverItem({
    required this.value,
    required this.height,
  });

  SliverItem copyWith({
    int? value,
    double? height,
  }) {
    return SliverItem(
      value: value ?? this.value,
      height: height ?? this.height,
    );
  }
}

class Sliver {
  final List<SliverItem> items;
  final GlobalKey? key;
  final ListController listController;
  final double pinnedHeaderHeight;

  // ignore: unused_element
  Sliver(
    this.items, {
    this.key,
    ListController? listController,
    required this.pinnedHeaderHeight,
  }) : listController = listController ?? ListController();

  Sliver copyWith({
    List<SliverItem>? items,
    GlobalKey? key,
    ListController? listController,
    double? pinnedHeaderHeight,
  }) {
    return Sliver(
      items ?? this.items,
      key: key ?? this.key,
      listController: listController ?? this.listController,
      pinnedHeaderHeight: pinnedHeaderHeight ?? this.pinnedHeaderHeight,
    );
  }

  double get height =>
      items.fold(0.0, (v, e) => v + e.height) + pinnedHeaderHeight;
}

class SliverListConfiguration {
  final List<Sliver> slivers;
  final double viewportHeight;

  SliverListConfiguration({
    required this.slivers,
    required this.viewportHeight,
  });

  SliverListConfiguration copyWith({
    List<Sliver>? slivers,
    double? viewportHeight,
  }) {
    return SliverListConfiguration(
      slivers: slivers ?? this.slivers,
      viewportHeight: viewportHeight ?? this.viewportHeight,
    );
  }

  static int _defaultItemValue(int sliver, int index) => index;
  static double _defaultPinnedHeaderHeight(int sliver) => 0;

  static SliverListConfiguration generate({
    int slivers = 1,
    required int Function(int sliver) itemsPerSliver,
    required double Function(int sliver, int index) itemHeight,
    required double viewportHeight,
    int Function(int sliver, int index) itemValue = _defaultItemValue,
    bool addGlobalKey = false,
    double Function(int sliver) pinnedHeaderHeight = _defaultPinnedHeaderHeight,
  }) {
    final List<Sliver> sliverList = [];
    for (int i = 0; i < slivers; ++i) {
      final List<SliverItem> items = [];
      final itemsCount = itemsPerSliver(i);
      for (int j = 0; j < itemsCount; ++j) {
        items.add(
          SliverItem(
            value: itemValue(i, j),
            height: itemHeight(i, j),
          ),
        );
      }
      sliverList.add(Sliver(
        items,
        key: addGlobalKey ? GlobalKey() : null,
        pinnedHeaderHeight: pinnedHeaderHeight(i),
      ));
    }
    return SliverListConfiguration(
      slivers: sliverList,
      viewportHeight: viewportHeight,
    );
  }

  static const kItemHeightInitial = 100;

  double get bottomScrollOffsetInitial {
    double initialHeight = 0;
    for (final sliver in slivers) {
      initialHeight +=
          sliver.items.length * kItemHeightInitial + sliver.pinnedHeaderHeight;
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

  int get totalItemCount {
    int count = 0;
    for (final sliver in slivers) {
      count += sliver.items.length;
    }
    return count;
  }

  double get maxItemHeight {
    double max = 0;
    for (final sliver in slivers) {
      for (final item in sliver.items) {
        max = math.max(max, item.height);
      }
    }
    return max;
  }

  double get maxScrollExtent => math.max(totalExtent - viewportHeight, 0);
}
