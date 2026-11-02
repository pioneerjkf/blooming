// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../components/showcase_card.dart';
import '../store/showcase_store.dart';

/// Section 06: Async UI, SWR & BloomPendingIndicator Showcase Demo.
base class AsyncSwrBuilderSectionDemo extends BloomWidget {
  const AsyncSwrBuilderSectionDemo({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final store = via.of<ShowcaseStore>(context).sections.asyncSwrBuilder;
    final currentQuery = via(store.query);
    final isPreserve = via(store.preserveData);
    final latency = via(store.latencyMs);
    final fetchCount = via(store.fetchCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // Controls & Configuration Card
        // ---------------------------------------------------------------------
        ShowcaseCard(
          title: 'Interactive Async Query Control',
          badge: 'SWR Simulation',
          description:
              'Switch queries or simulate slow network responses. When SWR is enabled, prior data remains rendered without flicker while background revalidation occurs.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Query Selector
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Select Query:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  for (final q in ['Alice', 'Bob', 'Charlie', 'Empty', 'Error'])
                    ChoiceChip(
                      label: Text(q),
                      selected: currentQuery == q,
                      onSelected: (selected) {
                        if (selected) store.setQuery(q);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // SWR & Latency settings
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Preserve Data on Pending (SWR)',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        isPreserve
                            ? 'Flicker-Free: Retains old state during fetch'
                            : 'Strict: Shows loading spinner on every query',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      value: isPreserve,
                      onChanged: (_) => store.togglePreserveData(),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latency: ${latency}ms',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(
                        width: 180,
                        child: Slider(
                          value: latency.toDouble(),
                          min: 200,
                          max: 2000,
                          divisions: 9,
                          label: '${latency}ms',
                          onChanged: (val) => store.setLatency(val.round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Summary Bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Total Dispatches: $fetchCount',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Status: ', style: TextStyle(fontSize: 13)),
                        composed((context, via) {
                          final isPending = via(store.pending);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? Colors.amber.withAlpha(30)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isPending
                                    ? Colors.amber.withAlpha(120)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(120),
                              ),
                            ),
                            child: Text(
                              isPending ? 'FETCHING' : 'SETTLED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPending
                                    ? Colors.amber
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // Showcase Card 1: BloomAsyncBuilder + BloomPendingIndicator
        // ---------------------------------------------------------------------
        ShowcaseCard(
          title: '1. BloomAsyncBuilder & BloomPendingIndicator',
          badge: 'SWR Widget',
          description:
              'BloomPendingIndicator reactively tracks store.pending without rebuilding the rest of the view. BloomAsyncBuilder displays cached data while new data arrives.',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Slim Linear Pending Indicator
                BloomPendingIndicator(
                  target: store.pending,
                  height: 3.5,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(30),
                ),

                // Async Builder Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: BloomAsyncBuilder<DemoUser?>(
                    bloom: store.userProfile,
                    pending: store.pending,
                    preserveDataOnPending: isPreserve,
                    loading: (context) => const _LoadingPlaceholder(),
                    error: (context, error, stack) => _ErrorView(
                      error: error,
                      onRetry: () => store.refresh(),
                    ),
                    empty: (context) => const _EmptyView(),
                    data: (context, user) {
                      if (user == null) return const _EmptyView();
                      return _UserProfileCard(user: user);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // Showcase Card 2: BloomAsyncBuilder.tuple Named Shorthand
        // ---------------------------------------------------------------------
        ShowcaseCard(
          title: '2. BloomAsyncBuilder.tuple Shorthand',
          badge: 'Tuple Shorthand',
          description:
              'Seamlessly binds to ({data, pending}) named records directly without boilerplate destructuring.',
          child: BloomAsyncBuilder<DemoUser?>.tuple(
            store.userTuple,
            preserveDataOnPending: isPreserve,
            loading: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (context, err, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Inline Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            empty: (context) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No profile loaded (Empty result)'),
              ),
            ),
            data: (context, user) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user != null && user.name.isNotEmpty ? user.name[0] : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              title: Text(user?.name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user?.bio ?? ''),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // Showcase Card 3: Multi-Step Async Pipeline & Post-Await via()
        // ---------------------------------------------------------------------
        _MultiStepCheckoutShowcaseCard(store: store),
      ],
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.user});

  final DemoUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              user.name.isNotEmpty ? user.name[0] : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.id,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.bio,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fetched at: ${user.fetchedAt.toIso8601String().substring(11, 19)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Fetching remote profile in progress...',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fetch Error Encountered',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(fontSize: 13, color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry Query'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No user profile found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Showcase Card 3: Multi-Step Async Pipeline & Post-Await via() Widgets
// =============================================================================

base class _MultiStepCheckoutShowcaseCard extends BloomWidget {
  const _MultiStepCheckoutShowcaseCard({required this.store});

  final AsyncSwrBuilderStore store;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final cart = via(store.cart);
    final address = via(store.shippingAddress);
    final option = via(store.shippingOption);
    final isManual = via(store.manualMode);
    final step = via(store.checkoutStep);
    final trackedNodes = via(store.trackedNodes);
    final turnId = via(store.activeTurnId);
    final stepLog = via(store.stepStatusLog);

    final isStep1Waiting = step == CheckoutPipelineStep.step1Waiting;
    final isStep2Waiting =
        cart.hasPhysicalItems && step == CheckoutPipelineStep.step2Waiting;
    final isStep3Waiting =
        cart.hasPhysicalItems && step == CheckoutPipelineStep.step3Waiting;

    final isStep1Passed = step == CheckoutPipelineStep.step2Waiting ||
        step == CheckoutPipelineStep.step3Waiting ||
        (step == CheckoutPipelineStep.completed && turnId > 0);

    final isStep2Passed = cart.hasPhysicalItems &&
        (step == CheckoutPipelineStep.step3Waiting ||
            (step == CheckoutPipelineStep.completed && turnId > 0));

    final isStep3Passed = cart.hasPhysicalItems &&
        step == CheckoutPipelineStep.completed &&
        turnId > 0;

    final isAddressTracked = trackedNodes.contains('shippingAddressBloom');
    final isOptionTracked =
        trackedNodes.contains('selectedShippingOptionBloom');

    return ShowcaseCard(
      title: '3. Multi-Step Async Pipeline & Post-Await via()',
      badge: 'v0.2.5 Post-Await',
      description:
          'Demonstrates multi-step sequential await stages inside computed.future. Dependencies are discovered on-demand across await boundaries, while unvisited branches (e.g. shipping address for digital goods) are pruned automatically.',
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isManual ? 'Manual Stepper' : 'Auto Flow',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Switch(
              value: isManual,
              onChanged: (_) => store.toggleManualMode(),
            ),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // Step 1 Controls: Cart Type Selection
          // -------------------------------------------------------------------
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('1. Cart Items:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ChoiceChip(
                label: const Text('Digital Bundle (\$49)'),
                selected: cart == CartType.digital,
                onSelected: (selected) {
                  if (selected) store.setCart(CartType.digital);
                },
              ),
              ChoiceChip(
                label: const Text('Physical Dev Kit (\$129)'),
                selected: cart == CartType.physical,
                onSelected: (selected) {
                  if (selected) store.setCart(CartType.physical);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // -------------------------------------------------------------------
          // Step 2 & 3 Controls (Conditional on Physical goods)
          // -------------------------------------------------------------------
          if (cart.hasPhysicalItems) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('2. Destination:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                for (final addr in [
                  'Seoul, Teheran-ro 123',
                  'Busan, Haeundae-ro 45',
                  'Pangyo, Innovalley 7',
                ])
                  ChoiceChip(
                    label: Text(addr),
                    selected: address == addr,
                    onSelected: (selected) {
                      if (selected) store.setShippingAddress(addr);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('3. Shipping Speed:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                for (final opt in ShippingOption.values)
                  ChoiceChip(
                    label: Text('${opt.title} (+\$${opt.price})'),
                    selected: option == opt,
                    onSelected: (selected) {
                      if (selected) store.setShippingOption(opt);
                    },
                  ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(90),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Digital Goods: Requires no shipping. Address & Shipping Option are bypassed and NEVER subscribed to (Branch Pruning)!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // -------------------------------------------------------------------
          // The 3 Process Action Buttons
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3-Step Sequential Async Stepper',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (isManual)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.fast_forward_rounded,
                                size: 16),
                            label: const Text('Fast-Forward All',
                                style: TextStyle(fontSize: 12)),
                            onPressed: (isStep1Waiting ||
                                    isStep2Waiting ||
                                    isStep3Waiting)
                                ? store.stepAll
                                : null,
                          ),
                        IconButton(
                          tooltip: 'Re-trigger Pipeline',
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          onPressed: store.refreshCheckout,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Prominent Pipeline Status & Guidance Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isStep1Waiting || isStep2Waiting || isStep3Waiting)
                        ? Theme.of(context).colorScheme.primary.withAlpha(25)
                        : Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isStep1Waiting ||
                              isStep2Waiting ||
                              isStep3Waiting)
                          ? Theme.of(context).colorScheme.primary.withAlpha(120)
                          : Colors.green.withAlpha(100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (isStep1Waiting || isStep2Waiting || isStep3Waiting)
                            ? Icons.pause_circle_filled_rounded
                            : Icons.check_circle_rounded,
                        color:
                            (isStep1Waiting || isStep2Waiting || isStep3Waiting)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.green,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isStep1Waiting
                              ? '⏸️ Pipeline paused at Step 1: Click the big "Resolve Inventory" button below to continue'
                              : isStep2Waiting
                                  ? '⏸️ Pipeline paused at Step 2: Click the big "Fetch Shipping Rates" button below to continue'
                                  : isStep3Waiting
                                      ? '⏸️ Pipeline paused at Step 3: Click the big "Finalize Calculation" button below to complete'
                                      : '✅ All active pipeline steps resolved! Try switching to Digital Bundle or editing Destination above to trigger a new evaluation turn.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: (isStep1Waiting ||
                                    isStep2Waiting ||
                                    isStep3Waiting)
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Responsive Process Buttons Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    final children = [
                      _ProcessStepButton(
                        stepNumber: 1,
                        title: '1. Verify Inventory',
                        subtitle: 'api.checkInventory(cart)',
                        actionLabel: 'Resolve Inventory',
                        actionIcon: Icons.inventory_2_rounded,
                        isWaiting: isStep1Waiting,
                        isPassed: isStep1Passed,
                        isSkipped: false,
                        isPendingPrior: false,
                        onPressed: isStep1Waiting ? store.resolveStep1 : null,
                      ),
                      _ProcessStepButton(
                        stepNumber: 2,
                        title: '2. Fetch Shipping Rates',
                        subtitle: 'api.fetchShippingOptions(addr)',
                        actionLabel: 'Fetch Shipping Rates',
                        actionIcon: Icons.local_shipping_rounded,
                        isWaiting: isStep2Waiting,
                        isPassed: isStep2Passed,
                        isSkipped: !cart.hasPhysicalItems,
                        isPendingPrior: isStep1Waiting,
                        onPressed: isStep2Waiting ? store.resolveStep2 : null,
                      ),
                      _ProcessStepButton(
                        stepNumber: 3,
                        title: '3. Finalize Calculation',
                        subtitle: 'api.calculateCheckout(...)',
                        actionLabel: 'Finalize Calculation',
                        actionIcon: Icons.receipt_long_rounded,
                        isWaiting: isStep3Waiting,
                        isPassed: isStep3Passed,
                        isSkipped: !cart.hasPhysicalItems,
                        isPendingPrior: isStep1Waiting || isStep2Waiting,
                        onPressed: isStep3Waiting ? store.resolveStep3 : null,
                      ),
                    ];

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final btn in children)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: btn,
                            ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: children[i]),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // -------------------------------------------------------------------
          // DAG Dependency Graph & Turn Isolation Inspector
          // -------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(70),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hub_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'DAG Dependency Inspector',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Turn #$turnId',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Live Active vs Pruned Dependency Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const _DependencyPill(
                      nodeName: 'cartBloom',
                      isTracked: true,
                      timingLabel: 'Pre-await (Step 1)',
                    ),
                    _DependencyPill(
                      nodeName: 'shippingAddressBloom',
                      isTracked: isAddressTracked,
                      timingLabel: 'Post-await #1 (Step 2)',
                    ),
                    _DependencyPill(
                      nodeName: 'selectedShippingOptionBloom',
                      isTracked: isOptionTracked,
                      timingLabel: 'Post-await #2 (Step 3)',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Turn Log
                Row(
                  children: [
                    const Icon(Icons.terminal_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stepLog,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // -------------------------------------------------------------------
          // Live Checkout Result Card with Pending Indicator
          // -------------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BloomPendingIndicator(
                  target: store.checkoutPending,
                  height: 3.5,
                  color: Colors.indigoAccent,
                  backgroundColor: Colors.indigoAccent.withAlpha(30),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CheckoutLivePipelineCard(store: store),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper Widgets for Multi-Step Checkout Card
// =============================================================================

class _ProcessStepButton extends StatelessWidget {
  const _ProcessStepButton({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.isWaiting,
    required this.isPassed,
    required this.isSkipped,
    required this.isPendingPrior,
    required this.onPressed,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final bool isWaiting;
  final bool isPassed;
  final bool isSkipped;
  final bool isPendingPrior;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color borderColor;

    if (isSkipped) {
      backgroundColor = theme.colorScheme.surface.withAlpha(50);
      borderColor = theme.colorScheme.outlineVariant.withAlpha(50);
    } else if (isWaiting) {
      backgroundColor = theme.colorScheme.primary.withAlpha(25);
      borderColor = theme.colorScheme.primary;
    } else if (isPassed) {
      backgroundColor = Colors.green.withAlpha(20);
      borderColor = Colors.green.withAlpha(100);
    } else {
      backgroundColor = theme.colorScheme.surface.withAlpha(80);
      borderColor = theme.colorScheme.outlineVariant.withAlpha(70);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isWaiting ? 2.0 : 1.0,
        ),
        boxShadow: isWaiting
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(45),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isSkipped ? Colors.grey : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isPassed)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Colors.green)
              else if (isSkipped)
                const Icon(Icons.block_rounded, size: 16, color: Colors.grey)
              else if (isWaiting)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEXT ACTION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Icon(Icons.hourglass_empty_rounded,
                    size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // Primary Interactive Element
          if (isWaiting)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              onPressed: onPressed,
              icon: Icon(actionIcon, size: 18),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (isPassed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(80)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text(
                    'Resolved ✓',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )
          else if (isSkipped)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(40)),
              ),
              child: const Text(
                'Skipped (Branch Pruned)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: null,
              child: Text(
                'Waiting for Step ${stepNumber - 1}...',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _DependencyPill extends StatelessWidget {
  const _DependencyPill({
    required this.nodeName,
    required this.isTracked,
    required this.timingLabel,
  });

  final String nodeName;
  final bool isTracked;
  final String timingLabel;

  @override
  Widget build(BuildContext context) {
    final color = isTracked ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTracked ? Icons.check_rounded : Icons.close_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            nodeName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: color,
              decoration: isTracked ? null : TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($timingLabel)',
            style: TextStyle(
              fontSize: 10,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

base class _CheckoutLivePipelineCard extends BloomWidget {
  const _CheckoutLivePipelineCard({required this.store});

  final AsyncSwrBuilderStore store;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = Theme.of(context);
    final cart = via(store.cart);
    final address = via(store.shippingAddress);
    final option = via(store.shippingOption);
    final inventory = via(store.inventoryResult);
    final shipping = via(store.shippingResult);
    // Directly reads the completed payload from the primary computed.future checkout node!
    final summary = via.state(store.checkout).dataOrNull;
    final step = via(store.checkoutStep);
    final turnId = via(store.activeTurnId);

    final isAllCompleted =
        summary != null && step == CheckoutPipelineStep.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Status Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color:
                      isAllCompleted ? Colors.green : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Quotation (Turn #$turnId)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAllCompleted
                    ? Colors.green.withAlpha(25)
                    : theme.colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isAllCompleted
                      ? Colors.green.withAlpha(90)
                      : theme.colorScheme.primary.withAlpha(90),
                ),
              ),
              child: Text(
                isAllCompleted ? 'RESOLVED ✓' : 'IN PROGRESS (${step.label})',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      isAllCompleted ? Colors.green : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. Items & Inventory Row (Step 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${cart.title} (${cart.subtitle}):',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            if (inventory != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${cart.basePrice}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            else
              Text(
                '— (Verifying inventory...)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Shipping Rates Row (Step 2)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                !cart.hasPhysicalItems
                    ? 'Shipping (Digital Delivery):'
                    : shipping != null
                        ? 'Shipping (${shipping.title}):'
                        : 'Shipping (${option.title}):',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            if (!cart.hasPhysicalItems)
              const Text(
                '\$0 (Free Digital Delivery ✓)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              )
            else if (shipping != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '+\$${shipping.price}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            else
              Text(
                '— (Awaiting shipping rates...)',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),

        // 3. Destination Row (Conditional on Physical goods)
        if (cart.hasPhysicalItems) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ship to:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inventory != null ? address : '— (Pending inventory step)',
                  style: TextStyle(
                    fontSize: 12,
                    color: inventory != null
                        ? Colors.grey
                        : theme.colorScheme.outline,
                    fontStyle:
                        inventory != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],

        const Divider(height: 22),

        // 4. Grand Total Row (Step 3)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (summary != null)
              Text(
                '\$${summary.grandTotal}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Text(
                '— (Pending final calculation)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
