// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/async_swr_builder_section.dart';

/// Interactive Demo User model for async showcases.
class DemoUser {
  const DemoUser({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarIcon,
    required this.bio,
    required this.fetchedAt,
  });

  final String id;
  final String name;
  final String role;
  final IconData avatarIcon;
  final String bio;
  final DateTime fetchedAt;
}

/// Represents the type of cart items for the Multi-Step Async Checkout Showcase.
enum CartType {
  digital(
    title: 'Digital Bundle',
    subtitle: 'eBook + Dev License (No Shipping)',
    hasPhysicalItems: false,
    basePrice: 49,
  ),
  physical(
    title: 'Physical Dev Kit',
    subtitle: 'Hardware Board + Book (Requires Shipping)',
    hasPhysicalItems: true,
    basePrice: 129,
  );

  const CartType({
    required this.title,
    required this.subtitle,
    required this.hasPhysicalItems,
    required this.basePrice,
  });

  final String title;
  final String subtitle;
  final bool hasPhysicalItems;
  final int basePrice;
}

/// Shipping option with rate for the Multi-Step Async Checkout Showcase.
enum ShippingOption {
  standard(
    title: 'Standard Ground',
    price: 5,
    deliveryTime: '3-5 business days',
  ),
  express(
    title: 'Express Air',
    price: 15,
    deliveryTime: 'Next business day',
  );

  const ShippingOption({
    required this.title,
    required this.price,
    required this.deliveryTime,
  });

  final String title;
  final int price;
  final String deliveryTime;
}

/// Inventory check result.
class InventoryInfo {
  const InventoryInfo({
    required this.hasPhysicalItems,
    required this.available,
  });

  final bool hasPhysicalItems;
  final bool available;
}

/// Final calculated checkout summary.
class CheckoutSummary {
  const CheckoutSummary({
    required this.cart,
    required this.hasPhysicalItems,
    required this.itemPrice,
    required this.shippingPrice,
    required this.address,
    required this.shippingOption,
    required this.turnId,
    required this.calculatedAt,
  });

  factory CheckoutSummary.empty() => CheckoutSummary(
        cart: CartType.physical,
        hasPhysicalItems: false,
        itemPrice: 0,
        shippingPrice: 0,
        address: null,
        shippingOption: null,
        turnId: 0,
        calculatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  final CartType cart;
  final bool hasPhysicalItems;
  final int itemPrice;
  final int shippingPrice;
  final String? address;
  final ShippingOption? shippingOption;
  final int turnId;
  final DateTime calculatedAt;

  int get grandTotal => itemPrice + shippingPrice;
  bool get isEmpty => turnId == 0;
}

/// Current active phase/step in the 3-step checkout pipeline.
enum CheckoutPipelineStep {
  idle('Idle', 'Pipeline ready to trigger'),
  step1Waiting('Step 1 Pending', 'Awaiting inventory verification...'),
  step2Waiting('Step 2 Pending', 'Awaiting shipping rate calculation...'),
  step3Waiting('Step 3 Pending', 'Awaiting final checkout calculation...'),
  completed('Completed', 'Checkout calculation finalized');

