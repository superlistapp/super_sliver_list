import "package:context_plus/context_plus.dart";
import "package:flutter/widgets.dart";
import "package:super_sliver_list/super_sliver_list.dart";

enum PrecomputeExtentPolicy {
  none,
  automatic,
  all,
}

extension DisplayName on PrecomputeExtentPolicy {
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class AppSettings {
  final showSliverList = ValueNotifier(true);
  final precomputeExtentPolicy = ValueNotifier(
    PrecomputeExtentPolicy.none,
  );
  late final ExtentPrecalculationPolicy extentPrecalculationPolicy;
  AppSettings() {
    extentPrecalculationPolicy = DefaultExtentPrecalculationPolicy(
      policy: precomputeExtentPolicy,
    );
  }
}

final appSettings = Ref<AppSettings>();

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
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) {
    final policy = this.policy.value;
    switch (policy) {
      case PrecomputeExtentPolicy.none:
        return false;
      case PrecomputeExtentPolicy.all:
        return true;
      case PrecomputeExtentPolicy.automatic:
        final contentDimensions = context.contentTotalExtent ?? 0;
        return context.numberOfItems < 100 ||
            contentDimensions < (context.viewportMainAxisExtent ?? 0) * 10;
    }
  }
}
