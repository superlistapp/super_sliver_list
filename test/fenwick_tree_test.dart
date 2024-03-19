import "dart:typed_data";

import "package:super_sliver_list/src/fenwick_tree.dart";
import "package:test/test.dart";

void main() {
  test("FenwickTree works", () {
    final tree = FenwickTree(size: 10);
    tree.update(0, 2);
    tree.update(1, 1);
    tree.update(2, 3);
    tree.update(3, 4);
    tree.update(4, 5);
    tree.update(5, 1);
    tree.update(6, 2);
    tree.update(7, 3);
    tree.update(8, 4);
    tree.update(9, 5);

    expect(tree.query(0), 0);
    expect(tree.query(3), 6);
    expect(tree.query(5), 15);
    expect(tree.query(6), 16);
    expect(tree.query(9), 25);
    expect(tree.query(10), 30);

    expect(tree.inverseQuery(0), 0);
    expect(tree.inverseQuery(1), 0);
    expect(tree.inverseQuery(2), 1);
    expect(tree.inverseQuery(5), 2);
    expect(tree.inverseQuery(6), 3);
    expect(tree.inverseQuery(25), 9);
    expect(tree.inverseQuery(29), 9);
    expect(tree.inverseQuery(30), 10);
    expect(tree.inverseQuery(300), 10);

    tree.update(5, 1);
    expect(tree.query(5), 15);
    expect(tree.query(6), 17);
    expect(tree.query(10), 31);
  });
  test("FenwickTree from list", () {
    final list = Float64List(10);
    list[0] = 2;
    list[1] = 1;
    list[2] = 3;
    list[3] = 4;
    list[4] = 5;
    list[5] = 1;
    list[6] = 2;
    list[7] = 3;
    list[8] = 4;
    list[9] = 5;
    final tree = FenwickTree.fromList(list: list);
    expect(tree.query(0), 0);
    expect(tree.query(3), 6);
    expect(tree.query(5), 15);
    expect(tree.query(6), 16);
    expect(tree.query(9), 25);
    expect(tree.query(10), 30);
  });
  test("large FenwickTree", () {
    const size = 10000000;
    final tree = FenwickTree(size: size);
    for (var i = 0; i < size; ++i) {
      tree.update(i, i.toDouble());
    }
    double total = 0;
    for (var i = 0; i < size; ++i) {
      expect(tree.query(i), total);
      total += i;
    }
    tree.update(0, 100);
    total = 0;
    for (var i = 0; i < size; ++i) {
      expect(tree.query(i), total);
      total += i == 0 ? 100 : i;
    }
  });
  test("large FenwickTree from list", () {
    const size = 10000000;
    final list = Float64List(size);
    for (var i = 0; i < size; ++i) {
      list[i] = i.toDouble();
    }
    final tree = FenwickTree.fromList(list: list);
    double total = 0;
    for (var i = 0; i < size; ++i) {
      expect(tree.query(i), total);
      total += i;
    }
    tree.update(0, 100);
    total = 0;
    for (var i = 0; i < size; ++i) {
      expect(tree.query(i), total);
      total += i == 0 ? 100 : i;
    }
  });
}