  const CheckoutPipelineStep(this.label, this.description);
  final String label;
  final String description;
}

/// Sub-store for Section 06: Async UI, SWR & BloomPendingIndicator.
class AsyncSwrBuilderStore {
  AsyncSwrBuilderStore({int initialLatency = 500})
      : _latencyMs = blooming<int>(initialLatency) {
    _rawFuture = computed.future<DemoUser?>((via) async {
      final query = via(_query.bloom);
      final latency = via(_latencyMs.bloom);

      // Artificial asynchronous latency simulation
      if (latency > 0) {
        await Future<void>.delayed(Duration(milliseconds: latency));
      }

      if (query == 'Error') {
        throw Exception('Simulated Network 500: Failed to fetch user profile');
      }

      if (query == 'Empty') {
        return null;
      }

      return switch (query) {
        'Alice' => DemoUser(
            id: 'usr_001',
            name: 'Alice Johnson',
            role: 'Principal Systems Architect',
            avatarIcon: Icons.architecture_rounded,
            bio: 'Specializing in LPDAG graph compilers & reactive systems.',
            fetchedAt: DateTime.now(),
          ),
        'Bob' => DemoUser(
            id: 'usr_002',
            name: 'Bob Smith',
            role: 'Kernel Performance Hacker',
            avatarIcon: Icons.memory_rounded,
            bio: 'Obsessed with zero-alloc inline functors & cache lines.',
            fetchedAt: DateTime.now(),
          ),
        'Charlie' => DemoUser(
            id: 'usr_003',
            name: 'Charlie Davis',
            role: 'Product UX Designer',
            avatarIcon: Icons.palette_rounded,
            bio: 'Designing flicker-free micro-interactions & fluid motion.',
            fetchedAt: DateTime.now(),
          ),
        _ => DemoUser(
            id: 'usr_999',
            name: query,
            role: 'Guest Contributor',
            avatarIcon: Icons.person_rounded,
            bio: 'Exploring declarative reactive Flutter architectures.',
            fetchedAt: DateTime.now(),
          ),
      };
    });

    userProfile = _rawFuture.retained(pending: _pendingCoupler);

    // -------------------------------------------------------------------------
    // Multi-Step Async Pipeline & Post-Await BloomVia Tracking (Checkout Flow)
    // -------------------------------------------------------------------------
    // Note: The `scheduleMicrotask` calls throughout this derivation are purely
    // for UI showcase instrumentation (telemetry for active turn ID, DAG nodes,
    // and live step logs). Real-world production derivations require only the
    // clean business logic shown in the README and ShowcaseSection.codeSnippet!
    checkout = computed.future<CheckoutSummary>((via) async {
      via(_checkoutRefreshSignal.bloom);
      final turn = ++_turnCounter;
      scheduleMicrotask(() {
        _activeTurnId.set(turn);
        _trackedNodes.set(['cartBloom']);
        _stepStatusLog.set('Turn #$turn started: reading cartBloom');
        // Values in progress start EMPTY:
        _inventoryResult.set(null);
        _shippingResult.set(null);
      });

      // 1. Read cart (First synchronous read)
      final cart = via(_cart.bloom);

      // Step 1: Inventory Check (1st await)
      final inventory = await _awaitInventoryCheck(cart, turn);
      if (_turnCounter != turn) {
        return CheckoutSummary.empty();
      }

      // Step 1 Completed: Reveal inventory result!
      scheduleMicrotask(() {
        _inventoryResult.set(inventory);
      });

      if (!inventory.hasPhysicalItems) {
        // Digital items: Early exit!
        // shippingAddressBloom and shippingOptionBloom are NEVER read or tracked!
        final digitalSummary = CheckoutSummary(
          cart: cart,
          hasPhysicalItems: false,
          itemPrice: cart.basePrice,
          shippingPrice: 0,
          address: null,
          shippingOption: null,
          turnId: turn,
          calculatedAt: DateTime.now(),
        );
        scheduleMicrotask(() {
          _trackedNodes.set(['cartBloom']);
          _checkoutStep.set(CheckoutPipelineStep.completed);
          _stepStatusLog.set(
            'Turn #$turn: Completed (Digital - Address & Shipping bypassed!)',
          );
          _shippingResult.set(null);
        });
        return digitalSummary;
      }

      // 2. Read address after 1st await (Post-await via tracking!)
      final address = via(_shippingAddress.bloom);
      scheduleMicrotask(() {
        _trackedNodes.set(['cartBloom', 'shippingAddressBloom']);
        _stepStatusLog.set(
          'Turn #$turn: read shippingAddressBloom after 1st await',
        );
      });

      // Step 2: Shipping Options (2nd await)
      final shippingOptions = await _awaitShippingOptions(address, turn);
      if (_turnCounter != turn) {
        return CheckoutSummary.empty();
      }

      // 3. Read shipping option after 2nd await (Post-await via tracking!)
      final selectedOption = via(_shippingOption.bloom);
      scheduleMicrotask(() {
        _trackedNodes.set([
          'cartBloom',
          'shippingAddressBloom',
          'selectedShippingOptionBloom',
        ]);
        _stepStatusLog.set(
          'Turn #$turn: read selectedShippingOptionBloom after 2nd await',
        );
      });

      // Step 3: Checkout Calculation (3rd await)
      final summary = await _awaitFinalCalculation(
        cart: cart,
        address: address,
        options: shippingOptions,
        option: selectedOption,
        turn: turn,
      );
      if (_turnCounter != turn) {
        return CheckoutSummary.empty();
      }

      scheduleMicrotask(() {
        _checkoutStep.set(CheckoutPipelineStep.completed);
        _stepStatusLog.set(
          'Turn #$turn: Completed (Physical - All 3 dependencies tracked!)',
        );
      });
      return summary;
    });

    retainedCheckout = checkout.retained(pending: _checkoutPendingCoupler);
  }

