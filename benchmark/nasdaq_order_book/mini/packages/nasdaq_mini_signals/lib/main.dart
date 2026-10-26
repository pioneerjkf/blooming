import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'src/pipeline/order_book_pipeline.dart';
import 'src/ui/benchmark_hud_panel.dart';
import 'src/ui/event_loop_right_panel.dart';
import 'src/ui/nasdaq_watchlist_view.dart';
import 'src/ui/order_book_view.dart';
import 'src/ui/price_trend_view.dart';
import 'src/ui/recent_trades_view.dart';
import 'src/ui/selected_stock_header_bar.dart';
import 'src/ui/theme.dart';
import 'src/ui/theme_rotation_bar.dart';
import 'src/ui/tps_badge.dart';
import 'src/ui/benchmark_progress_badge.dart';

// =============================================================================
// SECTION 1: APPLICATION ENTRYPOINT
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NasdaqBenchmarkApp());
}

class NasdaqBenchmarkApp extends StatelessWidget {
  const NasdaqBenchmarkApp({
    super.key,
    this.themeStore,
    this.pipeline,
  });

  final NasdaqThemeStore? themeStore;
  final OrderBookPipeline? pipeline;

  @override
  Widget build(BuildContext context) {
    return NasdaqBenchmarkRootScreen(
      themeStore: themeStore,
      pipeline: pipeline,
    );
  }
}

// =============================================================================
// SECTION 2: ROOT SWISS BENCHMARK REACTIVE COMPONENT
// =============================================================================

class NasdaqBenchmarkRootScreen extends SignalStatefulWidget {
  const NasdaqBenchmarkRootScreen({
    super.key,
    this.themeStore,
    this.pipeline,
  });

  final NasdaqThemeStore? themeStore;
  final OrderBookPipeline? pipeline;

  @override
  State<NasdaqBenchmarkRootScreen> createState() =>
      _NasdaqBenchmarkRootScreenState();
}

