import 'package:blooming_extensions/blooming_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('ListBloomElementsExtension', () {
    test('binarySearch and lowerBound locate elements reactively', () {
      final controller = blooming<List<int>>([10, 20, 30, 40]);

      final indexBloom = controller.bloom.elements.binarySearch(30);
      final boundBloom = controller.bloom.elements.lowerBound(25);

      final termIdx = RawBloomTerminal(indexBloom, onInvalidated: () {});
      final termBound = RawBloomTerminal(boundBloom, onInvalidated: () {});

      termIdx.activate();
      termBound.activate();

      expect(termIdx.snapshot.data, 2);
      expect(termBound.snapshot.data,
          2); // 25 would be inserted at index 2 (between 20 and 30)

      termIdx.deactivate();
      termBound.deactivate();
    });

    test(
        'sortedRange, sortedBy, sortedByCompare, shuffledRange, reversedRange, swapped return new lists reactively',
        () {
      final controller = blooming<List<int>>([5, 3, 9, 1, 7]);

      final sortedRangeBloom =
          controller.bloom.elements.sortedRange(1, 4, (a, b) => a.compareTo(b));
      final sortedByBloom = controller.bloom.elements.sortedBy((x) => x);
      final shuffledRangeBloom = controller.bloom.elements.shuffledRange(1, 4);
      final reversedRangeBloom = controller.bloom.elements.reversedRange(1, 4);
      final swappedBloom = controller.bloom.elements.swapped(0, 4);

      final t1 = RawBloomTerminal(sortedRangeBloom, onInvalidated: () {});
      final t2 = RawBloomTerminal(sortedByBloom, onInvalidated: () {});
      final t3 = RawBloomTerminal(shuffledRangeBloom, onInvalidated: () {});
      final t4 = RawBloomTerminal(reversedRangeBloom, onInvalidated: () {});
      final t5 = RawBloomTerminal(swappedBloom, onInvalidated: () {});

      t1.activate();
      t2.activate();
      t3.activate();
      t4.activate();
      t5.activate();

      expect(t1.snapshot.data, [5, 1, 3, 9, 7]);
      expect(t2.snapshot.data, [1, 3, 5, 7, 9]);
      expect(t4.snapshot.data, [5, 1, 9, 3, 7]);
      expect(t5.snapshot.data, [7, 3, 9, 1, 5]);

      t1.deactivate();
      t2.deactivate();
      t3.deactivate();
      t4.deactivate();
      t5.deactivate();
    });

    test(
        'equals, slice, elementAtOrNull, slices reactively compute list properties',
        () {
      final controller = blooming<List<int>>([1, 2, 3]);

      final eqBloom = controller.bloom.elements.equals([1, 2, 3]);
      final sliceBloom = controller.bloom.elements.slice(1, 3);
      final elemBloom = controller.bloom.elements.elementAtOrNull(1);
      final slicesBloom = controller.bloom.elements.slices(2);

      final tEq = RawBloomTerminal(eqBloom, onInvalidated: () {});
      final tSlice = RawBloomTerminal(sliceBloom, onInvalidated: () {});
      final tElem = RawBloomTerminal(elemBloom, onInvalidated: () {});
      final tSlices = RawBloomTerminal(slicesBloom, onInvalidated: () {});

      tEq.activate();
      tSlice.activate();
      tElem.activate();
      tSlices.activate();

      expect(tEq.snapshot.data, true);
      expect(tSlice.snapshot.data, [2, 3]);
      expect(tElem.snapshot.data, 2);
      expect(tSlices.snapshot.data, [
        [1, 2],
        [3]
      ]);

      tEq.deactivate();
      tSlice.deactivate();
      tElem.deactivate();
      tSlices.deactivate();
    });
  });
}
