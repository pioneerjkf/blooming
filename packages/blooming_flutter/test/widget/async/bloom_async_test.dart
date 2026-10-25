// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

void main() {
  group('BloomAsyncBuilder & BloomPendingIndicator Widget Tests', () {
    testWidgets(
        '1.1 BloomAsyncBuilder renders loading when node has no data yet',
        (tester) async {
      final controller = BloomController<String>.late();
      final pending = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: controller.bloom,
            pending: pending.bloom,
            data: (context, user) => Text('Data: $user'),
            loading: (context) => const Text('Loading...'),
            error: (context, error, stack) => Text('Error: $error'),
            empty: (context) => const Text('Empty!'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Data: Alice'), findsNothing);
    });

    testWidgets('1.2 BloomAsyncBuilder transitions from loading to data',
        (tester) async {
      final controller = BloomController<String>.late();
      final pending = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: controller.bloom,
            pending: pending.bloom,
            data: (context, user) => Text('Data: $user'),
            loading: (context) => const Text('Loading...'),
            error: (context, error, stack) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      // Transition to data
      controller.set('Alice');
      pending.set(false);
      await tester.pump();

      expect(find.text('Data: Alice'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets('1.3 BloomAsyncBuilder renders error when node fails',
        (tester) async {
      final controller = BloomController<String>.late();
      final pending = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: controller.bloom,
            pending: pending.bloom,
            data: (context, user) => Text('Data: $user'),
            loading: (context) => const Text('Loading...'),
            error: (context, error, stack) => Text('Error: $error'),
          ),
        ),
      );

      controller.setError('Server unavailable');
      pending.set(false);
      await tester.pump();

      expect(find.text('Error: Server unavailable'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '1.4 BloomAsyncBuilder renders empty when payload is empty list/map',
        (tester) async {
      final listController = BloomController<List<String>>(['first', 'second']);
      final pending = BloomController<bool>(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<List<String>>(
            bloom: listController.bloom,
            pending: pending.bloom,
            data: (context, items) => Text('Items: ${items.length}'),
            loading: (context) => const Text('Loading...'),
            empty: (context) => const Text('No items found'),
          ),
        ),
      );

      expect(find.text('Items: 2'), findsOneWidget);

      // Mutate to empty list
      listController.set([]);
      await tester.pump();

      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Items: 0'), findsNothing);

      // Mutate to empty map
      final mapController = BloomController<Map<String, int>>({'a': 1});
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<Map<String, int>>(
            bloom: mapController.bloom,
            pending: pending.bloom,
            data: (context, map) => Text('Map: ${map.length}'),
            loading: (context) => const Text('Loading...'),
            empty: (context) => const Text('Empty Map'),
          ),
        ),
      );
      expect(find.text('Map: 1'), findsOneWidget);

      mapController.set({});
      await tester.pump();
      expect(find.text('Empty Map'), findsOneWidget);
    });

    testWidgets(
        '1.4b BloomAsyncBuilder renders default ErrorWidget when error callback is null',
        (tester) async {
      final controller = BloomController<String>.late();
      final pending = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: controller.bloom,
            pending: pending.bloom,
            data: (context, user) => Text('Data: $user'),
            loading: (context) => const Text('Loading...'),
          ),
        ),
      );

      controller.setError('Default Error Message');
      pending.set(false);
      await tester.pump();

      expect(find.byType(ErrorWidget), findsOneWidget);
    });

    testWidgets(
        '1.5 BloomAsyncBuilder renders empty when settled with empty node',
        (tester) async {
      final node = Bloom<String>.empty('AwaitingSearchQuery');
      final pending = Bloom.constant(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: node,
            pending: pending,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            empty: (context) => const Text('Please enter search query'),
          ),
        ),
      );

      expect(find.text('Please enter search query'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '1.5b BloomAsyncBuilder renders loading as fallback when empty is null and settled empty',
        (tester) async {
      final node = Bloom<String>.empty();
      final pending = Bloom.constant(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: node,
            pending: pending,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets(
        '1.5c BloomAsyncBuilder works with toBloomTuple() destructured records',
        (tester) async {
      final completer = Completer<String>();
      final (:data, :pending) = completer.future.toBloomTuple();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: data,
            pending: pending,
            data: (context, val) => Text('Result: $val'),
            loading: (context) => const Text('Loading...'),
            empty: (context) => const Text('Empty'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      completer.complete('LoadedData');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Result: LoadedData'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '1.5d BloomAsyncBuilder transitions from loading to empty when pending settles to false on empty node',
        (tester) async {
      final dataController = BloomController<String>.late();
      final pendingController = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: dataController.bloom,
            pending: pendingController.bloom,
            data: (context, val) => Text('Result: $val'),
            loading: (context) => const Text('Loading...'),
            empty: (context) => const Text('No Data Found'),
          ),
        ),
      );

      // While pending == true, shows loading
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('No Data Found'), findsNothing);

      // Settle pending to false without providing data -> transitions to empty!
      pendingController.set(false);
      await tester.pump();

      expect(find.text('No Data Found'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '1.6 SWR preservation: retains prior data during pending re-evaluation by default',
        (tester) async {
      final query = BloomController<String>('apple');
      Completer<String>? activeCompleter;

      final rawFuture = computed.future((via) {
        via(query.bloom);
        final c = Completer<String>();
        activeCompleter = c;
        return c.future;
      });

      final pendingCoupler = BloomCoupler<bool>.late();
      final retainedNode = rawFuture.retained(pending: pendingCoupler);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: retainedNode,
            pending: pendingCoupler.bloom,
            preserveDataOnPending: true,
            data: (context, val) => Text('Fruit: $val'),
            loading: (context) => const Text('Loading...'),
          ),
        ),
      );

      // Initially loading
      expect(find.text('Loading...'), findsOneWidget);

      // First query finishes
      activeCompleter!.complete('AppleResults');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Fruit: AppleResults'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);

      // Query changes -> Starts pending transition
      query.set('banana');
      await tester.pump();
      await tester.pump(Duration.zero);

      // FLICKER-FREE SWR: Previous data is retained on screen!
      expect(find.text('Fruit: AppleResults'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);

      // Second query completes
      activeCompleter!.complete('BananaResults');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Fruit: BananaResults'), findsOneWidget);
    });

    testWidgets(
        '1.7 SWR disabled (preserveDataOnPending: false): shows loading during pending',
        (tester) async {
      final query = BloomController<String>('apple');
      Completer<String>? activeCompleter;

      final rawFuture = computed.future((via) {
        via(query.bloom);
        final c = Completer<String>();
        activeCompleter = c;
        return c.future;
      });

      final pendingCoupler = BloomCoupler<bool>.late();
      final retainedNode = rawFuture.retained(pending: pendingCoupler);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: retainedNode,
            pending: pendingCoupler.bloom,
            preserveDataOnPending: false, // SWR disabled!
            data: (context, val) => Text('Fruit: $val'),
            loading: (context) => const Text('Loading...'),
          ),
        ),
      );

      // Initial load
      expect(find.text('Loading...'), findsOneWidget);
      activeCompleter!.complete('AppleResults');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Fruit: AppleResults'), findsOneWidget);

      // Query changes -> pending
      query.set('banana');
      await tester.pump();
      await tester.pump(Duration.zero);

      // Shows loading because preserveDataOnPending is false!
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Fruit: AppleResults'), findsNothing);

      activeCompleter!.complete('BananaResults');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Fruit: BananaResults'), findsOneWidget);
    });

    testWidgets(
        '1.8 Selective pending subscription: BloomAsyncBuilder does NOT rebuild on pending change when preserveDataOnPending is true',
        (tester) async {
      final dataController = BloomController<String>('InitialData');
      final pendingController = BloomController<bool>(false);
      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: dataController.bloom,
            pending: pendingController.bloom,
            preserveDataOnPending: true,
            data: (context, val) {
              buildCount++;
              return Text('Data: $val (build $buildCount)');
            },
            loading: (context) => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Data: InitialData (build 1)'), findsOneWidget);
      expect(buildCount, 1);

      // Mutate pending to true: BloomAsyncBuilder should NOT rebuild because preserveDataOnPending is true
      pendingController.set(true);
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('Data: InitialData (build 1)'), findsOneWidget);

      // Mutate pending back to false: still NO rebuild
      pendingController.set(false);
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('Data: InitialData (build 1)'), findsOneWidget);

      // Only mutating data triggers a rebuild
      dataController.set('UpdatedData');
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Data: UpdatedData (build 2)'), findsOneWidget);
    });

    testWidgets(
        '1.9 Selective pending subscription: error state does NOT rebuild on pending change',
        (tester) async {
      final dataController = BloomController<String>.error('FatalError');
      final pendingController = BloomController<bool>(false);
      int errorBuildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: dataController.bloom,
            pending: pendingController.bloom,
            preserveDataOnPending: true,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            error: (context, err, stack) {
              errorBuildCount++;
              return Text('Error: $err (build $errorBuildCount)');
            },
          ),
        ),
      );

      expect(find.text('Error: FatalError (build 1)'), findsOneWidget);
      expect(errorBuildCount, 1);

      // Pending state change (e.g. background retry started)
      pendingController.set(true);
      await tester.pump();

      // Error UI is retained without rebuilding
      expect(errorBuildCount, 1);
      expect(find.text('Error: FatalError (build 1)'), findsOneWidget);
    });

    testWidgets('2.1 BloomPendingIndicator renders idle vs pending correctly',
        (tester) async {
      final pendingBloom = BloomController<bool>(false);

      final bar = BloomPendingIndicator(
        target: pendingBloom.bloom,
        height: 4.0,
      );

      expect(bar.preferredSize.height, 4.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              bar,
              const Text('Content Body'),
            ],
          ),
        ),
      );

      expect(find.text('Content Body'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);

      // Toggle pending to true
      pendingBloom.set(true);
      await tester.pump();

      expect(find.byType(CustomPaint), findsOneWidget);

      // Toggle pending back to false
      pendingBloom.set(false);
      await tester.pump();

      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('2.2 BloomPendingIndicator supports custom builder',
        (tester) async {
      final pendingBloom = BloomController<bool>(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomPendingIndicator(
            target: pendingBloom.bloom,
            builder: (context, isPending) => Text('PendingStatus: $isPending'),
          ),
        ),
      );

      expect(find.text('PendingStatus: false'), findsOneWidget);

      pendingBloom.set(true);
      await tester.pump();

      expect(find.text('PendingStatus: true'), findsOneWidget);
    });

    testWidgets(
        '2.3 BloomPendingIndicator directly binds to retained pending coupler',
        (tester) async {
      final query = BloomController<int>(1);
      Completer<String>? completer;

      final pendingCoupler = BloomCoupler<bool>.late();
      computed.future((via) {
        via(query.bloom);
        final c = Completer<String>();
        completer = c;
        return c.future;
      }).retained(pending: pendingCoupler);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomPendingIndicator(
            target: pendingCoupler.bloom,
            builder: (context, isPending) =>
                Text('RetainedPending: $isPending'),
          ),
        ),
      );

      // Initially before first resolution: idle (pending is false, raw is empty)
      expect(find.text('RetainedPending: false'), findsOneWidget);

      completer!.complete('Result 1');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('RetainedPending: false'), findsOneWidget);

      // Trigger re-query -> pending turns true
      query.set(2);
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('RetainedPending: true'), findsOneWidget);

      completer!.complete('Result 2');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('RetainedPending: false'), findsOneWidget);
    });

    testWidgets(
        '2.4 BloomPendingIndicator with opaque backgroundColor paints background',
        (tester) async {
      final pendingBloom = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomPendingIndicator(
            target: pendingBloom.bloom,
            color: const Color(0xFF0000FF),
            backgroundColor: const Color(0xFF000000),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final painter = customPaint.painter as dynamic;

      // test shouldRepaint branches
      expect(painter.shouldRepaint(painter), isFalse);
    });

    testWidgets(
        '3.1 composed with BloomPhase pattern matching handles 3-state nodes declaratively',
        (tester) async {
      final node = BloomController<String>.late();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child:
              composed((context, via) => switch (via.state(node.bloom).phase) {
                    BloomPhase.valid => Text('Item: ${via(node.bloom)}'),
                    BloomPhase.empty => const Text('비어있음'),
                    BloomPhase.error => const Text('에러'),
                  }),
        ),
      );

      expect(find.text('비어있음'), findsOneWidget);

      node.set('MacBook Pro');
      await tester.pump();
      expect(find.text('Item: MacBook Pro'), findsOneWidget);

      node.setError('Fail');
      await tester.pump();
      expect(find.text('에러'), findsOneWidget);
    });

    testWidgets(
        '3.2 BloomAsyncBuilder works seamlessly with Future toBloomTuple()',
        (tester) async {
      final completer = Completer<String>();
      final (:data, :pending) = completer.future.toBloomTuple();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: data,
            pending: pending,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            error: (context, err, stack) => Text('Error: $err'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      completer.complete('FutureResolved');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Data: FutureResolved'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '3.3 BloomAsyncBuilder works seamlessly with Stream toBloomTuple() without single-subscription conflict',
        (tester) async {
      final controller = StreamController<String>();
      final (:data, :pending) = controller.stream.toBloomTuple();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>(
            bloom: data,
            pending: pending,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            error: (context, err, stack) => Text('Error: $err'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      controller.add('StreamVal1');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Data: StreamVal1'), findsOneWidget);

      controller.add('StreamVal2');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Data: StreamVal2'), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        '3.4 BloomAsyncBuilder.tuple works seamlessly with Future toBloomTuple()',
        (tester) async {
      final completer = Completer<String>();
      final tuple = completer.future.toBloomTuple();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>.tuple(
            tuple,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            error: (context, err, stack) => Text('Error: $err'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      completer.complete('TupleResolved');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Data: TupleResolved'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets(
        '3.5 BloomAsyncBuilder.tuple works seamlessly with Stream toBloomTuple()',
        (tester) async {
      final controller = StreamController<String>();
      final tuple = controller.stream.toBloomTuple();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomAsyncBuilder<String>.tuple(
            tuple,
            data: (context, val) => Text('Data: $val'),
            loading: (context) => const Text('Loading...'),
            error: (context, err, stack) => Text('Error: $err'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      controller.add('StreamTuple1');
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Data: StreamTuple1'), findsOneWidget);

      await controller.close();
    });
  });
}