class _NasdaqBenchmarkRootScreenState extends State<NasdaqBenchmarkRootScreen>
    with SingleTickerProviderStateMixin {
  late final NasdaqThemeStore _themeStore =
      widget.themeStore ?? NasdaqThemeStore();
  late final OrderBookPipeline _pipeline =
      widget.pipeline ?? OrderBookPipeline();
  late final Signal<double> _animOffsetSignal = signal<double>(0.5);

  late final Signal<NasdaqThemeStore> _themeStoreSignal = signal(_themeStore);
  late final Signal<OrderBookPipeline> _pipelineSignal = signal(_pipeline);

  Ticker? _ticker;
  double _elapsedSeconds = 0.0;
  void Function()? _scrollAnimCleanup;

  void _updateTicker(bool enabled) {
    if (enabled) {
      if (_ticker?.isActive != true) {
        _ticker?.start();
      }
    } else {
      if (_ticker?.isActive == true) {
        _ticker?.stop();
      }
      _animOffsetSignal.value = 0.5;
    }
  }

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      final normalizedProgress =
          (sin((_elapsedSeconds / 10.0) * 2 * pi - (pi / 2)) + 1.0) / 2.0;
      _animOffsetSignal.value = normalizedProgress;
    });

    _scrollAnimCleanup =
        _pipeline.isScrollAnimationEnabledSignal.subscribe((enabled) {
      _updateTicker(enabled);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTicker(_pipeline.isScrollAnimationEnabled);
      _pipeline.startSimulation();
    });
  }

  @override
  void dispose() {
    _scrollAnimCleanup?.call();
    _ticker?.stop();
    _ticker?.dispose();
    _pipeline.dispose();
    _themeStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeStore.themeDataSignal.value;

    return MultiSignalProvider(
      providers: [
        SignalProvider<Signal<NasdaqThemeStore>>.value(
          value: _themeStoreSignal,
        ),
        SignalProvider<ReadonlySignal<NasdaqThemeData>>.value(
          value: _themeStore.themeDataSignal,
        ),
        SignalProvider<Signal<OrderBookPipeline>>.value(
          value: _pipelineSignal,
        ),
        SignalProvider<ReadonlySignal<double>>.value(
          value: _animOffsetSignal,
        ),
      ],
      child: MaterialApp(
        title: 'NASDAQ 50-Level Order Book Benchmark (${theme.mode.label})',
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: false,
        theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: theme.background,
          cardColor: theme.cardBackground,
        ),
        home: Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1060,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Framework Brand Header Bar (Top-Left: Framework Name in Large Swiss Typography) (1060px)
                        Container(
                          width: 1060,
                          padding: const EdgeInsets.only(
                              left: 4, right: 4, bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'SIGNALS',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: theme.chipBg,
                                    border: Border.all(
                                        color: theme.chipBorder, width: 1.0),
                                  ),
                                  child: Text(
                                    'STATE MANAGEMENT',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: theme.chipText,
                                      letterSpacing: 1.2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '// FINE-GRAINED REACTIVE SIGNALS',
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textAccent,
                                    letterSpacing: 1.2,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'NASDAQ 50-LEVEL ORDER BOOK BENCHMARK',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textMuted,
                                    letterSpacing: 1.0,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top Theme Auto-Rotation Control Header Bar (1060px)
                        const ThemeRotationBar(),

                        const SizedBox(height: 3),

                        // Swiss Editorial Hero Title Header: Giant "000" + Bold Metadata Header (1060px)
                        Container(
                          width: 1060,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Giant Asymmetric Index "000"
                              Text(
                                '000',
                                style: theme.swissGiantNumber,
                              ),
                              const SizedBox(width: 10),
                              // Title & Coordinates Sub-Metadata (Googleplex, Mountain View, CA)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NASDAQ ORDER BOOK',
                                      style: theme.swissHeader,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '37°25\'19.1" N 122°05\'02.6" W',
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        color: theme.textMuted,
                                        letterSpacing: 0.6,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Text(
                                          'ENGINE. TPS. REPEAT. (SIGNALS)',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                            color: theme.textSecondary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Right Stamp Badges (TPS Live & Benchmark Progress)
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TpsHeaderBadge(),
                                  SizedBox(width: 8),
                                  BenchmarkProgressBadge(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Main Benchmark Layout (3-Column Swiss Dashboard matching 1060px width, 502px height)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Left Column: 001 NASDAQ WATCHLIST & Auto-Rotation Controller (Width 240px, Height 502px)
                            NasdaqWatchlistView(),

                            SizedBox(width: 10),

                            // 2. Middle Column (Width 570px): Selected Stock Bar + Stock Detail View (Height 502px)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Selected Stock Ticker & Live Metrics 1-Line Header Bar (Width 570px, Height 32px)
                                SelectedStockHeaderBar(),

                                SizedBox(height: 6),

                                // 002 PRICE TREND: Real-time Price Sparkline Chart (Width 570px, Height 64px)
                                PriceTrendView(),

                                SizedBox(height: 6),

                                // Middle Row: 003 ORDER BOOK (330px, Height 394px) + Right Column (004 RECENT TRADES [218px] + 005 BENCHMARK HUD [170px])
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 003 ORDER BOOK: 50-Level Extended Vertical Order Book Card (Width 330px, Height 394px)
                                    OrderBookView(),

                                    SizedBox(width: 10),

                                    // Center-Right Column (Width 230px): 004 RECENT TRADES + 005 BENCHMARK HUD
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 004 RECENT TRADES: Execution Ticks View (Width 230px, Height 218px)
                                        RecentTradesView(),

                                        SizedBox(height: 6),

                                        // 005 BENCHMARK HUD: Controls & Metrics HUD (Width 230px, Height 170px)
                                        BenchmarkHudPanel(),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(width: 10),

                            // 3. Right Column: Event Loop 3-Card Metrics Panel (Width 230px, Height 502px)
                            EventLoopRightPanel(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
