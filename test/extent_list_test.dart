import "package:super_sliver_list/src/extent_list.dart";
import "package:test/test.dart";

void main() {
  group("ResizableFloat64List", () {
    test("operations", () {
      final test = ResizableFloat64List();
      expect(test.length, equals(0));

      test.resize(4, (i) => i * 10.0);
      expect(test.length, equals(4));
      expect(test[0], equals(0.0));
      expect(test[1], equals(10.0));
      expect(test[2], equals(20.0));
      expect(test[3], equals(30.0));

      test.insert(2, 100);
      expect(test.length, equals(5));
      expect(test[0], equals(0.0));
      expect(test[1], equals(10.0));
      expect(test[2], equals(100.0));
      expect(test[3], equals(20.0));
      expect(test[4], equals(30.0));

      test.removeAt(2);
      expect(test.length, equals(4));
      expect(test[0], equals(0.0));
      expect(test[1], equals(10.0));
      expect(test[2], equals(20.0));
      expect(test[3], equals(30.0));

      // Inserting at the end
      test.insert(4, 100);
      expect(test.length, equals(5));
      expect(test[3], equals(30.0));
      expect(test[4], equals(100.0));

      // Removing at the end
      test.removeAt(4);
      expect(test.length, equals(4));
      expect(test[3], equals(30.0));
    });
    test("resize", () {
      final list = ResizableFloat64List();
      list.resize(300, (index) => 10);
      expect(list.length, equals(300));
      expect(list[0], equals(10));
      expect(list[299], equals(10));
    });
    test("resizeWithDefault", () {
      final list = ResizableFloat64List();
      list.resizeWithDefault(300, 10);
      expect(list.length, equals(300));
      expect(list[0], equals(10));
      expect(list[299], equals(10));
    });
  });
  group("ExtentList", () {
    test("empty", () {
      final extentList = ExtentList();
      expect(extentList.totalExtent, equals(0.0));
      expect(extentList.cleanRangeStart, isNull);
      expect(extentList.cleanRangeEnd, isNull);
      expect(extentList.hasDirtyItems, isFalse);
      expect(extentList.dirtyItemCount, 0.0);
    });
    test("resize", () {
      final extentList = ExtentList();

      extentList.resize(3, (_) => 100.0);
      expect(extentList.totalExtent, equals(300));
      expect(extentList.hasDirtyItems, isTrue);

      extentList.setExtent(0, 50);
      expect(extentList.totalExtent, equals(250));

      extentList.setExtent(1, 50);
      extentList.setExtent(2, 50);
      expect(extentList.hasDirtyItems, isFalse);

      extentList.resize(2, (_) => 100.0);
      expect(extentList.hasDirtyItems, isFalse);
      expect(extentList.totalExtent, equals(100));

      extentList.resize(4, (i) => i == null ? 0 : 150.0);
      expect(extentList.hasDirtyItems, isTrue);
      expect(extentList.totalExtent, equals(400));

      extentList.setExtent(2, 70);
      extentList.setExtent(3, 80);
      expect(extentList.hasDirtyItems, isFalse);
      expect(extentList.totalExtent, equals(100 + 70 + 80));

      extentList.resize(100, (index) => 50);
      expect(extentList.totalExtent, equals(5050));
      expect(extentList.dirtyItemCount, 96);

      extentList.resize(10, (index) => 50);
      expect(extentList.totalExtent, equals(550));
      expect(extentList.dirtyItemCount, 6);
    });
    test("cleanRange", () {
      final extentList = ExtentList();

      extentList.resize(10, (_) => 100.0);
      expect(extentList.cleanRangeStart, isNull);
      expect(extentList.cleanRangeEnd, isNull);

      extentList.setExtent(5, 50);
      expect(extentList.cleanRangeStart, equals(5));
      expect(extentList.cleanRangeEnd, equals(5));

      // non continuous
      extentList.setExtent(3, 50);
      expect(extentList.cleanRangeStart, equals(3));
      expect(extentList.cleanRangeEnd, equals(3));

      // non continuous
      extentList.setExtent(7, 50);
      expect(extentList.cleanRangeStart, equals(7));
      expect(extentList.cleanRangeEnd, equals(7));

      // fill in the gap - should extend the range
      extentList.setExtent(4, 50);
      expect(extentList.cleanRangeStart, equals(3));
      expect(extentList.cleanRangeEnd, equals(5));

      extentList.setExtent(6, 50);
      expect(extentList.cleanRangeStart, equals(3));
      expect(extentList.cleanRangeEnd, equals(7));

      extentList.resize(5, (_) => 100.0);
      expect(extentList.cleanRangeStart, equals(3));
      expect(extentList.cleanRangeEnd, equals(4));

      extentList.resize(3, (_) => 100.0);
      expect(extentList.cleanRangeStart, isNull);
      expect(extentList.cleanRangeEnd, isNull);
    });
    test("cleanRange reset", () {
      final extentList = ExtentList();

      extentList.resize(4, (_) => 100.0);
      for (int i = 0; i < 4; ++i) {
        extentList.setExtent(i, 50);
      }
      expect(extentList.cleanRangeStart, equals(0));
      expect(extentList.cleanRangeEnd, equals(3));
      expect(extentList.hasDirtyItems, isFalse);

      extentList.markAllDirty();

      expect(extentList.cleanRangeStart, isNull);
      expect(extentList.cleanRangeEnd, isNull);
      expect(extentList.hasDirtyItems, isTrue);
    });
    test("cleanRange after markDirty", () {
      final extentList = ExtentList();

      extentList.resize(4, (_) => 100.0);
      for (int i = 0; i < 4; ++i) {
        extentList.setExtent(i, 50);
      }
      expect(extentList.cleanRangeStart, equals(0));
      expect(extentList.cleanRangeEnd, equals(3));
      expect(extentList.hasDirtyItems, isFalse);

      extentList.markDirty(2);
      // whole clean range was reset.
      expect(extentList.cleanRangeStart, isNull);
      expect(extentList.cleanRangeEnd, isNull);
      expect(extentList.hasDirtyItems, isTrue);
    });
    test("cleanRange after markDirty is preserved", () {
      final extentList = ExtentList();

      extentList.resize(4, (_) => 100.0);
      for (int i = 0; i < 3; ++i) {
        extentList.setExtent(i, 50);
      }
      expect(extentList.cleanRangeStart, equals(0));
      expect(extentList.cleanRangeEnd, equals(2));
      expect(extentList.hasDirtyItems, isTrue);

      extentList.markDirty(3);
      // Item was already dirty, so clean range is preserved.
      expect(extentList.cleanRangeStart, equals(0));
      expect(extentList.cleanRangeEnd, equals(2));
      expect(extentList.hasDirtyItems, isTrue);
    });
  });
  test("addItem", () async {
    final extentList = ExtentList();
    extentList.resize(4, (_) => 100.0);
    for (int i = 0; i < 4; ++i) {
      extentList.setExtent(i, 50);
    }
    expect(extentList.totalExtent, 200);
    extentList.insertAt(2, (index) => 100);

    expect(extentList.totalExtent, 300);
    expect(extentList[2], 100);
    expect(extentList.isDirty(2), isTrue);
    expect(extentList.cleanRangeStart, isNull);
    expect(extentList.cleanRangeEnd, isNull);

    extentList.insertAt(0, (index) => 100);
    expect(extentList.totalExtent, 400);
    expect(extentList[0], 100);
    expect(extentList.isDirty(0), isTrue);

    extentList.insertAt(6, (index) => 150);
    expect(extentList.totalExtent, 550);
    expect(extentList[6], 150);
    expect(extentList.isDirty(6), isTrue);

    expect(extentList.length, equals(7));
  });
  test("removeItem", () async {
    final extentList = ExtentList();
    extentList.resize(4, (_) => 100.0);
    for (int i = 0; i < 3; ++i) {
      extentList.setExtent(i, 50);
    }
    expect(extentList.totalExtent, 250);
    extentList.removeAt(2);
    expect(extentList.totalExtent, 200);

    expect(extentList.isDirty(1), isFalse);
    expect(extentList.isDirty(2), isTrue);

    expect(extentList.cleanRangeStart, isNull);
    expect(extentList.cleanRangeEnd, isNull);

    extentList.removeAt(2);
    expect(extentList.totalExtent, 100);

    extentList.removeAt(0);
    expect(extentList.totalExtent, 50);

    expect(extentList.length, equals(1));
  });
  test("markAllDirty empty", () {
    final list = ExtentList();
    list.markAllDirty();
  });
  test("offsetForIndex", () {
    final extentList = ExtentList();

    extentList.resize(3, (_) => 100.0);
    extentList.setExtent(0, 50);
    extentList.setExtent(1, 70);
    extentList.setExtent(2, 80);

    expect(extentList.offsetForIndex(0), equals(0));
    expect(extentList.offsetForIndex(1), equals(50));
    expect(extentList.offsetForIndex(2), equals(120));
  });
  test("indexForOffset", () {
    final extentList = ExtentList();
    expect(extentList.indexForOffset(0), equals(null));
    expect(extentList.indexForOffset(100), equals(null));

    extentList.resize(3, (_) => 100.0);
    extentList.setExtent(0, 50);
    extentList.setExtent(1, 70);
    extentList.setExtent(2, 80);

    expect(extentList.indexForOffset(0), equals(0));
    expect(extentList.indexForOffset(49), equals(0));
    expect(extentList.indexForOffset(50), equals(1));
    expect(extentList.indexForOffset(119), equals(1));
    expect(extentList.indexForOffset(120), equals(2));
    expect(extentList.indexForOffset(200), equals(null));
    expect(extentList.indexForOffset(500), equals(null));
  });
  test("floating point rounding", () {
    final el = ExtentList();
    el.resize(2, (index) => 10.0);
    el.setExtent(0, 0.1);
    el.setExtent(1, 0.1);
    el.setExtent(0, 0.0);
    el.setExtent(1, 0.0);
    expect(el.totalExtent, 0.0);
  });
}
