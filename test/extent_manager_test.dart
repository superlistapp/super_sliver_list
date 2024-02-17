import "dart:ui";

import "package:super_sliver_list/src/extent_manager.dart";
import "package:test/test.dart";

class _TestExtentManagerDelegate extends ExtentManagerDelegate {
  const _TestExtentManagerDelegate();

  @override
  double estimateExtentForItem(int index) {
    return 100;
  }

  @override
  double getOffsetToReveal(
    int index,
    double alignment, {
    required bool estimationOnly,
    Rect? rect,
  }) {
    return 0;
  }

  @override
  void onMarkNeedsLayout() {}
}

void main() {
  group("ExtentList", () {
    test("indexForOffset", () {
      final extentManager =
          ExtentManager(delegate: const _TestExtentManagerDelegate());
      expect(extentManager.indexForOffset(0), equals(null));
      expect(extentManager.indexForOffset(100), equals(null));

      extentManager.resize(3);
      extentManager.setExtent(0, 50);
      extentManager.setExtent(1, 70);
      extentManager.setExtent(2, 80);

      expect(extentManager.indexForOffset(0), equals(0));
      expect(extentManager.indexForOffset(49), equals(0));
      expect(extentManager.indexForOffset(50), equals(1));
      expect(extentManager.indexForOffset(119), equals(1));
      expect(extentManager.indexForOffset(120), equals(2));
      expect(extentManager.indexForOffset(500), equals(null));
    });
    test("offsetForIndex", () {
      final extentManager =
          ExtentManager(delegate: const _TestExtentManagerDelegate());

      extentManager.resize(3);
      extentManager.setExtent(0, 50);
      extentManager.setExtent(1, 70);
      extentManager.setExtent(2, 80);

      expect(extentManager.offsetForIndex(0), equals(0));
      expect(extentManager.offsetForIndex(1), equals(50));
      expect(extentManager.offsetForIndex(2), equals(120));
    });
  });
}
