import 'package:blooming_extensions/blooming_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('NumericBloomElementsExtension', () {
    test('sum and average compute numeric elements reactively', () {
      final controller = blooming<List<double>>([1.5, 2.5, 4.0]);

      final sumBloom = controller.bloom.elements.sum;
      final avgBloom = controller.bloom.elements.average;

      final termSum = RawBloomTerminal(sumBloom, onInvalidated: () {});
      final termAvg = RawBloomTerminal(avgBloom, onInvalidated: () {});
      termSum.activate();
      termAvg.activate();

      expect(termSum.snapshot.data, 8.0);
      expect(termAvg.snapshot.data, 8.0 / 3);

      controller.set([10.0, 20.0]);
      expect(termSum.snapshot.data, 30.0);
      expect(termAvg.snapshot.data, 15.0);

      controller.set([]);
      expect(termSum.snapshot.data, 0.0);
      expect(termAvg.snapshot.hasError, isTrue);
      expect(termAvg.snapshot.error, isA<StateError>());

      termSum.deactivate();
      termAvg.deactivate();
    });
  });
}
