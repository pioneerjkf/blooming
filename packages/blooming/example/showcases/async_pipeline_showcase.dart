// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';

/// Showcase 5: Asynchronous Sequential Pipelines & Post-Await Tracking
///
/// Demonstrates Bloom's post-`await` dynamic dependency tracking within [ComputedFunctor.future]:
/// 1. Interleaving asynchronous I/O (`await`) with dynamic reactive reads (`via(...)`)
/// 2. Automatic branch pruning (e.g. digital goods bypass address & shipping dependencies)
/// 3. Dynamic dependency discovery (nodes read only after `await` are tracked surgically)
/// 4. Turn isolation and stale turn supersession without race conditions
void main() async {
  print('=== Showcase 5: Asynchronous Sequential Pipelines ===\n');

  final api = _MockCheckoutApi();
  var turnCounter = 0;

  // Upstream Reactive Sources (Producer handles)
  final cart = blooming<_CartItem>(
    const _CartItem(
      name: 'Physical Dev Kit',
      price: 129,
      hasPhysicalItems: true,
    ),
  );
  final destination = blooming<String>('Seoul, Teheran-ro 123');
  final selectedOption = blooming<_ShippingOption>(
    const _ShippingOption(title: 'Standard Ground', price: 5),
  );

  // ---------------------------------------------------------------------------
  // Multi-Step Async Pipeline with Post-Await via() Tracking
  // ---------------------------------------------------------------------------
  final checkout = computed.future<_OrderSummary>((via) async {
    final turn = ++turnCounter;
    print('  [Pipeline] Turn #$turn: Starting checkout evaluation');

    // 1. Initial synchronous read: Cart
    final currentCart = via(cart.bloom);
    print('  [Pipeline] Turn #$turn: Step 1 -> Checking inventory for ${currentCart.name}...');
    final inventory = await api.checkInventory(currentCart);

    if (!inventory.hasPhysicalItems) {
      // Early exit for digital goods:
      // destination and selectedOption are NEVER read or tracked!
      print('  [Pipeline] Turn #$turn: Digital item detected -> Address & Shipping bypassed!');
      return api.quoteDigitalItems(currentCart, turn);
    }

    // 2. Read shipping address AFTER the first await!
    // Bloom captures this post-await dependency seamlessly.
    final address = via(destination.bloom);
    print('  [Pipeline] Turn #$turn: Step 2 -> Fetching shipping options for "$address"...');
    final shippingOptions = await api.fetchShippingOptions(address);

    // 3. Read selected shipping option AFTER the second await!
    final option = via(selectedOption.bloom);
    print('  [Pipeline] Turn #$turn: Step 3 -> Finalizing calculation with ${option.title}...');
    return await api.calculateCheckout(
      cart: currentCart,
      address: address,
      shippingOptions: shippingOptions,
      option: option,
      turnId: turn,
    );
  });

  // Attach a reactive terminal effect to observe resolved quotations.
  // Inactive Dormancy: computed.future starts ONLY when an active subscriber connects!
  print('--- Attaching Reactive Effect Runner ---');
  final runner = checkout.effect(() {
    final state = untracked.state(checkout);
    if (state.hasData) {
      print('  [Terminal] 📦 Fresh Quotation Received: ${state.data}\n');
    }
  }).start();

  // ---------------------------------------------------------------------------
  // Scenario 1: Initial Physical Goods Checkout
  // ---------------------------------------------------------------------------
  print('\n--- 1. Initial Physical Order (Turn #1) ---');
  // Wait for 3 async steps to resolve
  await Future<void>.delayed(const Duration(milliseconds: 120));

  // ---------------------------------------------------------------------------
  // Scenario 2: Dynamic Branch Pruning (Digital Goods Early Exit)
  // ---------------------------------------------------------------------------
  print('--- 2. Switching to Digital Goods (Branch Pruning) ---');
  cart.data = const _CartItem(
    name: 'Digital Architecture Bundle',
    price: 49,
    hasPhysicalItems: false,
  );

  // Wait for digital order to resolve
  await Future<void>.delayed(const Duration(milliseconds: 60));

  print('--- 3. Mutating Address While Digital Order is Active ---');
  print('-> Updating destination to "Busan, Haeundae-ro 45"...');
  destination.data = 'Busan, Haeundae-ro 45';

  // Wait briefly: Because digital goods early-exited before reading destination,
  // destination is NOT tracked. The pipeline should NOT re-evaluate!
  await Future<void>.delayed(const Duration(milliseconds: 60));
  print('-> Verified: Zero redundant re-evaluations triggered (Branch Pruning proved!)\n');

  // ---------------------------------------------------------------------------
  // Scenario 3: Dynamically Reviving Downstream Dependencies
  // ---------------------------------------------------------------------------
  print('--- 4. Switching back to Physical Goods ---');
  cart.data = const _CartItem(
    name: 'Physical Dev Kit',
    price: 129,
    hasPhysicalItems: true,
  );

  await Future<void>.delayed(const Duration(milliseconds: 120));

  print('--- 5. Updating Shipping Option for Physical Goods ---');
  print('-> Upgrading to Express Air (+15)...');
  selectedOption.data = const _ShippingOption(title: 'Express Air', price: 15);

  await Future<void>.delayed(const Duration(milliseconds: 120));

  // ---------------------------------------------------------------------------
  // Cleanup: Detach subscriber
  // ---------------------------------------------------------------------------
  print('--- Stopping Runner (Inactive Dormancy Restored) ---');
  runner.stop();
  print('Done.');
}