  final _query = blooming<String>('Alice');
  final _preserveData = blooming<bool>(true);
  final BloomController<int> _latencyMs;
  final _fetchCount = blooming<int>(1);
  final _pendingCoupler = BloomCoupler<bool>.late();

  late final Bloom<DemoUser?> _rawFuture;

  /// Retained SWR node holding prior user profile data during background re-queries.
  late final Bloom<DemoUser?> userProfile;

  Bloom<String> get query => _query.bloom;
  Bloom<bool> get preserveData => _preserveData.bloom;
  Bloom<int> get latencyMs => _latencyMs.bloom;
  Bloom<int> get fetchCount => _fetchCount.bloom;
  Bloom<bool> get pending => _pendingCoupler.bloom;

  /// Retained SWR tuple holding ({data, pending}) directly for BloomAsyncBuilder.tuple.
  ({Bloom<DemoUser?> data, Bloom<bool> pending}) get userTuple =>
      (data: userProfile, pending: pending);

  // ---------------------------------------------------------------------------
  // Multi-Step Checkout Pipeline State & Controllers
  // ---------------------------------------------------------------------------
  final _cart = blooming<CartType>(CartType.physical);
  final _shippingAddress = blooming<String>('Seoul, Teheran-ro 123');
  final _shippingOption = blooming<ShippingOption>(ShippingOption.standard);
  final _manualMode = blooming<bool>(true);
  final _checkoutStep =
      blooming<CheckoutPipelineStep>(CheckoutPipelineStep.idle);
  final _trackedNodes = blooming<List<String>>(['cartBloom']);
  final _activeTurnId = blooming<int>(0);
  final _stepStatusLog = blooming<String>('Ready');
  final _checkoutRefreshSignal = blooming.signal();
  final _checkoutPendingCoupler = BloomCoupler<bool>.late();

  // Intermediate step results: empty (null) while in-flight, populated on step completion
  final _inventoryResult = blooming<InventoryInfo?>(null);
  final _shippingResult = blooming<ShippingOption?>(null);

  Completer<InventoryInfo>? _step1Completer;
  Completer<List<ShippingOption>>? _step2Completer;
  Completer<CheckoutSummary>? _step3Completer;
  int _turnCounter = 0;

  Bloom<CartType> get cart => _cart.bloom;
  Bloom<String> get shippingAddress => _shippingAddress.bloom;
  Bloom<ShippingOption> get shippingOption => _shippingOption.bloom;
  Bloom<bool> get manualMode => _manualMode.bloom;
  Bloom<CheckoutPipelineStep> get checkoutStep => _checkoutStep.bloom;
  Bloom<List<String>> get trackedNodes => _trackedNodes.bloom;
  Bloom<int> get activeTurnId => _activeTurnId.bloom;
  Bloom<String> get stepStatusLog => _stepStatusLog.bloom;
  Bloom<bool> get checkoutPending => _checkoutPendingCoupler.bloom;

  /// Live intermediate step result for Step 1 (Inventory).
  Bloom<InventoryInfo?> get inventoryResult => _inventoryResult.bloom;

  /// Live intermediate step result for Step 2 (Shipping Rate).
  Bloom<ShippingOption?> get shippingResult => _shippingResult.bloom;

  /// Primary multi-step asynchronous checkout derivation.
  late final Bloom<CheckoutSummary> checkout;

  /// Retained SWR checkout node preserving prior calculation during in-flight turns.
  late final Bloom<CheckoutSummary> retainedCheckout;

  void setQuery(String newQuery) {
    _fetchCount.set(_fetchCount.data + 1);
    _query.set(newQuery);
  }

  void togglePreserveData() => _preserveData.set(!_preserveData.data);

  void setLatency(int ms) => _latencyMs.set(ms);

  void refresh() {
    _fetchCount.set(_fetchCount.data + 1);
    final current = _query.data;
    // Re-trigger by setting identical or re-query
    _query.set(current);
  }

  // ---------------------------------------------------------------------------
  // Checkout Process Button Triggers & Control Methods
  // ---------------------------------------------------------------------------

