import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';

import '../engine/order_book_models.dart';
import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: FINE-GRAINED ORDER BOOK ROW COMPONENT (1:1 REACTIVE ROW)
// =============================================================================

/// High-performance 1:1 reactive widget representing a single row in the 50-level order book.
/// Styled with dynamic Swiss Art Series Palette and micro-flash overlays.
final class OrderBookRow extends BuildComponent
    with CorallineTerminalIntentAware, CorallineBuildContextAware {
  OrderBookRow({
    required this.isAsk,
    required this.index,
  });

  final bool isAsk;
  final int index;

  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();

  late final Coral<OrderBookRowData> _rowCoral =
      coralOf<OrderBookPipeline>().cascade(
    (p) => isAsk ? p.askProviders[index].coral : p.bidProviders[index].coral,
  );

  @override
  Iterable<CoralNode> manifest() => [_rowCoral, themeCoral];

  @override
  Widget build() {
    final theme = themeCoral.data;
    final data = _rowCoral.data;
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
