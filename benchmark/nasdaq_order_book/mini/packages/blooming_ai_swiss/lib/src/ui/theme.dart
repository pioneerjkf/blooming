import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blooming/blooming.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

// =============================================================================
// SECTION 1: SWISS ART SERIES THEME MODES ENUM (28 PRESETS)
// =============================================================================

/// Available Swiss Art Series Theme Modes (including high-contrast Dark & Poster themes)
enum NasdaqThemeMode {
  swissOledDark('SWISS OLED DARK', 'OLED Minimalist Black'),
  swissGridCopenhagen('GRID COPENHAGEN', 'Pine Green & Cream Editorial'),
  swissWhisky81('WHISKY 1981', 'Sand Beige, Crimson & Forest'),
  swissGenerationX('GENERATION X 1978', 'Vivid Canary & Duotone'),
  swissOpernhaus('OPERNHAUS ZÜRICH', 'Flame Orange & Magenta'),
  swissBauhausSlate('BAUHAUS SLATE', 'Slate Indigo & Mustard Gold'),
  swissForestHaas('SWISS HAAS TEAL', 'Forest Teal & Vermilion'),
  swissAkzidenzBlue('AKZIDENZ BLUE', 'Ultramarine Blue & Yellow'),
  swissZuerichMuseum('ZÜRICH MUSEUM', 'Espresso & Tricolor Accent'),
  swissNovumDark('NOVUM CHARCOAL', 'Flame Orange & Charcoal'),
  swissConstructivistDark('CONSTRUCTIVIST DARK', 'Deep Cobalt & Gold'),
  swissCyberNeon('SWISS NEON', 'Cyber Black & Neon Teal'),
  swissBrutalismDark('BRUTALISM DARK', 'Black & Voltage Yellow'),
  swissHaasCream('HAAS CREAM', 'Ivory Cream & Deep Teal'),
  swissLight('SWISS LIGHT', 'Editorial Light'),
  swissBrutalismRed('BRUTALISM RED', 'Red & High Contrast'),
  swissAmberGeneva('AMBER GENEVA', 'Vivid Geneva Amber'),
  swissMondrianGrid('MONDRIAN GRID', 'Primary Grid Pattern'),
  swissBrockmann55('BROCKMANN 1955', 'Canary Yellow, Cobalt & Pink'),
  swissCyanPoster99('CYAN POSTER 1999', 'Electric Cyan & Sky White'),
  swissMiedinger57('MIEDINGER 1957', 'Helvetica Linen & Vermilion'),
  swissDialecticsRed('SWISS DIALECTICS', 'Crimson Red & Stark White Grid'),
  swissKunsthaus50('KUNSTHAUS 1950', 'Kraft Parchment & Charcoal'),
  swissWeimarBauhaus23('WEIMAR BAUHAUS 1923', 'Cream, Cobalt & Mustard'),
  swissHerrenmode23('HERRENMODE 1923', 'Petrol Teal & Terracotta'),
  swissElectricViolet('ELECTRIC VIOLET', 'Poster White & Violet Accent'),
  swissairSlate50('SWISSAIR 1950', 'Steel Slate & Swissair Cyan'),
  swissMidCenturyGeometry('MID-CENTURY GEOMETRY', 'Midnight Navy, Peach & Terracotta');

  const NasdaqThemeMode(this.label, this.description);
  final String label;
  final String description;
}

// =============================================================================
// SECTION 2: SWISS THEME DATA SPECIFICATIONS
// =============================================================================

/// Swiss Art Series Theme Data definition holding colors & styles for a theme mode.
class NasdaqThemeData {
  const NasdaqThemeData({
    required this.mode,
    required this.background,
    required this.cardBackground,
    required this.surfaceBorder,
    required this.gridLine,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textAccent,
    required this.askRed,
    required this.askRedBg,
    required this.bidGreen,
    required this.bidGreenBg,
    required this.flashUpGlow,
    required this.flashDownGlow,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
  });

  final NasdaqThemeMode mode;
  final Color background;
  final Color cardBackground;
  final Color surfaceBorder;
  final Color gridLine;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textAccent;
  final Color askRed;
  final Color askRedBg;
  final Color bidGreen;
  final Color bidGreenBg;
  final Color flashUpGlow;
  final Color flashDownGlow;
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;

