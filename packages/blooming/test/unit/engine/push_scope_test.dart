import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('PushScope Coverage', () {
    test('Phase 2 Terminal Flush Error (line 100)', () {
      final ctrl = BloomController(0);

      Object? caughtError;
      final t1 = RawBloomTerminal<int>(
        ctrl.bloom,
        onInvalidated: () {
          throw StateError('Invalidate Error');
        },
        onUncaughtError: (e, s) {
          caughtError = e;
        },
      );

      t1.activate();
      ctrl.set(1);

      expect(caughtError, isA<StateError>().having((e) => e.message, 'message', 'Invalidate Error'));
    });

    test('Multiple terminals queue flush tail coverage (line 61)', () {
      final ctrl = BloomController(0);
      final t1 = RawBloomTerminal<int>(ctrl.bloom, onInvalidated: () {});
      final t2 = RawBloomTerminal<int>(ctrl.bloom, onInvalidated: () {});

      t1.activate();
      t2.activate();

      ctrl.set(1);

      expect(untracked(ctrl.bloom), 1);
    });

    test('Multiple terminals push origin tail coverage (line 36)', () {
      final ctrl = BloomController(0);
      final ctrl1 = BloomController(0);
      final ctrl2 = BloomController(0);

      final t = RawBloomTerminal<int>(ctrl.bloom, onInvalidated: () {
        print('onInvalidated called!');
        print('Setting ctrl1...');
        ctrl1.set(1);
        print('Setting ctrl2...');
        ctrl2.set(1);
        print('Done setting inside onInvalidated.');
      });
      t.activate();

      print('Triggering drain...');
      ctrl.set(1);
      print('Done triggering drain.');

      expect(untracked(ctrl1.bloom), 1);
      expect(untracked(ctrl2.bloom), 1);
    });
  });
}
