import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  test('Multiple origins queued during Phase 2 (covers _pushOriginTail!._nextPushOrigin = origin; line 36)', () {
    final ctrl1 = blooming(0);
    final ctrl2 = blooming(0);
    final ctrl3 = blooming(0);

    final t1 = RawBloomTerminal<int>(ctrl1.bloom, onInvalidated: () {
      // Called during Phase 2.
      // queueOrigin called for ctrl2 (tail was null, becomes ctrl2)
      ctrl2.set(1);
      // queueOrigin called for ctrl3 (tail is ctrl2, so line 36 hits)
      ctrl3.set(1);
    });
    t1.activate();

    ctrl1.set(1);

    expect(untracked(ctrl2.bloom), 1);
    expect(untracked(ctrl3.bloom), 1);
  });
}