  static const NasdaqThemeData swissOledDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissOledDark,
    background: Color(0xFF09090B),
    cardBackground: Color(0xFF121215),
    surfaceBorder: Color(0xFF27272A),
    gridLine: Color(0xFF1E1E24),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    textAccent: Color(0xFF38BDF8),
    askRed: Color(0xFFFF453A),
    askRedBg: Color(0x33FF453A),
    bidGreen: Color(0xFF30D158),
    bidGreenBg: Color(0x3330D158),
    flashUpGlow: Color(0x6630D158),
    flashDownGlow: Color(0x66FF453A),
    chipBg: Color(0xFF27272A),
    chipBorder: Color(0xFF3F3F46),
    chipText: Color(0xFFFAFAFA),
  );

  static const NasdaqThemeData swissGridCopenhagen = NasdaqThemeData(
    mode: NasdaqThemeMode.swissGridCopenhagen,
    background: Color(0xFF163E2B),
    cardBackground: Color(0xFF1E4F39),
    surfaceBorder: Color(0xFFE2DDD1),
    gridLine: Color(0xFF286248),
    textPrimary: Color(0xFFF7F5EE),
    textSecondary: Color(0xFFB4C8BB),
    textMuted: Color(0xFF7D9987),
    textAccent: Color(0xFFE2DDD1),
    askRed: Color(0xFFFF5252),
    askRedBg: Color(0x33FF5252),
    bidGreen: Color(0xFF00E676),
    bidGreenBg: Color(0x3300E676),
    flashUpGlow: Color(0x6600E676),
    flashDownGlow: Color(0x66FF5252),
    chipBg: Color(0xFFE2DDD1),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF163E2B),
  );

  static const NasdaqThemeData swissWhisky81 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissWhisky81,
    background: Color(0xFFC7BEAD),
    cardBackground: Color(0xFFD4CCBC),
    surfaceBorder: Color(0xFFB81D24),
    gridLine: Color(0xFFB3AA98),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF403D37),
    textMuted: Color(0xFF6B665E),
    textAccent: Color(0xFFB81D24),
    askRed: Color(0xFFB81D24),
    askRedBg: Color(0x33B81D24),
    bidGreen: Color(0xFF006B36),
    bidGreenBg: Color(0x33006B36),
    flashUpGlow: Color(0x55006B36),
    flashDownGlow: Color(0x55B81D24),
    chipBg: Color(0xFFB81D24),
    chipBorder: Color(0xFF1A1A1A),
    chipText: Color(0xFFF0EBE1),
  );

  static const NasdaqThemeData swissGenerationX = NasdaqThemeData(
    mode: NasdaqThemeMode.swissGenerationX,
    background: Color(0xFFFED100),
    cardBackground: Color(0xFFFFDB26),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFFE0B800),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF2B2B2B),
    textMuted: Color(0xFF5E5E5E),
    textAccent: Color(0xFF000000),
    askRed: Color(0xFFE00000),
    askRedBg: Color(0x33E00000),
    bidGreen: Color(0xFF008000),
    bidGreenBg: Color(0x33008000),
    flashUpGlow: Color(0x55008000),
    flashDownGlow: Color(0x55E00000),
    chipBg: Color(0xFF000000),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFFFED100),
  );

  static const NasdaqThemeData swissOpernhaus = NasdaqThemeData(
    mode: NasdaqThemeMode.swissOpernhaus,
    background: Color(0xFFE84A27),
    cardBackground: Color(0xFFEE5E3E),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFFD43815),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFD5CC),
    textMuted: Color(0xFFFFA694),
    textAccent: Color(0xFF000000),
    askRed: Color(0xFF000000),
    askRedBg: Color(0x33000000),
    bidGreen: Color(0xFFFFFFFF),
    bidGreenBg: Color(0x33FFFFFF),
    flashUpGlow: Color(0x66FFFFFF),
    flashDownGlow: Color(0x66000000),
    chipBg: Color(0xFF000000),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissBauhausSlate = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBauhausSlate,
    background: Color(0xFF2B3A4A),
    cardBackground: Color(0xFF344558),
    surfaceBorder: Color(0xFFE2DDD1),
    gridLine: Color(0xFF41566D),
    textPrimary: Color(0xFFF7F5EE),
    textSecondary: Color(0xFFB8C7D6),
    textMuted: Color(0xFF8195A8),
    textAccent: Color(0xFFE5A93C),
    askRed: Color(0xFFFF5252),
    askRedBg: Color(0x33FF5252),
    bidGreen: Color(0xFF00E676),
    bidGreenBg: Color(0x3300E676),
    flashUpGlow: Color(0x6600E676),
    flashDownGlow: Color(0x66FF5252),
    chipBg: Color(0xFFE5A93C),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF1E2833),
  );

  static const NasdaqThemeData swissForestHaas = NasdaqThemeData(
    mode: NasdaqThemeMode.swissForestHaas,
    background: Color(0xFF1B3B36),
    cardBackground: Color(0xFF234B45),
    surfaceBorder: Color(0xFFD35400),
    gridLine: Color(0xFF2D5E57),
    textPrimary: Color(0xFFFAF8F5),
    textSecondary: Color(0xFFADC4C0),
    textMuted: Color(0xFF759993),
    textAccent: Color(0xFFE67E22),
    askRed: Color(0xFFE74C3C),
    askRedBg: Color(0x33E74C3C),
    bidGreen: Color(0xFF2ECC71),
    bidGreenBg: Color(0x332ECC71),
    flashUpGlow: Color(0x662ECC71),
    flashDownGlow: Color(0x66E74C3C),
    chipBg: Color(0xFFD35400),
    chipBorder: Color(0xFFFAF8F5),
    chipText: Color(0xFFFAF8F5),
  );

  static const NasdaqThemeData swissAkzidenzBlue = NasdaqThemeData(
    mode: NasdaqThemeMode.swissAkzidenzBlue,
    background: Color(0xFF0F3B8C),
    cardBackground: Color(0xFF1548A6),
    surfaceBorder: Color(0xFFFFCC00),
    gridLine: Color(0xFF1E5CC7),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0CDFF),
    textMuted: Color(0xFF7EA8F5),
    textAccent: Color(0xFFFFCC00),
    askRed: Color(0xFFFF4D4D),
    askRedBg: Color(0x33FF4D4D),
    bidGreen: Color(0xFF00FF7F),
    bidGreenBg: Color(0x3300FF7F),
    flashUpGlow: Color(0x6600FF7F),
    flashDownGlow: Color(0x66FF4D4D),
    chipBg: Color(0xFFFFCC00),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF0B2559),
  );

  static const NasdaqThemeData swissZuerichMuseum = NasdaqThemeData(
    mode: NasdaqThemeMode.swissZuerichMuseum,
    background: Color(0xFF2E241E),
    cardBackground: Color(0xFF3B2E27),
    surfaceBorder: Color(0xFFD4813F),
    gridLine: Color(0xFF4D3D34),
    textPrimary: Color(0xFFFAF5EF),
    textSecondary: Color(0xFFD6C8BC),
    textMuted: Color(0xFFA19185),
    textAccent: Color(0xFFE5985C),
    askRed: Color(0xFFE74C3C),
    askRedBg: Color(0x33E74C3C),
    bidGreen: Color(0xFF27AE60),
    bidGreenBg: Color(0x3327AE60),
    flashUpGlow: Color(0x6627AE60),
    flashDownGlow: Color(0x66E74C3C),
    chipBg: Color(0xFFD4813F),
    chipBorder: Color(0xFFFAF5EF),
    chipText: Color(0xFF1F1814),
  );

  static const NasdaqThemeData swissNovumDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissNovumDark,
    background: Color(0xFF1A1A1A),
    cardBackground: Color(0xFF262626),
    surfaceBorder: Color(0xFFFF5500),
    gridLine: Color(0xFF383838),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB8B8B8),
    textMuted: Color(0xFF7A7A7A),
    textAccent: Color(0xFFFF5500),
    askRed: Color(0xFFFF4D4D),
    askRedBg: Color(0x33FF4D4D),
    bidGreen: Color(0xFF00E676),
    bidGreenBg: Color(0x3300E676),
    flashUpGlow: Color(0x6600E676),
    flashDownGlow: Color(0x66FF4D4D),
    chipBg: Color(0xFFFF5500),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissConstructivistDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissConstructivistDark,
    background: Color(0xFF0E1A2B),
    cardBackground: Color(0xFF14243B),
    surfaceBorder: Color(0xFFD4AF37),
    gridLine: Color(0xFF1D3557),
    textPrimary: Color(0xFFFAF8F2),
    textSecondary: Color(0xFFB5C4D6),
    textMuted: Color(0xFF798FA8),
    textAccent: Color(0xFFD4AF37),
    askRed: Color(0xFFFF5959),
    askRedBg: Color(0x33FF5959),
    bidGreen: Color(0xFF2EC4B6),
    bidGreenBg: Color(0x332EC4B6),
    flashUpGlow: Color(0x662EC4B6),
    flashDownGlow: Color(0x66FF5959),
    chipBg: Color(0xFFD4AF37),
    chipBorder: Color(0xFFFAF8F2),
    chipText: Color(0xFF0E1A2B),
  );

  static const NasdaqThemeData swissCyberNeon = NasdaqThemeData(
    mode: NasdaqThemeMode.swissCyberNeon,
    background: Color(0xFF0A0E14),
    cardBackground: Color(0xFF101721),
    surfaceBorder: Color(0xFF00FFCC),
    gridLine: Color(0xFF1B2838),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF586069),
    textAccent: Color(0xFF00FFCC),
    askRed: Color(0xFFFF0055),
    askRedBg: Color(0x33FF0055),
    bidGreen: Color(0xFF00FFCC),
    bidGreenBg: Color(0x3300FFCC),
    flashUpGlow: Color(0x6600FFCC),
    flashDownGlow: Color(0x66FF0055),
    chipBg: Color(0xFF00FFCC),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF0A0E14),
  );

  static const NasdaqThemeData swissBrutalismDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrutalismDark,
    background: Color(0xFF000000),
    cardBackground: Color(0xFF141414),
    surfaceBorder: Color(0xFFFAFF00),
    gridLine: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA6A6A6),
    textMuted: Color(0xFF6B6B6B),
    textAccent: Color(0xFFFAFF00),
    askRed: Color(0xFFFF3333),
    askRedBg: Color(0x33FF3333),
    bidGreen: Color(0xFFFAFF00),
    bidGreenBg: Color(0x33FAFF00),
    flashUpGlow: Color(0x66FAFF00),
    flashDownGlow: Color(0x66FF3333),
    chipBg: Color(0xFFFAFF00),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF000000),
  );

  static const NasdaqThemeData swissHaasCream = NasdaqThemeData(
    mode: NasdaqThemeMode.swissHaasCream,
    background: Color(0xFFF4F0E8),
    cardBackground: Color(0xFFEDE6DA),
    surfaceBorder: Color(0xFF1B3B36),
    gridLine: Color(0xFFDDD4C4),
    textPrimary: Color(0xFF1A2624),
    textSecondary: Color(0xFF4A5E5B),
    textMuted: Color(0xFF7D9490),
    textAccent: Color(0xFF1B3B36),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x33D32F2F),
    bidGreen: Color(0xFF2E7D32),
    bidGreenBg: Color(0x332E7D32),
    flashUpGlow: Color(0x552E7D32),
    flashDownGlow: Color(0x55D32F2F),
    chipBg: Color(0xFF1B3B36),
    chipBorder: Color(0xFF1A2624),
    chipText: Color(0xFFF4F0E8),
  );

  static const NasdaqThemeData swissLight = NasdaqThemeData(
    mode: NasdaqThemeMode.swissLight,
    background: Color(0xFFF7F5F0),
    cardBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFFE2DDD5),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF888888),
    textAccent: Color(0xFFE53935),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x22D32F2F),
    bidGreen: Color(0xFF2E7D32),
    bidGreenBg: Color(0x222E7D32),
    flashUpGlow: Color(0x442E7D32),
    flashDownGlow: Color(0x44D32F2F),
    chipBg: Color(0xFF111111),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissBrutalismRed = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrutalismRed,
    background: Color(0xFFE50914),
    cardBackground: Color(0xFFB80710),
    surfaceBorder: Color(0xFFFFFFFF),
    gridLine: Color(0xFF8C050C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFCCD0),
    textMuted: Color(0xFFFFA3AA),
    textAccent: Color(0xFFFFFFFF),
    askRed: Color(0xFF000000),
    askRedBg: Color(0x33000000),
    bidGreen: Color(0xFFFFFFFF),
    bidGreenBg: Color(0x33FFFFFF),
    flashUpGlow: Color(0x66FFFFFF),
    flashDownGlow: Color(0x66000000),
    chipBg: Color(0xFFFFFFFF),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFFE50914),
  );

  static const NasdaqThemeData swissAmberGeneva = NasdaqThemeData(
    mode: NasdaqThemeMode.swissAmberGeneva,
    background: Color(0xFFFFB300),
    cardBackground: Color(0xFFFFC107),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFFFFA000),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF332200),
    textMuted: Color(0xFF664400),
    textAccent: Color(0xFF000000),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x33D32F2F),
    bidGreen: Color(0xFF1B5E20),
    bidGreenBg: Color(0x331B5E20),
    flashUpGlow: Color(0x551B5E20),
    flashDownGlow: Color(0x55D32F2F),
    chipBg: Color(0xFF000000),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFFFFB300),
  );

  static const NasdaqThemeData swissMondrianGrid = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMondrianGrid,
    background: Color(0xFFFAFAFA),
    cardBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFF000000),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF666666),
    textAccent: Color(0xFF0055A5),
    askRed: Color(0xFFE51C23),
    askRedBg: Color(0x33E51C23),
    bidGreen: Color(0xFF0055A5),
    bidGreenBg: Color(0x330055A5),
    flashUpGlow: Color(0x550055A5),
    flashDownGlow: Color(0x55E51C23),
    chipBg: Color(0xFFFFD600),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFF000000),
  );

  static const NasdaqThemeData swissBrockmann55 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrockmann55,
    background: Color(0xFFE8E2D2),
    cardBackground: Color(0xFFF0EBE0),
    surfaceBorder: Color(0xFF1A365D),
    gridLine: Color(0xFFD4CCA8),
    textPrimary: Color(0xFF1A202C),
    textSecondary: Color(0xFF4A5568),
    textMuted: Color(0xFF718096),
    textAccent: Color(0xFFD69E2E),
    askRed: Color(0xFFE53E3E),
    askRedBg: Color(0x33E53E3E),
    bidGreen: Color(0xFF319795),
    bidGreenBg: Color(0x33319795),
    flashUpGlow: Color(0x55319795),
    flashDownGlow: Color(0x55E53E3E),
    chipBg: Color(0xFF1A365D),
    chipBorder: Color(0xFF1A202C),
    chipText: Color(0xFFE8E2D2),
  );

  static const NasdaqThemeData swissCyanPoster99 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissCyanPoster99,
    background: Color(0xFF00BCD4),
    cardBackground: Color(0xFF26C6DA),
    surfaceBorder: Color(0xFF000000),
    gridLine: Color(0xFF00ACC1),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF004D40),
    textMuted: Color(0xFF00695C),
    textAccent: Color(0xFFFFFFFF),
    askRed: Color(0xFFD50000),
    askRedBg: Color(0x33D50000),
    bidGreen: Color(0xFF004D40),
    bidGreenBg: Color(0x33004D40),
    flashUpGlow: Color(0x55004D40),
    flashDownGlow: Color(0x55D50000),
    chipBg: Color(0xFF000000),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF00BCD4),
  );

  static const NasdaqThemeData swissMiedinger57 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMiedinger57,
    background: Color(0xFFEFEBE4),
    cardBackground: Color(0xFFF7F4EE),
    surfaceBorder: Color(0xFFE64A19),
    gridLine: Color(0xFFDCD5C9),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF545454),
    textMuted: Color(0xFF8A8A8A),
    textAccent: Color(0xFFE64A19),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x33D32F2F),
    bidGreen: Color(0xFF388E3C),
    bidGreenBg: Color(0x33388E3C),
    flashUpGlow: Color(0x55388E3C),
    flashDownGlow: Color(0x55D32F2F),
    chipBg: Color(0xFFE64A19),
    chipBorder: Color(0xFF212121),
    chipText: Color(0xFFEFEBE4),
  );

  static const NasdaqThemeData swissDialecticsRed = NasdaqThemeData(
    mode: NasdaqThemeMode.swissDialecticsRed,
    background: Color(0xFFC62828),
    cardBackground: Color(0xFFD32F2F),
    surfaceBorder: Color(0xFFFFFFFF),
    gridLine: Color(0xFFB71C1C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFCDD2),
    textMuted: Color(0xFFEF9A9A),
    textAccent: Color(0xFFFFFFFF),
    askRed: Color(0xFF212121),
    askRedBg: Color(0x33212121),
    bidGreen: Color(0xFFFFFFFF),
    bidGreenBg: Color(0x33FFFFFF),
    flashUpGlow: Color(0x66FFFFFF),
    flashDownGlow: Color(0x66212121),
    chipBg: Color(0xFFFFFFFF),
    chipBorder: Color(0xFF212121),
    chipText: Color(0xFFC62828),
  );

  static const NasdaqThemeData swissKunsthaus50 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissKunsthaus50,
    background: Color(0xFFD7CCC8),
    cardBackground: Color(0xFFE0D7D3),
    surfaceBorder: Color(0xFF3E2723),
    gridLine: Color(0xFFBCAAA4),
    textPrimary: Color(0xFF261D1A),
    textSecondary: Color(0xFF4E3D38),
    textMuted: Color(0xFF79655F),
    textAccent: Color(0xFF5D4037),
    askRed: Color(0xFFC62828),
    askRedBg: Color(0x33C62828),
    bidGreen: Color(0xFF2E7D32),
    bidGreenBg: Color(0x332E7D32),
    flashUpGlow: Color(0x552E7D32),
    flashDownGlow: Color(0x55C62828),
    chipBg: Color(0xFF3E2723),
    chipBorder: Color(0xFF261D1A),
    chipText: Color(0xFFD7CCC8),
  );

  static const NasdaqThemeData swissWeimarBauhaus23 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissWeimarBauhaus23,
    background: Color(0xFFF2ECE1),
    cardBackground: Color(0xFFFAF6EE),
    surfaceBorder: Color(0xFF1565C0),
    gridLine: Color(0xFFE0D6C3),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF424242),
    textMuted: Color(0xFF757575),
    textAccent: Color(0xFFC62828),
    askRed: Color(0xFFC62828),
    askRedBg: Color(0x33C62828),
    bidGreen: Color(0xFF1565C0),
    bidGreenBg: Color(0x331565C0),
    flashUpGlow: Color(0x551565C0),
    flashDownGlow: Color(0x55C62828),
    chipBg: Color(0xFFF9A825),
    chipBorder: Color(0xFF1A1A1A),
    chipText: Color(0xFF1A1A1A),
  );

  static const NasdaqThemeData swissHerrenmode23 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissHerrenmode23,
    background: Color(0xFF004D40),
    cardBackground: Color(0xFF00695C),
    surfaceBorder: Color(0xFFFF8A65),
    gridLine: Color(0xFF00796B),
    textPrimary: Color(0xFFE0F2F1),
    textSecondary: Color(0xFFB2DFDB),
    textMuted: Color(0xFF80CBC4),
    textAccent: Color(0xFFFF8A65),
    askRed: Color(0xFFFF7043),
    askRedBg: Color(0x33FF7043),
    bidGreen: Color(0xFF64FFDA),
    bidGreenBg: Color(0x3364FFDA),
    flashUpGlow: Color(0x6664FFDA),
    flashDownGlow: Color(0x66FF7043),
    chipBg: Color(0xFFFF8A65),
    chipBorder: Color(0xFFE0F2F1),
    chipText: Color(0xFF004D40),
  );

  static const NasdaqThemeData swissElectricViolet = NasdaqThemeData(
    mode: NasdaqThemeMode.swissElectricViolet,
    background: Color(0xFFEDE7F6),
    cardBackground: Color(0xFFF3E5F5),
    surfaceBorder: Color(0xFF6200EA),
    gridLine: Color(0xFFD1C4E9),
    textPrimary: Color(0xFF21153B),
    textSecondary: Color(0xFF4A3B69),
    textMuted: Color(0xFF7E6D9B),
    textAccent: Color(0xFF6200EA),
    askRed: Color(0xFFD50000),
    askRedBg: Color(0x33D50000),
    bidGreen: Color(0xFF00C853),
    bidGreenBg: Color(0x3300C853),
    flashUpGlow: Color(0x5500C853),
    flashDownGlow: Color(0x55D50000),
    chipBg: Color(0xFF6200EA),
    chipBorder: Color(0xFF21153B),
    chipText: Color(0xFFEDE7F6),
  );

  static const NasdaqThemeData swissairSlate50 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissairSlate50,
    background: Color(0xFF37474F),
    cardBackground: Color(0xFF455A64),
    surfaceBorder: Color(0xFF80DEEA),
    gridLine: Color(0xFF546E7A),
    textPrimary: Color(0xFFECEFF1),
    textSecondary: Color(0xFFCFD8DC),
    textMuted: Color(0xFF90A4AE),
    textAccent: Color(0xFF80DEEA),
    askRed: Color(0xFFFF5252),
    askRedBg: Color(0x33FF5252),
    bidGreen: Color(0xFF69F0AE),
    bidGreenBg: Color(0x3369F0AE),
    flashUpGlow: Color(0x6669F0AE),
    flashDownGlow: Color(0x66FF5252),
    chipBg: Color(0xFF80DEEA),
    chipBorder: Color(0xFFECEFF1),
    chipText: Color(0xFF263238),
  );

  static const NasdaqThemeData swissMidCenturyGeometry = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMidCenturyGeometry,
    background: Color(0xFF1A237E),
    cardBackground: Color(0xFF283593),
    surfaceBorder: Color(0xFFFFAB91),
    gridLine: Color(0xFF303F9F),
    textPrimary: Color(0xFFEDE7F6),
    textSecondary: Color(0xFFC5CAE9),
    textMuted: Color(0xFF9FA8DA),
    textAccent: Color(0xFFFFAB91),
    askRed: Color(0xFFFF5252),
    askRedBg: Color(0x33FF5252),
    bidGreen: Color(0xFF69F0AE),
    bidGreenBg: Color(0x3369F0AE),
    flashUpGlow: Color(0x6669F0AE),
    flashDownGlow: Color(0x66FF5252),
    chipBg: Color(0xFFFFAB91),
    chipBorder: Color(0xFFEDE7F6),
    chipText: Color(0xFF1A237E),
  );

  static NasdaqThemeData of(NasdaqThemeMode mode) {
    switch (mode) {
      case NasdaqThemeMode.swissOledDark:
        return swissOledDark;
      case NasdaqThemeMode.swissGridCopenhagen:
        return swissGridCopenhagen;
      case NasdaqThemeMode.swissWhisky81:
        return swissWhisky81;
      case NasdaqThemeMode.swissGenerationX:
        return swissGenerationX;
      case NasdaqThemeMode.swissOpernhaus:
        return swissOpernhaus;
      case NasdaqThemeMode.swissBauhausSlate:
        return swissBauhausSlate;
      case NasdaqThemeMode.swissForestHaas:
        return swissForestHaas;
      case NasdaqThemeMode.swissAkzidenzBlue:
        return swissAkzidenzBlue;
      case NasdaqThemeMode.swissZuerichMuseum:
        return swissZuerichMuseum;
      case NasdaqThemeMode.swissNovumDark:
        return swissNovumDark;
      case NasdaqThemeMode.swissConstructivistDark:
        return swissConstructivistDark;
      case NasdaqThemeMode.swissCyberNeon:
        return swissCyberNeon;
      case NasdaqThemeMode.swissBrutalismDark:
        return swissBrutalismDark;
      case NasdaqThemeMode.swissHaasCream:
        return swissHaasCream;
      case NasdaqThemeMode.swissLight:
        return swissLight;
      case NasdaqThemeMode.swissBrutalismRed:
        return swissBrutalismRed;
      case NasdaqThemeMode.swissAmberGeneva:
        return swissAmberGeneva;
      case NasdaqThemeMode.swissMondrianGrid:
        return swissMondrianGrid;
      case NasdaqThemeMode.swissBrockmann55:
        return swissBrockmann55;
      case NasdaqThemeMode.swissCyanPoster99:
        return swissCyanPoster99;
      case NasdaqThemeMode.swissMiedinger57:
        return swissMiedinger57;
      case NasdaqThemeMode.swissDialecticsRed:
        return swissDialecticsRed;
      case NasdaqThemeMode.swissKunsthaus50:
        return swissKunsthaus50;
      case NasdaqThemeMode.swissWeimarBauhaus23:
        return swissWeimarBauhaus23;
      case NasdaqThemeMode.swissHerrenmode23:
        return swissHerrenmode23;
      case NasdaqThemeMode.swissElectricViolet:
        return swissElectricViolet;
      case NasdaqThemeMode.swissairSlate50:
        return swissairSlate50;
      case NasdaqThemeMode.swissMidCenturyGeometry:
        return swissMidCenturyGeometry;
    }
  }

  TextStyle get swissGiantNumber => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        height: 0.9,
        letterSpacing: -1.5,
        fontFamily: 'monospace',
      );

  TextStyle get swissHeader => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: 1.5,
      );

  TextStyle get swissIndexLabel => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: textAccent,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
      );

  TextStyle get priceStyle => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        fontFamily: 'monospace',
        letterSpacing: 0.5,
      );

  TextStyle get volumeStyle => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        fontFamily: 'monospace',
        letterSpacing: 0.5,
      );
}