  Future<InventoryInfo> _awaitInventoryCheck(CartType cart, int turn) {
    _step1Completer = Completer<InventoryInfo>();
    scheduleMicrotask(() {
      _checkoutStep.set(CheckoutPipelineStep.step1Waiting);
      _stepStatusLog
          .set('Turn #$turn: Paused at Step 1 (Waiting for Inventory)');
    });

    if (!_manualMode.data) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_turnCounter == turn &&
            _step1Completer != null &&
            !_step1Completer!.isCompleted) {
          _step1Completer!.complete(
            InventoryInfo(
              hasPhysicalItems: cart.hasPhysicalItems,
              available: true,
            ),
          );
        }
      });
    }
    return _step1Completer!.future;
  }

  Future<List<ShippingOption>> _awaitShippingOptions(String address, int turn) {
    _step2Completer = Completer<List<ShippingOption>>();
    scheduleMicrotask(() {
      _checkoutStep.set(CheckoutPipelineStep.step2Waiting);
      _stepStatusLog.set(
        'Turn #$turn: Paused at Step 2 (Waiting for Shipping Rates)',
      );
    });

    if (!_manualMode.data) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_turnCounter == turn &&
            _step2Completer != null &&
            !_step2Completer!.isCompleted) {
          _step2Completer!.complete([
            ShippingOption.standard,
            ShippingOption.express,
          ]);
        }
      });
    }
    return _step2Completer!.future;
  }

  Future<CheckoutSummary> _awaitFinalCalculation({
    required CartType cart,
    required String address,
    required List<ShippingOption> options,
    required ShippingOption option,
    required int turn,
  }) {
    _step3Completer = Completer<CheckoutSummary>();
    scheduleMicrotask(() {
      _checkoutStep.set(CheckoutPipelineStep.step3Waiting);
      _stepStatusLog.set(
        'Turn #$turn: Paused at Step 3 (Waiting for Final Calculation)',
      );
    });

    if (!_manualMode.data) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_turnCounter == turn &&
            _step3Completer != null &&
            !_step3Completer!.isCompleted) {
          _step3Completer!.complete(
            CheckoutSummary(
              cart: cart,
              hasPhysicalItems: cart.hasPhysicalItems,
              itemPrice: cart.basePrice,
              shippingPrice: option.price,
              address: address,
              shippingOption: option,
              turnId: turn,
              calculatedAt: DateTime.now(),
            ),
          );
        }
      });
    }
    return _step3Completer!.future;
  }

  /// Resolves Step 1 (Inventory Verification).
  void resolveStep1() {
    if (_step1Completer != null && !_step1Completer!.isCompleted) {
      _step1Completer!.complete(
        InventoryInfo(
          hasPhysicalItems: _cart.data.hasPhysicalItems,
          available: true,
        ),
      );
    }
  }

  /// Resolves Step 2 (Shipping Rates Calculation).
  void resolveStep2() {
    if (_step2Completer != null && !_step2Completer!.isCompleted) {
      _step2Completer!.complete([
        ShippingOption.standard,
        ShippingOption.express,
      ]);
    }
  }

  /// Resolves Step 3 (Final Checkout Calculation).
  void resolveStep3() {
    if (_step3Completer != null && !_step3Completer!.isCompleted) {
      _step3Completer!.complete(
        CheckoutSummary(
          cart: _cart.data,
          hasPhysicalItems: _cart.data.hasPhysicalItems,
          itemPrice: _cart.data.basePrice,
          shippingPrice: _shippingOption.data.price,
          address: _shippingAddress.data,
          shippingOption: _shippingOption.data,
          turnId: _turnCounter,
          calculatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Sequentially completes whatever steps are currently pending.
  Future<void> stepAll() async {
    if (_checkoutStep.data == CheckoutPipelineStep.step1Waiting) {
      resolveStep1();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_checkoutStep.data == CheckoutPipelineStep.step2Waiting) {
        resolveStep2();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (_checkoutStep.data == CheckoutPipelineStep.step3Waiting) {
          resolveStep3();
        }
      }
    } else if (_checkoutStep.data == CheckoutPipelineStep.step2Waiting) {
      resolveStep2();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_checkoutStep.data == CheckoutPipelineStep.step3Waiting) {
        resolveStep3();
      }
    } else if (_checkoutStep.data == CheckoutPipelineStep.step3Waiting) {
      resolveStep3();
    }
  }

  /// Updates cart type (switches between digital bundle and physical kit).
  void setCart(CartType cart) {
    if (_cart.data != cart) {
      _inventoryResult.set(null);
      _shippingResult.set(null);
      _cart.set(cart);
    }
  }

  /// Updates shipping destination address.
  void setShippingAddress(String address) {
    if (_shippingAddress.data != address) {
      _shippingResult.set(null);
      _shippingAddress.set(address);
    }
  }

  /// Updates selected shipping delivery speed.
  void setShippingOption(ShippingOption option) {
    if (_shippingOption.data != option) {
      _shippingOption.set(option);
    }
  }

  /// Toggles between manual process button stepping and auto timer resolution.
  void toggleManualMode() {
    _manualMode.set(!_manualMode.data);
    if (!_manualMode.data) {
      stepAll();
    }
  }

  /// Re-triggers the checkout pipeline explicitly via discrete signal pulse.
  void refreshCheckout() {
    _inventoryResult.set(null);
    _shippingResult.set(null);
    _checkoutRefreshSignal.emit();
  }

  ShowcaseSection get section => ShowcaseSection(
        id: '06_async_swr_builder',
        number: '06',
        title: 'Async UI, SWR & BloomPendingIndicator',
        subtitle:
            'Declarative 4-state asynchronous building, flicker-free SWR, and surgical pending indicators',
        badge: 'Async SWR',
        icon: Icons.cloud_sync_rounded,
        codeSnippet: '''
// 1. Multi-Step Async Pipeline with Post-await via() Tracking
final checkout = computed.future<CheckoutSummary>((via) async {
  final cart = via(cartBloom);
  final inventory = await api.checkInventory(cart);

  if (!inventory.hasPhysicalItems) {
    return api.quoteDigitalItems(cart); // Bypasses address & shipping!
  }

  // Read the address after the first await, only when shipping is needed.
  final address = via(shippingAddressBloom);
  final shippingOptions = await api.fetchShippingOptions(address);

  // Read the selected shipping option after the second await.
  final shippingOption = via(selectedShippingOptionBloom);
  return api.calculateCheckout(cart, shippingOptions, shippingOption);
});

// 2. Declarative 4-state builder with SWR (Stale-While-Revalidate)
BloomAsyncBuilder<DemoUser?>(
  bloom: store.userProfile,
  pending: store.pending,
  preserveDataOnPending: true, // Flicker-free: retains stale data while refetching!
  data: (context, user) => user == null ? const EmptyNotice() : UserCard(user: user),
  loading: (context) => const ShimmerPlaceholder(),
  error: (context, error, stack) => ErrorCard(error: error),
  empty: (context) => const EmptyNotice(),
);

// 3. Surgical isolated Pending Indicator (Zero rebuild to surrounding tree)
BloomPendingIndicator(
  target: store.pending,
  height: 3.5,
  color: Colors.indigoAccent,
);
''',
        highlights: const [
          'Post-await via() Tracking: Read dependencies on-demand across sequential await points within owning async closures.',
          'Dynamic Branch Pruning: Unused branch dependencies (e.g. shipping address for digital goods) are never subscribed to.',
          'Turn Isolation: Stale post-await reads from superseded evaluation turns are cleanly isolated without race conditions.',
          'Zero-Flicker SWR: Retains previous valid data during background re-evaluation with preserveDataOnPending: true.',
          'BloomPendingIndicator: Surgical 2px~4px linear micro-indicator binding to Bloom<bool> with 0 rebuild to surrounding tree.',
        ],
        roadmapTree: '''
[Bloom Async UI & SWR Pipeline]
 ├── computed.future((via) async { ... })    -> Multi-Step async pipeline with post-await via()
 │    ├── Step 1: via(cartBloom) ──> await api.checkInventory(cart)
 │    ├── Branch: if (!hasPhysical) return digitalQuote (Prunes address & shipping!)
 │    ├── Step 2: via(shippingAddressBloom) ──> await api.fetchShippingOptions(addr)
 │    └── Step 3: via(selectedShippingOptionBloom) ──> return calculateCheckout(...)
 │
 ├── BloomAsyncBuilder<T>(...)               -> Declarative 4-State SWR Builder
 │    ├── BloomAsyncBuilder.tuple(tuple)     -> Ergonomic named shorthand for ({data, pending})
 │    ├── preserveDataOnPending: true       -> Zero-Flicker stale cache retention
 │    └── data / loading / error / empty
 │
 └── BloomPendingIndicator(...)              -> Surgical isolated micro-indicator
      ├── target: Bloom<bool>                -> Direct binding with 0 tree rebuild
      └── height / color / backgroundColor
''',
        builder: () => AsyncSwrBuilderSectionDemo(),
      );
}
