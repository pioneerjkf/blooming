import 'dart:async';

import 'package:flutter/material.dart';

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
  swissMidCenturyGeometry(
      'MID-CENTURY GEOMETRY', 'Midnight Navy, Peach & Terracotta');

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
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissGenerationX = NasdaqThemeData(
    mode: NasdaqThemeMode.swissGenerationX,
    background: Color(0xFFFFCC00),
    cardBackground: Color(0xFFF2C200),
    surfaceBorder: Color(0xFF141414),
    gridLine: Color(0xFFD6A900),
    textPrimary: Color(0xFF141414),
    textSecondary: Color(0xFF2A2A2A),
    textMuted: Color(0xFF555555),
    textAccent: Color(0xFFD61A1F),
    askRed: Color(0xFFD61A1F),
    askRedBg: Color(0x33D61A1F),
    bidGreen: Color(0xFF008C45),
    bidGreenBg: Color(0x33008C45),
    flashUpGlow: Color(0x66008C45),
    flashDownGlow: Color(0x66D61A1F),
    chipBg: Color(0xFF141414),
    chipBorder: Color(0xFFD61A1F),
    chipText: Color(0xFFFFCC00),
  );

  static const NasdaqThemeData swissOpernhaus = NasdaqThemeData(
    mode: NasdaqThemeMode.swissOpernhaus,
    background: Color(0xFFF24822),
    cardBackground: Color(0xFFE33A36),
    surfaceBorder: Color(0xFFFFFFFF),
    gridLine: Color(0xFFC7282C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFD4CB),
    textMuted: Color(0xFFFFA494),
    textAccent: Color(0xFF111111),
    askRed: Color(0xFF111111),
    askRedBg: Color(0x33111111),
    bidGreen: Color(0xFFFFFFFF),
    bidGreenBg: Color(0x33FFFFFF),
    flashUpGlow: Color(0x66FFFFFF),
    flashDownGlow: Color(0x66111111),
    chipBg: Color(0xFF111111),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissBauhausSlate = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBauhausSlate,
    background: Color(0xFF2A2640),
    cardBackground: Color(0xFF353052),
    surfaceBorder: Color(0xFFE5A83B),
    gridLine: Color(0xFF48426B),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFBDB6D4),
    textMuted: Color(0xFF867E9F),
    textAccent: Color(0xFFE5A83B),
    askRed: Color(0xFFFF5252),
    askRedBg: Color(0x33FF5252),
    bidGreen: Color(0xFFE5A83B),
    bidGreenBg: Color(0x33E5A83B),
    flashUpGlow: Color(0x66E5A83B),
    flashDownGlow: Color(0x66FF5252),
    chipBg: Color(0xFFE5A83B),
    chipBorder: Color(0xFFF3F4F6),
    chipText: Color(0xFF2A2640),
  );

  static const NasdaqThemeData swissForestHaas = NasdaqThemeData(
    mode: NasdaqThemeMode.swissForestHaas,
    background: Color(0xFF0F2624),
    cardBackground: Color(0xFF163432),
    surfaceBorder: Color(0xFFFF452B),
    gridLine: Color(0xFF224A47),
    textPrimary: Color(0xFFE8E5DA),
    textSecondary: Color(0xFFA5B5B2),
    textMuted: Color(0xFF6B807D),
    textAccent: Color(0xFFFF452B),
    askRed: Color(0xFFFF452B),
    askRedBg: Color(0x33FF452B),
    bidGreen: Color(0xFF20E070),
    bidGreenBg: Color(0x3320E070),
    flashUpGlow: Color(0x6620E070),
    flashDownGlow: Color(0x66FF452B),
    chipBg: Color(0xFFFF452B),
    chipBorder: Color(0xFFE8E5DA),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissAkzidenzBlue = NasdaqThemeData(
    mode: NasdaqThemeMode.swissAkzidenzBlue,
    background: Color(0xFF1D00E6),
    cardBackground: Color(0xFF1600B8),
    surfaceBorder: Color(0xFFFFEE00),
    gridLine: Color(0xFF331AE6),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD0CCFF),
    textMuted: Color(0xFF9990FF),
    textAccent: Color(0xFFFFEE00),
    askRed: Color(0xFFFF3366),
    askRedBg: Color(0x33FF3366),
    bidGreen: Color(0xFF00FF88),
    bidGreenBg: Color(0x3300FF88),
    flashUpGlow: Color(0x6600FF88),
    flashDownGlow: Color(0x66FF3366),
    chipBg: Color(0xFFFFEE00),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF000000),
  );

  static const NasdaqThemeData swissZuerichMuseum = NasdaqThemeData(
    mode: NasdaqThemeMode.swissZuerichMuseum,
    background: Color(0xFF1A181C),
    cardBackground: Color(0xFF242228),
    surfaceBorder: Color(0xFF2979FF),
    gridLine: Color(0xFF36323B),
    textPrimary: Color(0xFFF7F7F8),
    textSecondary: Color(0xFFB0ACC4),
    textMuted: Color(0xFF757088),
    textAccent: Color(0xFFFF3B30),
    askRed: Color(0xFFFF3B30),
    askRedBg: Color(0x33FF3B30),
    bidGreen: Color(0xFF2979FF),
    bidGreenBg: Color(0x332979FF),
    flashUpGlow: Color(0x662979FF),
    flashDownGlow: Color(0x66FF3B30),
    chipBg: Color(0xFFFF3B30),
    chipBorder: Color(0xFF2979FF),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissNovumDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissNovumDark,
    background: Color(0xFF141619),
    cardBackground: Color(0xFF1E2024),
    surfaceBorder: Color(0xFFFF5500),
    gridLine: Color(0xFF2E3238),
    textPrimary: Color(0xFFF0F2F5),
    textSecondary: Color(0xFF9EA5B0),
    textMuted: Color(0xFF6B7280),
    textAccent: Color(0xFFFF5500),
    askRed: Color(0xFFFF3B30),
    askRedBg: Color(0x33FF3B30),
    bidGreen: Color(0xFF00E676),
    bidGreenBg: Color(0x3300E676),
    flashUpGlow: Color(0x6600E676),
    flashDownGlow: Color(0x66FF3B30),
    chipBg: Color(0xFFFF5500),
    chipBorder: Color(0xFFFF7722),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissConstructivistDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissConstructivistDark,
    background: Color(0xFF0B132B),
    cardBackground: Color(0xFF1C2541),
    surfaceBorder: Color(0xFF3A506B),
    gridLine: Color(0xFF23324C),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFF8D99AE),
    textMuted: Color(0xFF5C6B73),
    textAccent: Color(0xFFFFD166),
    askRed: Color(0xFFEF476F),
    askRedBg: Color(0x33EF476F),
    bidGreen: Color(0xFF06D6A0),
    bidGreenBg: Color(0x3306D6A0),
    flashUpGlow: Color(0x6606D6A0),
    flashDownGlow: Color(0x66EF476F),
    chipBg: Color(0xFF1C2541),
    chipBorder: Color(0xFF3A506B),
    chipText: Color(0xFFFFD166),
  );

  static const NasdaqThemeData swissCyberNeon = NasdaqThemeData(
    mode: NasdaqThemeMode.swissCyberNeon,
    background: Color(0xFF0D1117),
    cardBackground: Color(0xFF161B22),
    surfaceBorder: Color(0xFF00B4D8),
    gridLine: Color(0xFF21262D),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    textMuted: Color(0xFF6E7681),
    textAccent: Color(0xFF00F5D4),
    askRed: Color(0xFFFF0055),
    askRedBg: Color(0x33FF0055),
    bidGreen: Color(0xFF00F5D4),
    bidGreenBg: Color(0x3300F5D4),
    flashUpGlow: Color(0x6600F5D4),
    flashDownGlow: Color(0x66FF0055),
    chipBg: Color(0xFF00B4D8),
    chipBorder: Color(0xFF90E0EF),
    chipText: Color(0xFF0D1117),
  );

  static const NasdaqThemeData swissBrutalismDark = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrutalismDark,
    background: Color(0xFF121212),
    cardBackground: Color(0xFF1E1E1E),
    surfaceBorder: Color(0xFFFFD600),
    gridLine: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textMuted: Color(0xFF888888),
    textAccent: Color(0xFFFFD600),
    askRed: Color(0xFFFF3366),
    askRedBg: Color(0x33FF3366),
    bidGreen: Color(0xFF00FF66),
    bidGreenBg: Color(0x3300FF66),
    flashUpGlow: Color(0x6600FF66),
    flashDownGlow: Color(0x66FF3366),
    chipBg: Color(0xFFFFD600),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFF000000),
  );

  static const NasdaqThemeData swissHaasCream = NasdaqThemeData(
    mode: NasdaqThemeMode.swissHaasCream,
    background: Color(0xFFE5E2D8),
    cardBackground: Color(0xFFF0EDF3),
    surfaceBorder: Color(0xFF0F2624),
    gridLine: Color(0xFFD1CCC0),
    textPrimary: Color(0xFF0F2624),
    textSecondary: Color(0xFF2A4D48),
    textMuted: Color(0xFF637D78),
    textAccent: Color(0xFFFF452B),
    askRed: Color(0xFFFF452B),
    askRedBg: Color(0x33FF452B),
    bidGreen: Color(0xFF0F2624),
    bidGreenBg: Color(0x220F2624),
    flashUpGlow: Color(0x440F2624),
    flashDownGlow: Color(0x44FF452B),
    chipBg: Color(0xFF0F2624),
    chipBorder: Color(0xFFFF452B),
    chipText: Color(0xFFE5E2D8),
  );

  static const NasdaqThemeData swissLight = NasdaqThemeData(
    mode: NasdaqThemeMode.swissLight,
    background: Color(0xFFEBE8E1),
    cardBackground: Color(0xFFF7F5EF),
    surfaceBorder: Color(0xFFBCB7AC),
    gridLine: Color(0xFFD4CFB7),
    textPrimary: Color(0xFF141414),
    textSecondary: Color(0xFF524F47),
    textMuted: Color(0xFF8C877D),
    textAccent: Color(0xFF1B2A4A),
    askRed: Color(0xFFC82333),
    askRedBg: Color(0x28C82333),
    bidGreen: Color(0xFF2E7D32),
    bidGreenBg: Color(0x282E7D32),
    flashUpGlow: Color(0x4481C784),
    flashDownGlow: Color(0x44E57373),
    chipBg: Color(0xFF141414),
    chipBorder: Color(0xFF141414),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissBrutalismRed = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrutalismRed,
    background: Color(0xFFF4F1EA),
    cardBackground: Color(0xFFEFECE6),
    surfaceBorder: Color(0xFFE50914),
    gridLine: Color(0xFFD8D2C6),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF1E1E1E),
    textMuted: Color(0xFF555555),
    textAccent: Color(0xFFE50914),
    askRed: Color(0xFFE50914),
    askRedBg: Color(0x33E50914),
    bidGreen: Color(0xFF1B8A3A),
    bidGreenBg: Color(0x331B8A3A),
    flashUpGlow: Color(0x661B8A3A),
    flashDownGlow: Color(0x66E50914),
    chipBg: Color(0xFFE50914),
    chipBorder: Color(0xFF000000),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissAmberGeneva = NasdaqThemeData(
    mode: NasdaqThemeMode.swissAmberGeneva,
    background: Color(0xFFE87722),
    cardBackground: Color(0xFFDA6C19),
    surfaceBorder: Color(0xFF141414),
    gridLine: Color(0xFFB5560C),
    textPrimary: Color(0xFF141414),
    textSecondary: Color(0xFF222222),
    textMuted: Color(0xFF444444),
    textAccent: Color(0xFF141414),
    askRed: Color(0xFF8B0000),
    askRedBg: Color(0x338B0000),
    bidGreen: Color(0xFF004D40),
    bidGreenBg: Color(0x33004D40),
    flashUpGlow: Color(0x66004D40),
    flashDownGlow: Color(0x668B0000),
    chipBg: Color(0xFF141414),
    chipBorder: Color(0xFFFFFFFF),
    chipText: Color(0xFFE87722),
  );

  static const NasdaqThemeData swissMondrianGrid = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMondrianGrid,
    background: Color(0xFFFAFAFA),
    cardBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF111111),
    gridLine: Color(0xFFF4C430),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF666666),
    textAccent: Color(0xFFD32F2F),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x33D32F2F),
    bidGreen: Color(0xFF1A237E),
    bidGreenBg: Color(0x331A237E),
    flashUpGlow: Color(0x661A237E),
    flashDownGlow: Color(0x66D32F2F),
    chipBg: Color(0xFFD32F2F),
    chipBorder: Color(0xFFF4C430),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissBrockmann55 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissBrockmann55,
    background: Color(0xFFE5EE00),
    cardBackground: Color(0xFFF7F9E4),
    surfaceBorder: Color(0xFF111111),
    gridLine: Color(0xFFCCE000),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF666666),
    textAccent: Color(0xFF0082CA),
    askRed: Color(0xFFE60067),
    askRedBg: Color(0x33E60067),
    bidGreen: Color(0xFF0082CA),
    bidGreenBg: Color(0x330082CA),
    flashUpGlow: Color(0x660082CA),
    flashDownGlow: Color(0x66E60067),
    chipBg: Color(0xFF111111),
    chipBorder: Color(0xFFE5EE00),
    chipText: Color(0xFFE5EE00),
  );

  static const NasdaqThemeData swissCyanPoster99 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissCyanPoster99,
    background: Color(0xFF1E88E5),
    cardBackground: Color(0xFFF0F8FF),
    surfaceBorder: Color(0xFF0C2340),
    gridLine: Color(0xFFBBDEFB),
    textPrimary: Color(0xFF0C2340),
    textSecondary: Color(0xFF1565C0),
    textMuted: Color(0xFF5C6BC0),
    textAccent: Color(0xFF0D47A1),
    askRed: Color(0xFFD81B60),
    askRedBg: Color(0x33D81B60),
    bidGreen: Color(0xFF00897B),
    bidGreenBg: Color(0x3300897B),
    flashUpGlow: Color(0x6600897B),
    flashDownGlow: Color(0x66D81B60),
    chipBg: Color(0xFF0C2340),
    chipBorder: Color(0xFF90CAF9),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissMiedinger57 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMiedinger57,
    background: Color(0xFFEFEBE0),
    cardBackground: Color(0xFFF7F5EE),
    surfaceBorder: Color(0xFF1F1F1F),
    gridLine: Color(0xFFDCD6C8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF4A4A4A),
    textMuted: Color(0xFF7A7A7A),
    textAccent: Color(0xFFFF5252),
    askRed: Color(0xFFFF3333),
    askRedBg: Color(0x33FF3333),
    bidGreen: Color(0xFF2E7D32),
    bidGreenBg: Color(0x332E7D32),
    flashUpGlow: Color(0x662E7D32),
    flashDownGlow: Color(0x66FF3333),
    chipBg: Color(0xFFFF5252),
    chipBorder: Color(0xFF1F1F1F),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissDialecticsRed = NasdaqThemeData(
    mode: NasdaqThemeMode.swissDialecticsRed,
    background: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF111111),
    gridLine: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF777777),
    textAccent: Color(0xFFE53935),
    askRed: Color(0xFFD32F2F),
    askRedBg: Color(0x33D32F2F),
    bidGreen: Color(0xFF000000),
    bidGreenBg: Color(0x22000000),
    flashUpGlow: Color(0x44000000),
    flashDownGlow: Color(0x66D32F2F),
    chipBg: Color(0xFFE53935),
    chipBorder: Color(0xFF111111),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissKunsthaus50 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissKunsthaus50,
    background: Color(0xFFC8AD8D),
    cardBackground: Color(0xFFD5BE9F),
    surfaceBorder: Color(0xFF1C1917),
    gridLine: Color(0xFFB59A7A),
    textPrimary: Color(0xFF1C1917),
    textSecondary: Color(0xFF3E342B),
    textMuted: Color(0xFF5D5146),
    textAccent: Color(0xFF1C1917),
    askRed: Color(0xFF8B0000),
    askRedBg: Color(0x338B0000),
    bidGreen: Color(0xFF1C1917),
    bidGreenBg: Color(0x331C1917),
    flashUpGlow: Color(0x661C1917),
    flashDownGlow: Color(0x668B0000),
    chipBg: Color(0xFF1C1917),
    chipBorder: Color(0xFFC8AD8D),
    chipText: Color(0xFFD5BE9F),
  );

  static const NasdaqThemeData swissWeimarBauhaus23 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissWeimarBauhaus23,
    background: Color(0xFFEAE6DF),
    cardBackground: Color(0xFFF5F2EC),
    surfaceBorder: Color(0xFF1B1B1B),
    gridLine: Color(0xFFD6D0C5),
    textPrimary: Color(0xFF1B1B1B),
    textSecondary: Color(0xFF4A4A4A),
    textMuted: Color(0xFF7A7A7A),
    textAccent: Color(0xFF1C4E89),
    askRed: Color(0xFFD93B2B),
    askRedBg: Color(0x33D93B2B),
    bidGreen: Color(0xFF1C4E89),
    bidGreenBg: Color(0x331C4E89),
    flashUpGlow: Color(0x661C4E89),
    flashDownGlow: Color(0x66D93B2B),
    chipBg: Color(0xFF1C4E89),
    chipBorder: Color(0xFFE5B22D),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissHerrenmode23 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissHerrenmode23,
    background: Color(0xFF006B7B),
    cardBackground: Color(0xFF075461),
    surfaceBorder: Color(0xFFEFE6D5),
    gridLine: Color(0xFF0D7A8C),
    textPrimary: Color(0xFFEFE6D5),
    textSecondary: Color(0xFFC0D5D8),
    textMuted: Color(0xFF88ABAF),
    textAccent: Color(0xFFD04A36),
    askRed: Color(0xFFD04A36),
    askRedBg: Color(0x33D04A36),
    bidGreen: Color(0xFF4DB6AC),
    bidGreenBg: Color(0x334DB6AC),
    flashUpGlow: Color(0x664DB6AC),
    flashDownGlow: Color(0x66D04A36),
    chipBg: Color(0xFFD04A36),
    chipBorder: Color(0xFFEFE6D5),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissElectricViolet = NasdaqThemeData(
    mode: NasdaqThemeMode.swissElectricViolet,
    background: Color(0xFFF0F0F3),
    cardBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFF111827),
    gridLine: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    textAccent: Color(0xFF7C3AED),
    askRed: Color(0xFFEC4899),
    askRedBg: Color(0x33EC4899),
    bidGreen: Color(0xFF7C3AED),
    bidGreenBg: Color(0x337C3AED),
    flashUpGlow: Color(0x667C3AED),
    flashDownGlow: Color(0x66EC4899),
    chipBg: Color(0xFF7C3AED),
    chipBorder: Color(0xFF111827),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissairSlate50 = NasdaqThemeData(
    mode: NasdaqThemeMode.swissairSlate50,
    background: Color(0xFF64748B),
    cardBackground: Color(0xFF475569),
    surfaceBorder: Color(0xFFF8FAFC),
    gridLine: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textAccent: Color(0xFF38BDF8),
    askRed: Color(0xFFEF4444),
    askRedBg: Color(0x33EF4444),
    bidGreen: Color(0xFF38BDF8),
    bidGreenBg: Color(0x3338BDF8),
    flashUpGlow: Color(0x6638BDF8),
    flashDownGlow: Color(0x66EF4444),
    chipBg: Color(0xFF0EA5E9),
    chipBorder: Color(0xFFF8FAFC),
    chipText: Color(0xFFFFFFFF),
  );

  static const NasdaqThemeData swissMidCenturyGeometry = NasdaqThemeData(
    mode: NasdaqThemeMode.swissMidCenturyGeometry,
    background: Color(0xFF0A1128),
    cardBackground: Color(0xFF131C38),
    surfaceBorder: Color(0xFFF7CEBA),
    gridLine: Color(0xFF1E294D),
    textPrimary: Color(0xFFF7CEBA),
    textSecondary: Color(0xFFD4B1A1),
    textMuted: Color(0xFF9E8478),
    textAccent: Color(0xFFE04A2B),
    askRed: Color(0xFFE04A2B),
    askRedBg: Color(0x33E04A2B),
    bidGreen: Color(0xFF4C86A8),
    bidGreenBg: Color(0x334C86A8),
    flashUpGlow: Color(0x664C86A8),
    flashDownGlow: Color(0x66E04A2B),
    chipBg: Color(0xFFE04A2B),
    chipBorder: Color(0xFFF7CEBA),
    chipText: Color(0xFFFFFFFF),
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
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1.0,
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
// SECTION 3: REACTIVE SWISS THEME DOMAIN STORE (PURE FLUTTER CHANGENOTIFIER)
// =============================================================================

/// Strongly-typed domain store providing reactive Theme state using [ChangeNotifier] and [ValueNotifier].
class NasdaqThemeStore extends ChangeNotifier {
  NasdaqThemeStore({NasdaqThemeMode initialMode = NasdaqThemeMode.swissLight}) {
    themeNotifier =
        ValueNotifier<NasdaqThemeData>(NasdaqThemeData.of(initialMode));
    isAutoRotatingNotifier = ValueNotifier<bool>(false);
    rotationIntervalIndexNotifier = ValueNotifier<int>(6); // Index 6 = 1000ms
  }

  /// Preset interval options in milliseconds for theme auto-rotation.
  static const List<double> rotationIntervalPresetsMs = [
    8.33,
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

  late final ValueNotifier<NasdaqThemeData> themeNotifier;
  late final ValueNotifier<bool> isAutoRotatingNotifier;
  late final ValueNotifier<int> rotationIntervalIndexNotifier;

  ValueNotifier<NasdaqThemeData> get themeDataSignal => themeNotifier;
  ValueNotifier<bool> get isAutoRotatingSignal => isAutoRotatingNotifier;
  ValueNotifier<int> get rotationIntervalIndexSignal =>
      rotationIntervalIndexNotifier;

  Timer? _rotationTimer;

  NasdaqThemeData get current => themeNotifier.value;
  NasdaqThemeMode get mode => current.mode;

  bool get isAutoRotating => isAutoRotatingNotifier.value;
  int get rotationIntervalIndex => rotationIntervalIndexNotifier.value;
  double get currentRotationIntervalMs =>
      rotationIntervalPresetsMs[rotationIntervalIndex];

  void toggleNextTheme() {
    final nextIndex = (mode.index + 1) % NasdaqThemeMode.values.length;
    final newMode = NasdaqThemeMode.values[nextIndex];
    themeNotifier.value = NasdaqThemeData.of(newMode);
    notifyListeners();
  }

  void togglePreviousTheme() {
    final prevIndex = (mode.index - 1 + NasdaqThemeMode.values.length) %
        NasdaqThemeMode.values.length;
    final newMode = NasdaqThemeMode.values[prevIndex];
    themeNotifier.value = NasdaqThemeData.of(newMode);
    notifyListeners();
  }

  void setThemeMode(NasdaqThemeMode newMode) {
    themeNotifier.value = NasdaqThemeData.of(newMode);
    notifyListeners();
  }

  void startAutoRotation() {
    isAutoRotatingNotifier.value = true;
    _restartRotationTimer();
    notifyListeners();
  }

  void stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    isAutoRotatingNotifier.value = false;
    notifyListeners();
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
    rotationIntervalIndexNotifier.value = clamped;
    if (isAutoRotating) {
      _restartRotationTimer();
    }
    notifyListeners();
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(
      Duration(microseconds: (currentRotationIntervalMs * 1000).round()),
      (_) => toggleNextTheme(),
    );
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    themeNotifier.dispose();
    isAutoRotatingNotifier.dispose();
    rotationIntervalIndexNotifier.dispose();
    super.dispose();
  }
}