// =============================================================================
// SECTION 3: REACTIVE SWISS THEME DOMAIN STORE (BLOOMING)
// =============================================================================

/// Strongly-typed domain store providing reactive Theme state using [BloomController].
/// Injected into Flutter element tree via [InheritedBloom<NasdaqThemeData>].
final class NasdaqThemeStore {
  NasdaqThemeStore({NasdaqThemeMode initialMode = NasdaqThemeMode.swissLight})
      : _controller = BloomController<NasdaqThemeData>(
          NasdaqThemeData.of(initialMode),
        );

  static const List<double> rotationIntervalPresetsMs = [
    16.67,
    50,
    100,
    250,
    500,
    1000,
    2000,
    3000,
    5000,
    10000,
  ];

  final BloomController<NasdaqThemeData> _controller;
  final BloomController<bool> _isAutoRotatingController = BloomController<bool>(false);
  final BloomController<int> _rotationIntervalIndexController =
      BloomController<int>(5); // Index 5 = 1000ms

  Timer? _rotationTimer;

  Bloom<NasdaqThemeData> get provider => _controller.bloom;
  Bloom<NasdaqThemeData> get themeBloom => _controller.bloom;
  NasdaqThemeData get current => _controller.data;
  NasdaqThemeMode get mode => current.mode;

