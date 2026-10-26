import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/order_book_models.dart';
import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: FINE-GRAINED ORDER BOOK ROW COMPONENT (1:1 REACTIVE ROW)
// =============================================================================

/// High-performance 1:1 reactive widget representing a single row in the 50-level order book.
/// Built with Flutter Riverpod [ConsumerWidget], styled with dynamic Swiss Art Series Palette and micro-flash overlays.
class OrderBookRow extends ConsumerWidget {
  const OrderBookRow({
    super.key,
    required this.isAsk,
    required this.index,
  });

  final bool isAsk;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final data =
        ref.watch(isAsk ? askRowProvider(index) : bidRowProvider(index));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isRecentFlash = (nowMs - data.flashTimestampMs) < 90;

    // Side-aware flash glow overlay in Dynamic Theme Palette
    Color flashOverlayColor = Colors.transparent;
    if (isRecentFlash) {
      if (data.isAsk) {
        flashOverlayColor = data.flashType == FlashType.up
            ? theme.flashDownGlow
            : theme.askRedBg;
      } else {
        flashOverlayColor = data.flashType == FlashType.up
            ? theme.flashUpGlow
            : theme.bidGreenBg;
      }
    }

    final barColor = data.isAsk ? theme.askRedBg : theme.bidGreenBg;
    final priceColor = data.isAsk ? theme.askRed : theme.bidGreen;

    return Container(
      height: 22,
      color: flashOverlayColor,
      child: Stack(
        children: [
          // Swiss Flat Depth Bar (sharp rectangular fill)
          Positioned(
            right: 0,
            top: 1,
            bottom: 1,
            width: (310 * data.volumeRatio).clamp(2.0, 310.0),
            child: Container(
              color: barColor,
            ),
          ),
          // Content Row (Price on Left, Size on Right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                Text(
                  data.price.toStringAsFixed(2),
                  style: theme.priceStyle.copyWith(color: priceColor),
                ),
                // Volume Size
                Text(
                  data.volume.toString(),
                  style: theme.volumeStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
