import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

enum PrecomputeExtentPolicy {
  none,
  all,
  automatic,
}

class AppSettings {
  final showSliverList = ValueNotifier(true);
  final precomputeExtentPolicy = ValueNotifier(
    PrecomputeExtentPolicy.automatic,
  );
  late final ExtentPrecalculationPolicy extentPrecalculationPolicy;
  AppSettings() {
    extentPrecalculationPolicy = DefaultExtentPrecalculationPolicy(
      policy: precomputeExtentPolicy,
    );
  }
}

class DefaultExtentPrecalculationPolicy extends ExtentPrecalculationPolicy {
  final ValueNotifier<PrecomputeExtentPolicy> policy;

  DefaultExtentPrecalculationPolicy({required this.policy});

  @override
  void onAttached() {
    super.onAttached();
    policy.addListener(valueDidChange);
  }

  @override
  void onDetached() {
    super.onDetached();
    policy.removeListener(valueDidChange);
  }

  @override
  bool shouldPrecaculateExtents(ExtentPrecalculationContext context) {
    final policy = this.policy.value;
    switch (policy) {
      case PrecomputeExtentPolicy.none:
        return false;
      case PrecomputeExtentPolicy.all:
        return true;
      case PrecomputeExtentPolicy.automatic:
        final contentDimensions = context.contentTotalExtent ?? 0;
        return context.numberOfItem < 100 ||
            contentDimensions < context.viewportMainAxisExtent * 10;
    }
  }
}