  Bloom<bool> get isAutoRotatingBloom => _isAutoRotatingController.bloom;
  Bloom<int> get rotationIntervalIndexBloom => _rotationIntervalIndexController.bloom;

  bool get isAutoRotating => _isAutoRotatingController.data;
  int get rotationIntervalIndex => _rotationIntervalIndexController.data;
  double get currentRotationIntervalMs => rotationIntervalPresetsMs[rotationIntervalIndex];

  void toggleNextTheme() {
    final nextIndex = (mode.index + 1) % NasdaqThemeMode.values.length;
    final newMode = NasdaqThemeMode.values[nextIndex];
    _controller.set(NasdaqThemeData.of(newMode));
  }

  void togglePreviousTheme() {
    final prevIndex =
        (mode.index - 1 + NasdaqThemeMode.values.length) % NasdaqThemeMode.values.length;
    final newMode = NasdaqThemeMode.values[prevIndex];
    _controller.set(NasdaqThemeData.of(newMode));
  }

  void setThemeMode(NasdaqThemeMode newMode) {
    _controller.set(NasdaqThemeData.of(newMode));
  }

  void startAutoRotation() {
    _isAutoRotatingController.set(true);
    _restartRotationTimer();
  }

  void stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _isAutoRotatingController.set(false);
  }

  void toggleAutoRotation() {
    if (isAutoRotating) {
      stopAutoRotation();
    } else {
      startAutoRotation();
    }
  }

  void setRotationIntervalIndex(int index) {
    final clamped = index.clamp(0, rotationIntervalPresetsMs.length - 1);
    _rotationIntervalIndexController.set(clamped);
    if (isAutoRotating) {
      _restartRotationTimer();
    }
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(
      Duration(microseconds: (currentRotationIntervalMs * 1000).round()),
      (_) => toggleNextTheme(),
    );
  }

  void dispose() {
    _rotationTimer?.cancel();
  }
}