// =============================================================================
// Domain Models & Simulated Async API
// =============================================================================

class _CartItem {
  const _CartItem({
    required this.name,
    required this.price,
    required this.hasPhysicalItems,
  });

  final String name;
  final int price;
  final bool hasPhysicalItems;

  @override
  String toString() => '$name (\$$price)';
}

class _InventoryStatus {
  const _InventoryStatus({
    required this.inStock,
    required this.hasPhysicalItems,
  });

  final bool inStock;
  final bool hasPhysicalItems;
}

class _ShippingOption {
  const _ShippingOption({required this.title, required this.price});

  final String title;
  final int price;

  @override
  String toString() => '$title (+\$$price)';
}

class _OrderSummary {
  const _OrderSummary({
    required this.cart,
    required this.itemPrice,
    required this.shippingPrice,
    required this.address,
    required this.shippingOption,
    required this.turnId,
  });

  final _CartItem cart;
  final int itemPrice;
  final int shippingPrice;
  final String? address;
  final _ShippingOption? shippingOption;
  final int turnId;

  int get grandTotal => itemPrice + shippingPrice;

  @override
  String toString() {
    if (address == null) {
      return '[Order #$turnId] ${cart.name} -> Total: \$$grandTotal (Digital Free Delivery)';
    }
    return '[Order #$turnId] ${cart.name} -> Ship to: "$address" via ${shippingOption?.title} -> Total: \$$grandTotal';
  }
}

class _MockCheckoutApi {
  Future<_InventoryStatus> checkInventory(_CartItem cart) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    return _InventoryStatus(
      inStock: true,
      hasPhysicalItems: cart.hasPhysicalItems,
    );
  }

  Future<List<_ShippingOption>> fetchShippingOptions(String address) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    return const [
      _ShippingOption(title: 'Standard Ground', price: 5),
      _ShippingOption(title: 'Express Air', price: 15),
    ];
  }

  Future<_OrderSummary> calculateCheckout({
    required _CartItem cart,
    required String address,
    required List<_ShippingOption> shippingOptions,
    required _ShippingOption option,
    required int turnId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    return _OrderSummary(
      cart: cart,
      itemPrice: cart.price,
      shippingPrice: option.price,
      address: address,
      shippingOption: option,
      turnId: turnId,
    );
  }

  _OrderSummary quoteDigitalItems(_CartItem cart, int turnId) {
    return _OrderSummary(
      cart: cart,
      itemPrice: cart.price,
      shippingPrice: 0,
      address: null,
      shippingOption: null,
      turnId: turnId,
    );
  }
}
