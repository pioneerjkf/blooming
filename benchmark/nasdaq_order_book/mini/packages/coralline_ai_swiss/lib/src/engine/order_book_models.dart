import 'package:flutter/foundation.dart';

// =============================================================================
// SECTION 1: FLASH & VISUAL ANIMATION ENUMS
// =============================================================================

/// Visual flash state triggered on order book row price or size updates.
enum FlashType {
  none,
  up,
  down,
  sizeChange,
}

// =============================================================================
// SECTION 2: NASDAQ STOCK ITEM MODEL & DEFAULT LIST
// =============================================================================

/// Immutable model representing a NASDAQ stock item in the symbol list.
@immutable
class NasdaqStockItem {
  const NasdaqStockItem({
    required this.symbol,
    required this.name,
    required this.basePrice,
    required this.priceChange,
    required this.priceChangePct,
  });

  final String symbol;
  final String name;
  final double basePrice;
  final double priceChange;
  final double priceChangePct;

/// Default dataset containing 500 top NASDAQ-listed stock items.
  static const List<NasdaqStockItem> defaultStocks = [
    NasdaqStockItem(symbol: 'NVDA', name: 'NVIDIA Corp', basePrice: 135.5, priceChange: 2.45, priceChangePct: 1.84),
    NasdaqStockItem(symbol: 'AAPL', name: 'Apple Inc.', basePrice: 224.2, priceChange: 1.15, priceChangePct: 0.52),
    NasdaqStockItem(symbol: 'MSFT', name: 'Microsoft Corp.', basePrice: 448.9, priceChange: -3.2, priceChangePct: -0.71),
    NasdaqStockItem(symbol: 'AMZN', name: 'Amazon.com Inc.', basePrice: 186.4, priceChange: 0.85, priceChangePct: 0.46),
    NasdaqStockItem(symbol: 'GOOGL', name: 'Alphabet Inc.', basePrice: 172.8, priceChange: -1.1, priceChangePct: -0.63),
    NasdaqStockItem(symbol: 'META', name: 'Meta Platforms Inc.', basePrice: 512.3, priceChange: 6.4, priceChangePct: 1.27),
    NasdaqStockItem(symbol: 'TSLA', name: 'Tesla Inc.', basePrice: 218.6, priceChange: -4.5, priceChangePct: -2.02),
    NasdaqStockItem(symbol: 'AVGO', name: 'Broadcom Inc.', basePrice: 168.1, priceChange: 3.8, priceChangePct: 2.31),
    NasdaqStockItem(symbol: 'COST', name: 'Costco Wholesale', basePrice: 845.5, priceChange: 5.2, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'AMD', name: 'Advanced Micro Devices', basePrice: 144.2, priceChange: -2.1, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'NFLX', name: 'Netflix Inc.', basePrice: 642.1, priceChange: 8.3, priceChangePct: 1.31),
    NasdaqStockItem(symbol: 'INTC', name: 'Intel Corp.', basePrice: 30.8, priceChange: -0.45, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'QCOM', name: 'QUALCOMM Inc.', basePrice: 175.4, priceChange: 2.1, priceChangePct: 1.21),
    NasdaqStockItem(symbol: 'AMAT', name: 'Applied Materials', basePrice: 210.3, priceChange: -1.8, priceChangePct: -0.85),
    NasdaqStockItem(symbol: 'TXN', name: 'Texas Instruments', basePrice: 202.5, priceChange: 0.9, priceChangePct: 0.45),
    NasdaqStockItem(symbol: 'HON', name: 'Honeywell International', basePrice: 215.8, priceChange: 1.4, priceChangePct: 0.65),
    NasdaqStockItem(symbol: 'BKNG', name: 'Booking Holdings', basePrice: 3820.0, priceChange: 25.5, priceChangePct: 0.67),
    NasdaqStockItem(symbol: 'ISRG', name: 'Intuitive Surgical', basePrice: 450.2, priceChange: 4.8, priceChangePct: 1.08),
    NasdaqStockItem(symbol: 'AMGN', name: 'Amgen Inc.', basePrice: 325.6, priceChange: -2.3, priceChangePct: -0.7),
    NasdaqStockItem(symbol: 'VRTX', name: 'Vertex Pharmaceuticals', basePrice: 488.1, priceChange: 3.2, priceChangePct: 0.66),
    NasdaqStockItem(symbol: 'ADP', name: 'Automatic Data Proc.', basePrice: 265.4, priceChange: 1.1, priceChangePct: 0.42),
    NasdaqStockItem(symbol: 'SBUX', name: 'Starbucks Corp.', basePrice: 95.8, priceChange: -0.8, priceChangePct: -0.83),
    NasdaqStockItem(symbol: 'PANW', name: 'Palo Alto Networks', basePrice: 342.9, priceChange: 5.6, priceChangePct: 1.66),
    NasdaqStockItem(symbol: 'GILD', name: 'Gilead Sciences', basePrice: 78.4, priceChange: 0.3, priceChangePct: 0.38),
    NasdaqStockItem(symbol: 'MDLZ', name: 'Mondelez International', basePrice: 72.1, priceChange: -0.4, priceChangePct: -0.55),
    NasdaqStockItem(symbol: 'REGN', name: 'Regeneron Pharma', basePrice: 1120.5, priceChange: 12.4, priceChangePct: 1.12),
    NasdaqStockItem(symbol: 'ADBE', name: 'Adobe Inc.', basePrice: 535.8, priceChange: -4.2, priceChangePct: -0.78),
    NasdaqStockItem(symbol: 'LRCX', name: 'Lam Research Corp.', basePrice: 920.4, priceChange: 8.7, priceChangePct: 0.95),
    NasdaqStockItem(symbol: 'MU', name: 'Micron Technology', basePrice: 110.6, priceChange: -1.9, priceChangePct: -1.69),
    NasdaqStockItem(symbol: 'CSX', name: 'CSX Corp.', basePrice: 34.2, priceChange: 0.15, priceChangePct: 0.44),
    NasdaqStockItem(symbol: 'MELI', name: 'MercadoLibre Inc.', basePrice: 1980.0, priceChange: 22.0, priceChangePct: 1.12),
    NasdaqStockItem(symbol: 'KLAC', name: 'KLA Corporation', basePrice: 810.3, priceChange: 6.5, priceChangePct: 0.81),
    NasdaqStockItem(symbol: 'SNPS', name: 'Synopsys Inc.', basePrice: 580.9, priceChange: -3.1, priceChangePct: -0.53),
    NasdaqStockItem(symbol: 'CDNS', name: 'Cadence Design Systems', basePrice: 312.4, priceChange: 2.8, priceChangePct: 0.9),
    NasdaqStockItem(symbol: 'ASML', name: 'ASML Holding NV', basePrice: 940.0, priceChange: 11.2, priceChangePct: 1.21),
    NasdaqStockItem(symbol: 'ORLY', name: 'O\'Reilly Automotive', basePrice: 1140.2, priceChange: 7.4, priceChangePct: 0.65),
    NasdaqStockItem(symbol: 'MAR', name: 'Marriott International', basePrice: 248.5, priceChange: -1.2, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'CTAS', name: 'Cintas Corp.', basePrice: 750.6, priceChange: 3.9, priceChangePct: 0.52),
    NasdaqStockItem(symbol: 'PCAR', name: 'PACCAR Inc.', basePrice: 105.8, priceChange: 0.7, priceChangePct: 0.67),
    NasdaqStockItem(symbol: 'NXPI', name: 'NXP Semiconductors', basePrice: 268.4, priceChange: -2.1, priceChangePct: -0.78),
    NasdaqStockItem(symbol: 'MCHP', name: 'Microchip Technology', basePrice: 88.3, priceChange: -0.6, priceChangePct: -0.67),
    NasdaqStockItem(symbol: 'KDP', name: 'Keurig Dr Pepper', basePrice: 34.8, priceChange: 0.2, priceChangePct: 0.58),
    NasdaqStockItem(symbol: 'ABNB', name: 'Airbnb Inc.', basePrice: 132.4, priceChange: 1.85, priceChangePct: 1.42),
    NasdaqStockItem(symbol: 'MNST', name: 'Monster Beverage', basePrice: 52.1, priceChange: -0.3, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'FTNT', name: 'Fortinet Inc.', basePrice: 66.7, priceChange: 1.2, priceChangePct: 1.83),
    NasdaqStockItem(symbol: 'PAYX', name: 'Paychex Inc.', basePrice: 128.9, priceChange: 0.85, priceChangePct: 0.66),
    NasdaqStockItem(symbol: 'ROST', name: 'Ross Stores Inc.', basePrice: 154.2, priceChange: 1.1, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'ODFL', name: 'Old Dominion Freight', basePrice: 212.8, priceChange: -1.6, priceChangePct: -0.75),
    NasdaqStockItem(symbol: 'FAST', name: 'Fastenal Company', basePrice: 68.4, priceChange: 0.4, priceChangePct: 0.59),
    NasdaqStockItem(symbol: 'LULU', name: 'Lululemon Athletica', basePrice: 285.0, priceChange: -3.5, priceChangePct: -1.21),
    NasdaqStockItem(symbol: 'KHC', name: 'Kraft Heinz Co.', basePrice: 35.6, priceChange: 0.15, priceChangePct: 0.42),
    NasdaqStockItem(symbol: 'CHTR', name: 'Charter Communications', basePrice: 340.2, priceChange: 4.1, priceChangePct: 1.22),
    NasdaqStockItem(symbol: 'IDXX', name: 'IDEXX Laboratories', basePrice: 495.8, priceChange: 6.2, priceChangePct: 1.27),
    NasdaqStockItem(symbol: 'EXC', name: 'Exelon Corp.', basePrice: 38.9, priceChange: 0.25, priceChangePct: 0.65),
    NasdaqStockItem(symbol: 'BKR', name: 'Baker Hughes Co.', basePrice: 36.4, priceChange: -0.35, priceChangePct: -0.95),
    NasdaqStockItem(symbol: 'EA', name: 'Electronic Arts', basePrice: 148.6, priceChange: 1.3, priceChangePct: 0.88),
    NasdaqStockItem(symbol: 'CCEP', name: 'Coca-Cola Europacific', basePrice: 75.2, priceChange: 0.45, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'CSGP', name: 'CoStar Group', basePrice: 78.9, priceChange: -0.7, priceChangePct: -0.88),
    NasdaqStockItem(symbol: 'GEHC', name: 'GE HealthCare', basePrice: 84.1, priceChange: 0.9, priceChangePct: 1.08),
    NasdaqStockItem(symbol: 'ON', name: 'ON Semiconductor', basePrice: 76.5, priceChange: -1.2, priceChangePct: -1.54),
    NasdaqStockItem(symbol: 'BIIB', name: 'Biogen Inc.', basePrice: 218.4, priceChange: 1.6, priceChangePct: 0.74),
    NasdaqStockItem(symbol: 'DXCM', name: 'DexCom Inc.', basePrice: 115.3, priceChange: -2.4, priceChangePct: -2.04),
    NasdaqStockItem(symbol: 'WBD', name: 'Warner Bros. Discovery', basePrice: 7.8, priceChange: -0.15, priceChangePct: -1.89),
    NasdaqStockItem(symbol: 'ANSS', name: 'ANSYS Inc.', basePrice: 328.0, priceChange: 2.1, priceChangePct: 0.64),
    NasdaqStockItem(symbol: 'VRSK', name: 'Verisk Analytics', basePrice: 272.5, priceChange: 1.8, priceChangePct: 0.66),
    NasdaqStockItem(symbol: 'MDB', name: 'MongoDB Inc.', basePrice: 245.8, priceChange: 7.2, priceChangePct: 3.02),
    NasdaqStockItem(symbol: 'TEAM', name: 'Atlassian Corp.', basePrice: 178.4, priceChange: -3.6, priceChangePct: -1.98),
    NasdaqStockItem(symbol: 'DDOG', name: 'Datadog Inc.', basePrice: 122.5, priceChange: 3.4, priceChangePct: 2.85),
    NasdaqStockItem(symbol: 'ZS', name: 'Zscaler Inc.', basePrice: 192.3, priceChange: 4.1, priceChangePct: 2.18),
    NasdaqStockItem(symbol: 'CRWD', name: 'CrowdStrike Holdings', basePrice: 260.4, priceChange: -5.8, priceChangePct: -2.18),
    NasdaqStockItem(symbol: 'NET', name: 'Cloudflare Inc.', basePrice: 82.6, priceChange: 1.95, priceChangePct: 2.42),
    NasdaqStockItem(symbol: 'SNOW', name: 'Snowflake Inc.', basePrice: 134.8, priceChange: -2.2, priceChangePct: -1.61),
    NasdaqStockItem(symbol: 'PLTR', name: 'Palantir Technologies', basePrice: 28.4, priceChange: 0.95, priceChangePct: 3.46),
    NasdaqStockItem(symbol: 'COIN', name: 'Coinbase Global', basePrice: 225.1, priceChange: 8.6, priceChangePct: 3.97),
    NasdaqStockItem(symbol: 'ARM', name: 'Arm Holdings', basePrice: 142.3, priceChange: 5.2, priceChangePct: 3.79),
    NasdaqStockItem(symbol: 'SMCI', name: 'Super Micro Computer', basePrice: 620.5, priceChange: -18.4, priceChangePct: -2.88),
    NasdaqStockItem(symbol: 'HOOD', name: 'Robinhood Markets', basePrice: 22.8, priceChange: 0.75, priceChangePct: 3.4),
    NasdaqStockItem(symbol: 'UBER', name: 'Uber Technologies', basePrice: 74.5, priceChange: 1.3, priceChangePct: 1.78),
    NasdaqStockItem(symbol: 'DASH', name: 'DoorDash Inc.', basePrice: 118.2, priceChange: 2.6, priceChangePct: 2.25),
    NasdaqStockItem(symbol: 'ROKU', name: 'Roku Inc.', basePrice: 62.4, priceChange: -1.1, priceChangePct: -1.73),
    NasdaqStockItem(symbol: 'SQ', name: 'Block Inc.', basePrice: 64.8, priceChange: 0.9, priceChangePct: 1.41),
    NasdaqStockItem(symbol: 'SHOP', name: 'Shopify Inc.', basePrice: 68.2, priceChange: 1.4, priceChangePct: 2.1),
    NasdaqStockItem(symbol: 'SE', name: 'Sea Limited', basePrice: 72.9, priceChange: 2.1, priceChangePct: 2.97),
    NasdaqStockItem(symbol: 'TTWO', name: 'Take-Two Interactive', basePrice: 156.4, priceChange: -0.8, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'PDD', name: 'PDD Holdings', basePrice: 132.6, priceChange: 3.8, priceChangePct: 2.95),
    NasdaqStockItem(symbol: 'JD', name: 'JD.com Inc.', basePrice: 26.4, priceChange: -0.3, priceChangePct: -1.12),
    NasdaqStockItem(symbol: 'BIDU', name: 'Baidu Inc.', basePrice: 88.5, priceChange: 0.6, priceChangePct: 0.68),
    NasdaqStockItem(symbol: 'BABA', name: 'Alibaba Group', basePrice: 76.8, priceChange: 1.2, priceChangePct: 1.59),
    NasdaqStockItem(symbol: 'TSM', name: 'Taiwan Semiconductor', basePrice: 168.9, priceChange: 3.4, priceChangePct: 2.05),
    NasdaqStockItem(symbol: 'S', name: 'SentinelOne Inc.', basePrice: 21.4, priceChange: 0.45, priceChangePct: 2.15),
    NasdaqStockItem(symbol: 'U', name: 'Unity Software', basePrice: 16.8, priceChange: -0.5, priceChangePct: -2.89),
    NasdaqStockItem(symbol: 'RBLX', name: 'Roblox Corp.', basePrice: 38.6, priceChange: 1.1, priceChangePct: 2.93),
    NasdaqStockItem(symbol: 'TOST', name: 'Toast Inc.', basePrice: 25.2, priceChange: 0.8, priceChangePct: 3.28),
    NasdaqStockItem(symbol: 'APP', name: 'AppLovin Corp.', basePrice: 84.5, priceChange: 3.6, priceChangePct: 4.45),
    NasdaqStockItem(symbol: 'CART', name: 'Instacart Maplebear', basePrice: 34.1, priceChange: 0.5, priceChangePct: 1.49),
    NasdaqStockItem(symbol: 'GRAB', name: 'Grab Holdings', basePrice: 3.65, priceChange: 0.08, priceChangePct: 2.24),
    NasdaqStockItem(symbol: 'PATH', name: 'UiPath Inc.', basePrice: 12.8, priceChange: -0.25, priceChangePct: -1.92),
    NasdaqStockItem(symbol: 'Z', name: 'Zillow Group', basePrice: 52.4, priceChange: 1.15, priceChangePct: 2.24),
    NasdaqStockItem(symbol: 'DKNG', name: 'DraftKings Inc.', basePrice: 36.8, priceChange: 0.9, priceChangePct: 2.51),
    NasdaqStockItem(symbol: 'AFRM', name: 'Affirm Holdings', basePrice: 31.5, priceChange: 0.85, priceChangePct: 2.77),
    NasdaqStockItem(symbol: 'MRVL', name: 'Marvell Technology', basePrice: 72.3, priceChange: 0.17, priceChangePct: 0.24),
    NasdaqStockItem(symbol: 'WDAY', name: 'Workday Inc.', basePrice: 248.6, priceChange: -3.58, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'ILMN', name: 'Illumina Inc.', basePrice: 128.4, priceChange: 0.35, priceChangePct: 0.27),
    NasdaqStockItem(symbol: 'ALGN', name: 'Align Technology', basePrice: 235.8, priceChange: 3.04, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'CPRT', name: 'Copart Inc.', basePrice: 54.2, priceChange: 0.7, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'PAYC', name: 'Paycom Software', basePrice: 165.1, priceChange: -1.39, priceChangePct: -0.84),
    NasdaqStockItem(symbol: 'NTES', name: 'NetEase Inc.', basePrice: 94.7, priceChange: -0.65, priceChangePct: -0.69),
    NasdaqStockItem(symbol: 'AZN', name: 'AstraZeneca PLC', basePrice: 78.5, priceChange: 0.75, priceChangePct: 0.96),
    NasdaqStockItem(symbol: 'VRSN', name: 'VeriSign Inc.', basePrice: 182.3, priceChange: -2.02, priceChangePct: -1.11),
    NasdaqStockItem(symbol: 'SIRI', name: 'Sirius XM Holdings', basePrice: 26.5, priceChange: 0.06, priceChangePct: 0.23),
    NasdaqStockItem(symbol: 'EBAY', name: 'eBay Inc.', basePrice: 56.4, priceChange: -0.14, priceChangePct: -0.25),
    NasdaqStockItem(symbol: 'SWKS', name: 'Skyworks Solutions', basePrice: 104.2, priceChange: -0.59, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'TER', name: 'Teradyne Inc.', basePrice: 132.8, priceChange: -0.68, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'ENTG', name: 'Entegris Inc.', basePrice: 124.5, priceChange: 1.49, priceChangePct: 1.2),
    NasdaqStockItem(symbol: 'WBA', name: 'Walgreens Boots Alliance', basePrice: 11.2, priceChange: 0.12, priceChangePct: 1.07),
    NasdaqStockItem(symbol: 'DLTR', name: 'Dollar Tree Inc.', basePrice: 108.6, priceChange: 0.52, priceChangePct: 0.48),
    NasdaqStockItem(symbol: 'SPLK', name: 'Splunk Technologies', basePrice: 157.0, priceChange: 0.42, priceChangePct: 0.27),
    NasdaqStockItem(symbol: 'OKTA', name: 'Okta Inc.', basePrice: 88.4, priceChange: 1.35, priceChangePct: 1.53),
    NasdaqStockItem(symbol: 'TWLO', name: 'Twilio Inc.', basePrice: 62.8, priceChange: 0.08, priceChangePct: 0.13),
    NasdaqStockItem(symbol: 'DOCU', name: 'DocuSign Inc.', basePrice: 54.9, priceChange: 0.53, priceChangePct: 0.97),
    NasdaqStockItem(symbol: 'ZM', name: 'Zoom Video Communications', basePrice: 64.3, priceChange: -0.62, priceChangePct: -0.96),
    NasdaqStockItem(symbol: 'PINS', name: 'Pinterest Inc.', basePrice: 32.7, priceChange: 0.26, priceChangePct: 0.8),
    NasdaqStockItem(symbol: 'SNAP', name: 'Snap Inc.', basePrice: 10.4, priceChange: 0.15, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'FSLR', name: 'First Solar Inc.', basePrice: 215.6, priceChange: 3.1, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'ENPH', name: 'Enphase Energy', basePrice: 112.4, priceChange: 0.91, priceChangePct: 0.81),
    NasdaqStockItem(symbol: 'SEDG', name: 'SolarEdge Technologies', basePrice: 28.5, priceChange: -0.07, priceChangePct: -0.25),
    NasdaqStockItem(symbol: 'RUN', name: 'Sunrun Inc.', basePrice: 14.8, priceChange: 0.19, priceChangePct: 1.28),
    NasdaqStockItem(symbol: 'RIVN', name: 'Rivian Automotive', basePrice: 13.9, priceChange: 0.02, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'LCID', name: 'Lucid Group', basePrice: 3.45, priceChange: 0.02, priceChangePct: 0.58),
    NasdaqStockItem(symbol: 'NIO', name: 'NIO Inc.', basePrice: 4.25, priceChange: 0.05, priceChangePct: 1.18),
    NasdaqStockItem(symbol: 'XPEV', name: 'XPeng Inc.', basePrice: 8.1, priceChange: 0.1, priceChangePct: 1.23),
    NasdaqStockItem(symbol: 'LI', name: 'Li Auto Inc.', basePrice: 20.6, priceChange: -0.11, priceChangePct: -0.53),
    NasdaqStockItem(symbol: 'CEG', name: 'Constellation Energy', basePrice: 208.4, priceChange: -2.94, priceChangePct: -1.41),
    NasdaqStockItem(symbol: 'FANG', name: 'Diamondback Energy', basePrice: 188.7, priceChange: -0.23, priceChangePct: -0.12),
    NasdaqStockItem(symbol: 'TRGP', name: 'Targa Resources', basePrice: 135.2, priceChange: -0.32, priceChangePct: -0.24),
    NasdaqStockItem(symbol: 'EQIX', name: 'Equinix Inc.', basePrice: 842.0, priceChange: -1.52, priceChangePct: -0.18),
    NasdaqStockItem(symbol: 'DLR', name: 'Digital Realty Trust', basePrice: 152.6, priceChange: 2.2, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'SBAC', name: 'SBA Communications', basePrice: 218.4, priceChange: 1.64, priceChangePct: 0.75),
    NasdaqStockItem(symbol: 'AMT', name: 'American Tower', basePrice: 214.5, priceChange: -1.03, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'CCI', name: 'Crown Castle', basePrice: 110.8, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'XEL', name: 'Xcel Energy', basePrice: 58.9, priceChange: -0.71, priceChangePct: -1.21),
    NasdaqStockItem(symbol: 'AEP', name: 'American Electric Power', basePrice: 92.4, priceChange: -0.8, priceChangePct: -0.87),
    NasdaqStockItem(symbol: 'ED', name: 'Consolidated Edison', basePrice: 96.8, priceChange: 1.28, priceChangePct: 1.32),
    NasdaqStockItem(symbol: 'PEG', name: 'Public Service Enterprise', basePrice: 78.2, priceChange: -0.63, priceChangePct: -0.81),
    NasdaqStockItem(symbol: 'WEC', name: 'WEC Energy Group', basePrice: 84.6, priceChange: 0.51, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'ES', name: 'Eversource Energy', basePrice: 62.5, priceChange: -0.15, priceChangePct: -0.24),
    NasdaqStockItem(symbol: 'D', name: 'Dominion Energy', basePrice: 52.8, priceChange: 0.51, priceChangePct: 0.97),
    NasdaqStockItem(symbol: 'SO', name: 'Southern Company', basePrice: 82.4, priceChange: 0.67, priceChangePct: 0.81),
    NasdaqStockItem(symbol: 'DUK', name: 'Duke Energy', basePrice: 106.5, priceChange: -0.77, priceChangePct: -0.72),
    NasdaqStockItem(symbol: 'NEE', name: 'NextEra Energy', basePrice: 74.8, priceChange: 0.99, priceChangePct: 1.32),
    NasdaqStockItem(symbol: 'MRNA', name: 'Moderna Inc.', basePrice: 86.4, priceChange: 1.22, priceChangePct: 1.41),
    NasdaqStockItem(symbol: 'BNTX', name: 'BioNTech SE', basePrice: 88.2, priceChange: 0.03, priceChangePct: 0.03),
    NasdaqStockItem(symbol: 'NVAX', name: 'Novavax Inc.', basePrice: 12.6, priceChange: -0.02, priceChangePct: -0.16),
    NasdaqStockItem(symbol: 'ALNY', name: 'Alnylam Pharmaceuticals', basePrice: 242.0, priceChange: -0.44, priceChangePct: -0.18),
    NasdaqStockItem(symbol: 'BMRN', name: 'BioMarin Pharmaceutical', basePrice: 82.5, priceChange: 0.59, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'EXAS', name: 'Exact Sciences', basePrice: 58.7, priceChange: -0.44, priceChangePct: -0.75),
    NasdaqStockItem(symbol: 'INCY', name: 'Incyte Corp.', basePrice: 62.4, priceChange: -0.9, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'SRPT', name: 'Sarepta Therapeutics', basePrice: 128.5, priceChange: 0.77, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'BGNE', name: 'BeiGene Ltd.', basePrice: 184.2, priceChange: -0.66, priceChangePct: -0.36),
    NasdaqStockItem(symbol: 'LEGN', name: 'Legend Biotech', basePrice: 46.8, priceChange: -0.45, priceChangePct: -0.96),
    NasdaqStockItem(symbol: 'CRSP', name: 'CRISPR Therapeutics', basePrice: 52.3, priceChange: -0.75, priceChangePct: -1.43),
    NasdaqStockItem(symbol: 'NTLA', name: 'Intellia Therapeutics', basePrice: 22.4, priceChange: 0.05, priceChangePct: 0.22),
    NasdaqStockItem(symbol: 'EDIT', name: 'Editas Medicine', basePrice: 5.6, priceChange: -0.05, priceChangePct: -0.89),
    NasdaqStockItem(symbol: 'BEAM', name: 'Beam Therapeutics', basePrice: 26.8, priceChange: -0.12, priceChangePct: -0.45),
    NasdaqStockItem(symbol: 'PACB', name: 'Pacific Biosciences', basePrice: 1.85, priceChange: -0.02, priceChangePct: -1.08),
    NasdaqStockItem(symbol: 'TWST', name: 'Twist Bioscience', basePrice: 46.2, priceChange: 0.71, priceChangePct: 1.54),
    NasdaqStockItem(symbol: 'TXG', name: '10x Genomics', basePrice: 18.9, priceChange: 0.14, priceChangePct: 0.74),
    NasdaqStockItem(symbol: 'QDEL', name: 'QuidelOrtho Corp.', basePrice: 42.5, priceChange: -0.36, priceChangePct: -0.85),
    NasdaqStockItem(symbol: 'HOLX', name: 'Hologic Inc.', basePrice: 78.6, priceChange: -0.57, priceChangePct: -0.73),
    NasdaqStockItem(symbol: 'TFX', name: 'Teleflex Inc.', basePrice: 235.4, priceChange: 3.18, priceChangePct: 1.35),
    NasdaqStockItem(symbol: 'PODD', name: 'Insulet Corp.', basePrice: 198.5, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'MASI', name: 'Masimo Corp.', basePrice: 126.8, priceChange: -1.22, priceChangePct: -0.96),
    NasdaqStockItem(symbol: 'PEN', name: 'Penumbra Inc.', basePrice: 184.5, priceChange: -1.99, priceChangePct: -1.08),
    NasdaqStockItem(symbol: 'NVCR', name: 'NovoCure Ltd.', basePrice: 16.4, priceChange: -0.06, priceChangePct: -0.37),
    NasdaqStockItem(symbol: 'GKOS', name: 'Glaukos Corp.', basePrice: 118.6, priceChange: -1.71, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'SWAV', name: 'Shockwave Medical', basePrice: 332.0, priceChange: -1.59, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'AXNX', name: 'Axonics Inc.', basePrice: 68.5, priceChange: -0.99, priceChangePct: -1.45),
    NasdaqStockItem(symbol: 'IRTC', name: 'iRhythm Technologies', basePrice: 104.2, priceChange: -0.59, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'GMED', name: 'Globus Medical', basePrice: 68.4, priceChange: 0.39, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'TNDM', name: 'Tandem Diabetes Care', basePrice: 42.6, priceChange: 0.22, priceChangePct: 0.52),
    NasdaqStockItem(symbol: 'SYM', name: 'Symbotic Inc.', basePrice: 24.8, priceChange: 0.01, priceChangePct: 0.04),
    NasdaqStockItem(symbol: 'AUR', name: 'Aurora Innovation', basePrice: 4.85, priceChange: -0.03, priceChangePct: -0.62),
    NasdaqStockItem(symbol: 'OUST', name: 'Ouster Inc.', basePrice: 12.6, priceChange: -0.02, priceChangePct: -0.16),
    NasdaqStockItem(symbol: 'LAZR', name: 'Luminar Technologies', basePrice: 1.45, priceChange: -0.01, priceChangePct: -0.69),
    NasdaqStockItem(symbol: 'HSAI', name: 'Hesai Group', basePrice: 4.6, priceChange: -0.02, priceChangePct: -0.43),
    NasdaqStockItem(symbol: 'INVZ', name: 'Innoviz Technologies', basePrice: 0.95, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'AEVA', name: 'Aeva Technologies', basePrice: 2.8, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'JOBY', name: 'Joby Aviation', basePrice: 5.2, priceChange: -0.04, priceChangePct: -0.77),
    NasdaqStockItem(symbol: 'ACHR', name: 'Archer Aviation', basePrice: 3.85, priceChange: 0.06, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'EH', name: 'EHang Holdings', basePrice: 14.6, priceChange: -0.16, priceChangePct: -1.1),
    NasdaqStockItem(symbol: 'LILM', name: 'Lilium N.V.', basePrice: 0.85, priceChange: 0.01, priceChangePct: 1.18),
    NasdaqStockItem(symbol: 'EVLV', name: 'Evolv Technologies', basePrice: 2.65, priceChange: -0.01, priceChangePct: -0.38),
    NasdaqStockItem(symbol: 'ASTS', name: 'AST SpaceMobile', basePrice: 21.8, priceChange: 0.09, priceChangePct: 0.41),
    NasdaqStockItem(symbol: 'RKLB', name: 'Rocket Lab USA', basePrice: 5.4, priceChange: -0.07, priceChangePct: -1.3),
    NasdaqStockItem(symbol: 'PL', name: 'Planet Labs PBC', basePrice: 2.15, priceChange: 0.01, priceChangePct: 0.47),
    NasdaqStockItem(symbol: 'BKSY', name: 'BlackSky Technology', basePrice: 1.35, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'SPIR', name: 'Spire Global', basePrice: 11.2, priceChange: 0.12, priceChangePct: 1.07),
    NasdaqStockItem(symbol: 'RDW', name: 'Redwire Corp.', basePrice: 6.8, priceChange: 0.03, priceChangePct: 0.44),
    NasdaqStockItem(symbol: 'LUNR', name: 'Intuitive Machines', basePrice: 5.45, priceChange: -0.05, priceChangePct: -0.92),
    NasdaqStockItem(symbol: 'MNTS', name: 'Momentus Inc.', basePrice: 0.65, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'IONQ', name: 'IonQ Inc.', basePrice: 7.8, priceChange: -0.04, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'RGTI', name: 'Rigetti Computing', basePrice: 1.15, priceChange: -0.01, priceChangePct: -0.87),
    NasdaqStockItem(symbol: 'QBTS', name: 'D-Wave Quantum', basePrice: 1.05, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'QUBT', name: 'Quantum Computing', basePrice: 0.85, priceChange: 0.01, priceChangePct: 1.18),
    NasdaqStockItem(symbol: 'ARQQ', name: 'Arqit Quantum', basePrice: 0.55, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'AI', name: 'C3.ai Inc.', basePrice: 22.4, priceChange: 0.05, priceChangePct: 0.22),
    NasdaqStockItem(symbol: 'BBAI', name: 'BigBear.ai Holdings', basePrice: 1.65, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'SOUN', name: 'SoundHound AI', basePrice: 5.1, priceChange: 0.04, priceChangePct: 0.78),
    NasdaqStockItem(symbol: 'ASTR', name: 'Astra Space', basePrice: 0.75, priceChange: -0.01, priceChangePct: -1.33),
    NasdaqStockItem(symbol: 'UPST', name: 'Upstart Holdings', basePrice: 36.4, priceChange: 0.31, priceChangePct: 0.85),
    NasdaqStockItem(symbol: 'MQ', name: 'Marqeta Inc.', basePrice: 5.25, priceChange: 0.01, priceChangePct: 0.19),
    NasdaqStockItem(symbol: 'FLY', name: 'Flywire Corp.', basePrice: 18.6, priceChange: -0.01, priceChangePct: -0.05),
    NasdaqStockItem(symbol: 'RELY', name: 'Remitly Global', basePrice: 14.2, priceChange: 0.14, priceChangePct: 0.99),
    NasdaqStockItem(symbol: 'DLO', name: 'DLocal Ltd.', basePrice: 8.9, priceChange: -0.1, priceChangePct: -1.12),
    NasdaqStockItem(symbol: 'NU', name: 'Nu Holdings Ltd.', basePrice: 12.8, priceChange: -0.1, priceChangePct: -0.78),
    NasdaqStockItem(symbol: 'PAGS', name: 'PagSeguro Digital', basePrice: 11.4, priceChange: 0.11, priceChangePct: 0.96),
    NasdaqStockItem(symbol: 'STNE', name: 'StoneCo Ltd.', basePrice: 12.1, priceChange: -0.09, priceChangePct: -0.74),
    NasdaqStockItem(symbol: 'GTLB', name: 'GitLab Inc.', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'HCP', name: 'HashiCorp Inc.', basePrice: 33.8, priceChange: -0.49, priceChangePct: -1.45),
    NasdaqStockItem(symbol: 'CFLT', name: 'Confluent Inc.', basePrice: 21.5, priceChange: 0.31, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'ESTC', name: 'Elastic N.V.', basePrice: 76.4, priceChange: 0.07, priceChangePct: 0.09),
    NasdaqStockItem(symbol: 'MNDY', name: 'Monday.com Ltd.', basePrice: 228.5, priceChange: 1.37, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'ASAN', name: 'Asana Inc.', basePrice: 13.4, priceChange: 0.05, priceChangePct: 0.37),
    NasdaqStockItem(symbol: 'SMAR', name: 'Smartsheet Inc.', basePrice: 49.8, priceChange: -0.18, priceChangePct: -0.36),
    NasdaqStockItem(symbol: 'FIVN', name: 'Five9 Inc.', basePrice: 32.6, priceChange: 0.44, priceChangePct: 1.35),
    NasdaqStockItem(symbol: 'RNG', name: 'RingCentral Inc.', basePrice: 31.4, priceChange: 0.34, priceChangePct: 1.08),
    NasdaqStockItem(symbol: 'BAND', name: 'Bandwidth Inc.', basePrice: 18.2, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'VRNS', name: 'Varonis Systems', basePrice: 54.8, priceChange: 0.39, priceChangePct: 0.71),
    NasdaqStockItem(symbol: 'TENB', name: 'Tenable Holdings', basePrice: 42.3, priceChange: 0.61, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'RPD', name: 'Rapid7 Inc.', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'QLYS', name: 'Qualys Inc.', basePrice: 135.2, priceChange: -0.32, priceChangePct: -0.24),
    NasdaqStockItem(symbol: 'CYBR', name: 'CyberArk Software', basePrice: 268.4, priceChange: 1.93, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'SAIL', name: 'SailPoint Tech', basePrice: 64.2, priceChange: 0.71, priceChangePct: 1.11),
    NasdaqStockItem(symbol: 'CHKP', name: 'Check Point Software', basePrice: 174.5, priceChange: 1.26, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'GEN', name: 'Gen Digital Inc.', basePrice: 24.8, priceChange: 0.01, priceChangePct: 0.04),
    NasdaqStockItem(symbol: 'BL', name: 'BlackLine Inc.', basePrice: 52.6, priceChange: -0.17, priceChangePct: -0.32),
    NasdaqStockItem(symbol: 'ALTR', name: 'Altair Engineering', basePrice: 96.4, priceChange: -1.19, priceChangePct: -1.23),
    NasdaqStockItem(symbol: 'PTC', name: 'PTC Inc.', basePrice: 178.5, priceChange: 1.07, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'MANH', name: 'Manhattan Associates', basePrice: 242.0, priceChange: -0.44, priceChangePct: -0.18),
    NasdaqStockItem(symbol: 'SPSX', name: 'SPS Commerce', basePrice: 198.4, priceChange: 0.54, priceChangePct: 0.27),
    NasdaqStockItem(symbol: 'APPF', name: 'AppFolio Inc.', basePrice: 235.6, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'ALRM', name: 'Alarm.com Holdings', basePrice: 56.8, priceChange: -0.48, priceChangePct: -0.85),
    NasdaqStockItem(symbol: 'EBIX', name: 'Ebix Inc.', basePrice: 4.2, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'VERX', name: 'Vertex Inc.', basePrice: 36.4, priceChange: 0.31, priceChangePct: 0.85),
    NasdaqStockItem(symbol: 'AVDX', name: 'AvidXchange Holdings', basePrice: 9.4, priceChange: -0.13, priceChangePct: -1.38),
    NasdaqStockItem(symbol: 'BILL', name: 'BILL Holdings', basePrice: 51.2, priceChange: 0.29, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'COUP', name: 'Coupa Software', basePrice: 81.0, priceChange: 0.8, priceChangePct: 0.99),
    NasdaqStockItem(symbol: 'PCOR', name: 'Procore Technologies', basePrice: 64.8, priceChange: 0.16, priceChangePct: 0.25),
    NasdaqStockItem(symbol: 'DOCN', name: 'DigitalOcean Holdings', basePrice: 32.6, priceChange: 0.44, priceChangePct: 1.35),
    NasdaqStockItem(symbol: 'FSLY', name: 'Fastly Inc.', basePrice: 7.4, priceChange: 0.04, priceChangePct: 0.54),
    NasdaqStockItem(symbol: 'AKAM', name: 'Akamai Technologies', basePrice: 98.6, priceChange: -0.59, priceChangePct: -0.6),
    NasdaqStockItem(symbol: 'NTNX', name: 'Nutanix Inc.', basePrice: 54.2, priceChange: 0.7, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'PSTG', name: 'Pure Storage', basePrice: 58.4, priceChange: 0.21, priceChangePct: 0.36),
    NasdaqStockItem(symbol: 'WDC', name: 'Western Digital', basePrice: 64.8, priceChange: 0.16, priceChangePct: 0.25),
    NasdaqStockItem(symbol: 'STX', name: 'Seagate Technology', basePrice: 102.5, priceChange: -0.49, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'QRVO', name: 'Qorvo Inc.', basePrice: 108.4, priceChange: -1.2, priceChangePct: -1.11),
    NasdaqStockItem(symbol: 'CRUS', name: 'Cirrus Logic', basePrice: 124.6, priceChange: -0.15, priceChangePct: -0.12),
    NasdaqStockItem(symbol: 'SLAB', name: 'Silicon Laboratories', basePrice: 114.2, priceChange: 1.27, priceChangePct: 1.11),
    NasdaqStockItem(symbol: 'DIOD', name: 'Diodes Inc.', basePrice: 72.8, priceChange: 1.05, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'POWI', name: 'Power Integrations', basePrice: 68.4, priceChange: 0.39, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'MPWR', name: 'Monolithic Power', basePrice: 840.5, priceChange: 12.1, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'SIMO', name: 'Silicon Motion Technology', basePrice: 62.4, priceChange: -0.9, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'RMBS', name: 'Rambus Inc.', basePrice: 52.8, priceChange: 0.51, priceChangePct: 0.97),
    NasdaqStockItem(symbol: 'SITM', name: 'SiTime Corp.', basePrice: 118.4, priceChange: 0.25, priceChangePct: 0.21),
    NasdaqStockItem(symbol: 'ACLS', name: 'Axcelis Technologies', basePrice: 108.6, priceChange: 0.52, priceChangePct: 0.48),
    NasdaqStockItem(symbol: 'CCCS', name: 'CCC Intelligent Solutions', basePrice: 11.8, priceChange: -0.12, priceChangePct: -1.02),
    NasdaqStockItem(symbol: 'EXTR', name: 'Extreme Networks', basePrice: 12.4, priceChange: 0.11, priceChangePct: 0.89),
    NasdaqStockItem(symbol: 'CIEN', name: 'Ciena Corp.', basePrice: 52.6, priceChange: -0.17, priceChangePct: -0.32),
    NasdaqStockItem(symbol: 'INFN', name: 'Infinera Corp.', basePrice: 6.4, priceChange: 0.1, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'CALX', name: 'Calix Inc.', basePrice: 34.8, priceChange: 0.5, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'ADTN', name: 'ADTRAN Holdings', basePrice: 5.6, priceChange: -0.05, priceChangePct: -0.89),
    NasdaqStockItem(symbol: 'VIAV', name: 'Viavi Solutions', basePrice: 8.4, priceChange: -0.08, priceChangePct: -0.95),
    NasdaqStockItem(symbol: 'LITE', name: 'Lumentum Holdings', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'COHR', name: 'Coherent Corp.', basePrice: 74.2, priceChange: -0.42, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'IPGP', name: 'IPG Photonics', basePrice: 78.5, priceChange: 0.75, priceChangePct: 0.96),
    NasdaqStockItem(symbol: 'NOVT', name: 'Novanta Inc.', basePrice: 164.2, priceChange: -2.36, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'CGNX', name: 'Cognex Corp.', basePrice: 42.8, priceChange: 0.36, priceChangePct: 0.84),
    NasdaqStockItem(symbol: 'FARO', name: 'FARO Technologies', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'KEYS', name: 'Keysight Technologies', basePrice: 142.6, priceChange: -2.05, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'NATI', name: 'National Instruments', basePrice: 59.8, priceChange: -0.72, priceChangePct: -1.2),
    NasdaqStockItem(symbol: 'ITRI', name: 'Itron Inc.', basePrice: 104.2, priceChange: -0.59, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'OSIS', name: 'OSI Systems', basePrice: 142.8, priceChange: 2.18, priceChangePct: 1.53),
    NasdaqStockItem(symbol: 'AEIS', name: 'Advanced Energy', basePrice: 102.4, priceChange: 1.2, priceChangePct: 1.17),
    NasdaqStockItem(symbol: 'VICR', name: 'Vicor Corp.', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'SANM', name: 'Sanmina Corp.', basePrice: 64.2, priceChange: 0.71, priceChangePct: 1.11),
    NasdaqStockItem(symbol: 'PLEX', name: 'Plexus Corp.', basePrice: 114.8, priceChange: 0.28, priceChangePct: 0.24),
    NasdaqStockItem(symbol: 'TTMI', name: 'TTM Technologies', basePrice: 18.6, priceChange: -0.01, priceChangePct: -0.05),
    NasdaqStockItem(symbol: 'CTS', name: 'CTS Corp.', basePrice: 44.2, priceChange: 0.41, priceChangePct: 0.93),
    NasdaqStockItem(symbol: 'KBAL', name: 'Kimball Electronics', basePrice: 22.4, priceChange: 0.05, priceChangePct: 0.22),
    NasdaqStockItem(symbol: 'BHE', name: 'Benchmark Electronics', basePrice: 38.5, priceChange: -0.14, priceChangePct: -0.36),
    NasdaqStockItem(symbol: 'MMSI', name: 'Merit Medical Systems', basePrice: 84.6, priceChange: 0.51, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'ATRC', name: 'AtriCure Inc.', basePrice: 28.4, priceChange: 0.03, priceChangePct: 0.11),
    NasdaqStockItem(symbol: 'LMAT', name: 'LeMaitre Vascular', basePrice: 78.2, priceChange: -0.63, priceChangePct: -0.81),
    NasdaqStockItem(symbol: 'CNMD', name: 'CONMED Corp.', basePrice: 72.4, priceChange: -0.37, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'ANGO', name: 'AngioDynamics', basePrice: 6.8, priceChange: 0.03, priceChangePct: 0.44),
    NasdaqStockItem(symbol: 'UTHR', name: 'United Therapeutics', basePrice: 318.5, priceChange: -1.91, priceChangePct: -0.6),
    NasdaqStockItem(symbol: 'NBIX', name: 'Neurocrine Biosciences', basePrice: 138.4, priceChange: -0.79, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'HALO', name: 'Halozyme Therapeutics', basePrice: 52.6, priceChange: -0.17, priceChangePct: -0.32),
    NasdaqStockItem(symbol: 'JAZZ', name: 'Jazz Pharmaceuticals', basePrice: 112.4, priceChange: 0.91, priceChangePct: 0.81),
    NasdaqStockItem(symbol: 'EXEL', name: 'Exelixis Inc.', basePrice: 24.8, priceChange: 0.01, priceChangePct: 0.04),
    NasdaqStockItem(symbol: 'IONS', name: 'Ionis Pharmaceuticals', basePrice: 44.6, priceChange: 0.12, priceChangePct: 0.27),
    NasdaqStockItem(symbol: 'FOLD', name: 'Amicus Therapeutics', basePrice: 11.2, priceChange: 0.12, priceChangePct: 1.07),
    NasdaqStockItem(symbol: 'AGIO', name: 'Agios Pharmaceuticals', basePrice: 46.8, priceChange: -0.45, priceChangePct: -0.96),
    NasdaqStockItem(symbol: 'BLUE', name: 'bluebird bio', basePrice: 0.85, priceChange: 0.01, priceChangePct: 1.18),
    NasdaqStockItem(symbol: 'FATE', name: 'Fate Therapeutics', basePrice: 3.4, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'SGMO', name: 'Sangamo Therapeutics', basePrice: 0.72, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'ALLO', name: 'Allogene Therapeutics', basePrice: 2.85, priceChange: -0.01, priceChangePct: -0.35),
    NasdaqStockItem(symbol: 'KYMR', name: 'Kymera Therapeutics', basePrice: 38.4, priceChange: 0.55, priceChangePct: 1.43),
    NasdaqStockItem(symbol: 'ARVN', name: 'Arvinas Inc.', basePrice: 26.2, priceChange: 0.28, priceChangePct: 1.07),
    NasdaqStockItem(symbol: 'PRTA', name: 'Prothena Corp.', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'RGNX', name: 'REGENXBIO Inc.', basePrice: 12.6, priceChange: -0.02, priceChangePct: -0.16),
    NasdaqStockItem(symbol: 'KURA', name: 'Kura Oncology', basePrice: 18.2, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'MRTX', name: 'Mirati Therapeutics', basePrice: 58.0, priceChange: 0.17, priceChangePct: 0.29),
    NasdaqStockItem(symbol: 'KRYS', name: 'Krystal Biotech', basePrice: 178.4, priceChange: -2.52, priceChangePct: -1.41),
    NasdaqStockItem(symbol: 'APLS', name: 'Apellis Pharmaceuticals', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'PRAX', name: 'Praxis Precision', basePrice: 48.2, priceChange: 0.56, priceChangePct: 1.16),
    NasdaqStockItem(symbol: 'VKTX', name: 'Viking Therapeutics', basePrice: 58.4, priceChange: 0.21, priceChangePct: 0.36),
    NasdaqStockItem(symbol: 'ALT', name: 'Altimmune Inc.', basePrice: 6.8, priceChange: 0.03, priceChangePct: 0.44),
    NasdaqStockItem(symbol: 'CRNX', name: 'Crinetics Pharmaceuticals', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'MDGL', name: 'Madrigal Pharmaceuticals', basePrice: 242.0, priceChange: -0.44, priceChangePct: -0.18),
    NasdaqStockItem(symbol: 'CYTK', name: 'Cytokinetics Inc.', basePrice: 54.8, priceChange: 0.39, priceChangePct: 0.71),
    NasdaqStockItem(symbol: 'BPMC', name: 'Blueprint Medicines', basePrice: 98.4, priceChange: 0.56, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'MOR', name: 'MorphoSys AG', basePrice: 18.2, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'ARWR', name: 'Arrowhead Pharmaceuticals', basePrice: 22.4, priceChange: 0.05, priceChangePct: 0.22),
    NasdaqStockItem(symbol: 'DCPH', name: 'Deciphera Pharmaceuticals', basePrice: 25.4, priceChange: 0.12, priceChangePct: 0.47),
    NasdaqStockItem(symbol: 'KROS', name: 'Keros Therapeutics', basePrice: 52.8, priceChange: 0.51, priceChangePct: 0.97),
    NasdaqStockItem(symbol: 'IMVT', name: 'Immunovant Inc.', basePrice: 28.4, priceChange: 0.03, priceChangePct: 0.11),
    NasdaqStockItem(symbol: 'ROIV', name: 'Roivant Sciences', basePrice: 11.6, priceChange: -0.11, priceChangePct: -0.95),
    NasdaqStockItem(symbol: 'RPRX', name: 'Royalty Pharma', basePrice: 28.2, priceChange: -0.3, priceChangePct: -1.06),
    NasdaqStockItem(symbol: 'CORT', name: 'Corcept Therapeutics', basePrice: 34.5, priceChange: 0.04, priceChangePct: 0.12),
    NasdaqStockItem(symbol: 'SUPN', name: 'Supernus Pharmaceuticals', basePrice: 32.8, priceChange: -0.43, priceChangePct: -1.31),
    NasdaqStockItem(symbol: 'CDNA', name: 'CareDx Inc.', basePrice: 24.6, priceChange: -0.18, priceChangePct: -0.73),
    NasdaqStockItem(symbol: 'NTRA', name: 'Natera Inc.', basePrice: 118.5, priceChange: -1.71, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'GH', name: 'Guardant Health', basePrice: 28.4, priceChange: 0.03, priceChangePct: 0.11),
    NasdaqStockItem(symbol: 'NVST', name: 'Envista Holdings', basePrice: 18.2, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'PDCO', name: 'Patterson Companies', basePrice: 24.8, priceChange: 0.01, priceChangePct: 0.04),
    NasdaqStockItem(symbol: 'HSIC', name: 'Henry Schein', basePrice: 72.4, priceChange: -0.37, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'PRGO', name: 'Perrigo Company', basePrice: 28.6, priceChange: 0.37, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'AMPH', name: 'Amphastar Pharmaceuticals', basePrice: 44.2, priceChange: 0.41, priceChangePct: 0.93),
    NasdaqStockItem(symbol: 'COLL', name: 'Collegium Pharmaceutical', basePrice: 34.8, priceChange: 0.5, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'INVA', name: 'Innoviva Inc.', basePrice: 16.2, priceChange: -0.19, priceChangePct: -1.17),
    NasdaqStockItem(symbol: 'CPRX', name: 'Catalyst Pharmaceuticals', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'ANIP', name: 'ANI Pharmaceuticals', basePrice: 56.8, priceChange: -0.48, priceChangePct: -0.85),
    NasdaqStockItem(symbol: 'EBS', name: 'Emergent BioSolutions', basePrice: 8.2, priceChange: 0.04, priceChangePct: 0.49),
    NasdaqStockItem(symbol: 'HELE', name: 'Helen of Troy', basePrice: 62.4, priceChange: -0.9, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'CENT', name: 'Central Garden & Pet', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'FRPT', name: 'Freshpet Inc.', basePrice: 128.4, priceChange: 0.35, priceChangePct: 0.27),
    NasdaqStockItem(symbol: 'HAIN', name: 'Hain Celestial Group', basePrice: 7.4, priceChange: 0.04, priceChangePct: 0.54),
    NasdaqStockItem(symbol: 'SMPL', name: 'Simply Good Foods', basePrice: 36.8, priceChange: -0.04, priceChangePct: -0.11),
    NasdaqStockItem(symbol: 'FIZZ', name: 'National Beverage', basePrice: 46.2, priceChange: 0.71, priceChangePct: 1.54),
    NasdaqStockItem(symbol: 'CALM', name: 'Cal-Maine Foods', basePrice: 68.4, priceChange: 0.39, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'LWAY', name: 'Lifeway Foods', basePrice: 18.6, priceChange: -0.01, priceChangePct: -0.05),
    NasdaqStockItem(symbol: 'BRID', name: 'Bridgford Foods', basePrice: 12.4, priceChange: 0.11, priceChangePct: 0.89),
    NasdaqStockItem(symbol: 'JACK', name: 'Jack in the Box', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'WEN', name: 'Wendy\'s Company', basePrice: 16.8, priceChange: 0.21, priceChangePct: 1.25),
    NasdaqStockItem(symbol: 'PZZA', name: 'Papa John\'s International', basePrice: 46.2, priceChange: 0.71, priceChangePct: 1.54),
    NasdaqStockItem(symbol: 'WING', name: 'Wingstop Inc.', basePrice: 368.5, priceChange: -2.21, priceChangePct: -0.6),
    NasdaqStockItem(symbol: 'SHAK', name: 'Shake Shack Inc.', basePrice: 98.4, priceChange: 0.56, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'CAVA', name: 'CAVA Group Inc.', basePrice: 94.2, priceChange: -1.33, priceChangePct: -1.41),
    NasdaqStockItem(symbol: 'SG', name: 'Sweetgreen Inc.', basePrice: 28.6, priceChange: 0.37, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'BROS', name: 'Dutch Bros Inc.', basePrice: 34.8, priceChange: 0.5, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'CBRL', name: 'Cracker Barrel', basePrice: 42.6, priceChange: 0.22, priceChangePct: 0.52),
    NasdaqStockItem(symbol: 'TXRH', name: 'Texas Roadhouse', basePrice: 168.4, priceChange: -0.96, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'CHUY', name: 'Chuy\'s Holdings', basePrice: 37.4, priceChange: 0.27, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'BLMN', name: 'Bloomin\' Brands', basePrice: 18.2, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'PLAY', name: 'Dave & Buster\'s', basePrice: 36.8, priceChange: -0.04, priceChangePct: -0.11),
    NasdaqStockItem(symbol: 'RRGB', name: 'Red Robin Gourmet', basePrice: 6.4, priceChange: 0.1, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'DIN', name: 'Dine Brands Global', basePrice: 38.5, priceChange: -0.14, priceChangePct: -0.36),
    NasdaqStockItem(symbol: 'DENN', name: 'Denny\'s Corp.', basePrice: 6.2, priceChange: -0.08, priceChangePct: -1.29),
    NasdaqStockItem(symbol: 'BJRI', name: 'BJ\'s Restaurants', basePrice: 32.4, priceChange: -0.12, priceChangePct: -0.37),
    NasdaqStockItem(symbol: 'LOCO', name: 'El Pollo Loco', basePrice: 11.2, priceChange: 0.12, priceChangePct: 1.07),
    NasdaqStockItem(symbol: 'PTLO', name: 'Portillo\'s Inc.', basePrice: 11.8, priceChange: -0.12, priceChangePct: -1.02),
    NasdaqStockItem(symbol: 'KRUS', name: 'Kura Sushi USA', basePrice: 68.4, priceChange: 0.39, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'NDLS', name: 'Noodles & Company', basePrice: 1.45, priceChange: -0.01, priceChangePct: -0.69),
    NasdaqStockItem(symbol: 'TAST', name: 'Carrols Restaurant Group', basePrice: 9.5, priceChange: -0.01, priceChangePct: -0.11),
    NasdaqStockItem(symbol: 'RAVE', name: 'Rave Restaurant Group', basePrice: 1.85, priceChange: -0.02, priceChangePct: -1.08),
    NasdaqStockItem(symbol: 'FAT', name: 'FAT Brands Inc.', basePrice: 5.8, priceChange: 0.08, priceChangePct: 1.38),
    NasdaqStockItem(symbol: 'ARCO', name: 'Arcos Dorados', basePrice: 9.8, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'YUMC', name: 'Yum China Holdings', basePrice: 34.2, priceChange: -0.01, priceChangePct: -0.03),
    NasdaqStockItem(symbol: 'QSR', name: 'Restaurant Brands Intl', basePrice: 72.4, priceChange: -0.37, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'DPZ', name: 'Domino\'s Pizza', basePrice: 432.0, priceChange: -2.07, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'CMG', name: 'Chipotle Mexican Grill', basePrice: 54.8, priceChange: 0.39, priceChangePct: 0.71),
    NasdaqStockItem(symbol: 'PTON', name: 'Peloton Interactive', basePrice: 3.85, priceChange: 0.06, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'CHWY', name: 'Chewy Inc.', basePrice: 26.4, priceChange: -0.29, priceChangePct: -1.1),
    NasdaqStockItem(symbol: 'W', name: 'Wayfair Inc.', basePrice: 48.2, priceChange: 0.56, priceChangePct: 1.16),
    NasdaqStockItem(symbol: 'ETSY', name: 'Etsy Inc.', basePrice: 54.6, priceChange: -0.31, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'CPNG', name: 'Coupang Inc.', basePrice: 21.8, priceChange: 0.09, priceChangePct: 0.41),
    NasdaqStockItem(symbol: 'OZON', name: 'Ozon Holdings', basePrice: 16.4, priceChange: -0.06, priceChangePct: -0.37),
    NasdaqStockItem(symbol: 'JMIA', name: 'Jumia Technologies', basePrice: 5.2, priceChange: -0.04, priceChangePct: -0.77),
    NasdaqStockItem(symbol: 'POSH', name: 'Poshmark Marketplace', basePrice: 17.8, priceChange: 0.18, priceChangePct: 1.01),
    NasdaqStockItem(symbol: 'REAL', name: 'The RealReal', basePrice: 3.2, priceChange: 0.03, priceChangePct: 0.94),
    NasdaqStockItem(symbol: 'THRED', name: 'ThredUp Inc.', basePrice: 1.65, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'RENT', name: 'Rent the Runway', basePrice: 14.8, priceChange: 0.19, priceChangePct: 1.28),
    NasdaqStockItem(symbol: 'STITCH', name: 'Stitch Fix Inc.', basePrice: 2.45, priceChange: -0.03, priceChangePct: -1.22),
    NasdaqStockItem(symbol: 'BARK', name: 'BARK Inc.', basePrice: 1.35, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'PETS', name: 'PetMed Express', basePrice: 4.2, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'WOOF', name: 'Petco Health & Wellness', basePrice: 3.1, priceChange: -0.01, priceChangePct: -0.32),
    NasdaqStockItem(symbol: 'APRN', name: 'Blue Apron Holdings', basePrice: 12.4, priceChange: 0.11, priceChangePct: 0.89),
    NasdaqStockItem(symbol: 'BYND', name: 'Beyond Meat Inc.', basePrice: 6.4, priceChange: 0.1, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'OTLY', name: 'Oatly Group AB', basePrice: 0.85, priceChange: 0.01, priceChangePct: 1.18),
    NasdaqStockItem(symbol: 'TTCF', name: 'Tattooed Chef', basePrice: 0.45, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'VITL', name: 'Vital Farms Inc.', basePrice: 34.8, priceChange: 0.5, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'SOVO', name: 'Sovos Brands', basePrice: 22.8, priceChange: 0.03, priceChangePct: 0.13),
    NasdaqStockItem(symbol: 'BRBR', name: 'BellRing Brands', basePrice: 58.4, priceChange: 0.21, priceChangePct: 0.36),
    NasdaqStockItem(symbol: 'UTZ', name: 'Utz Brands Inc.', basePrice: 16.2, priceChange: -0.19, priceChangePct: -1.17),
    NasdaqStockItem(symbol: 'SNBR', name: 'Sleep Number Corp.', basePrice: 12.8, priceChange: -0.1, priceChangePct: -0.78),
    NasdaqStockItem(symbol: 'PRPL', name: 'Purple Innovation', basePrice: 0.95, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'LOVE', name: 'The Lovesac Company', basePrice: 24.6, priceChange: -0.18, priceChangePct: -0.73),
    NasdaqStockItem(symbol: 'WSM', name: 'Williams-Sonoma', basePrice: 142.5, priceChange: -1.88, priceChangePct: -1.32),
    NasdaqStockItem(symbol: 'RH', name: 'RH (Restoration Hardware)', basePrice: 268.0, priceChange: 1.61, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'ARHA', name: 'Arhaus Inc.', basePrice: 10.4, priceChange: 0.15, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'HVT', name: 'Haverty Furniture', basePrice: 28.2, priceChange: -0.3, priceChangePct: -1.06),
    NasdaqStockItem(symbol: 'ETD', name: 'Ethan Allen Interiors', basePrice: 28.6, priceChange: 0.37, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'LZB', name: 'La-Z-Boy Inc.', basePrice: 38.4, priceChange: 0.55, priceChangePct: 1.43),
    NasdaqStockItem(symbol: 'LEG', name: 'Leggett & Platt', basePrice: 11.8, priceChange: -0.12, priceChangePct: -1.02),
    NasdaqStockItem(symbol: 'TPX', name: 'Tempur Sealy', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'CRI', name: 'Carter\'s Inc.', basePrice: 62.4, priceChange: -0.9, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'OXM', name: 'Oxford Industries', basePrice: 82.5, priceChange: 0.59, priceChangePct: 0.72),
    NasdaqStockItem(symbol: 'VFC', name: 'V.F. Corp.', basePrice: 16.8, priceChange: 0.21, priceChangePct: 1.25),
    NasdaqStockItem(symbol: 'PVH', name: 'PVH Corp.', basePrice: 104.2, priceChange: -0.59, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'RL', name: 'Ralph Lauren Corp.', basePrice: 168.4, priceChange: -0.96, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'CPRI', name: 'Capri Holdings', basePrice: 34.6, priceChange: 0.38, priceChangePct: 1.1),
    NasdaqStockItem(symbol: 'TPR', name: 'Tapestry Inc.', basePrice: 42.8, priceChange: 0.36, priceChangePct: 0.84),
    NasdaqStockItem(symbol: 'LEVI', name: 'Levi Strauss & Co.', basePrice: 18.6, priceChange: -0.01, priceChangePct: -0.05),
    NasdaqStockItem(symbol: 'COLM', name: 'Columbia Sportswear', basePrice: 78.4, priceChange: -0.87, priceChangePct: -1.11),
    NasdaqStockItem(symbol: 'DECK', name: 'Deckers Outdoor', basePrice: 920.0, priceChange: -7.73, priceChangePct: -0.84),
    NasdaqStockItem(symbol: 'ONON', name: 'On Holding AG', basePrice: 42.5, priceChange: -0.36, priceChangePct: -0.85),
    NasdaqStockItem(symbol: 'BIRK', name: 'Birkenstock Holding', basePrice: 54.8, priceChange: 0.39, priceChangePct: 0.71),
    NasdaqStockItem(symbol: 'CROX', name: 'Crocs Inc.', basePrice: 138.4, priceChange: -0.79, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'SKX', name: 'Skechers U.S.A.', basePrice: 64.2, priceChange: 0.71, priceChangePct: 1.11),
    NasdaqStockItem(symbol: 'WWW', name: 'Wolverine World Wide', basePrice: 12.8, priceChange: -0.1, priceChangePct: -0.78),
    NasdaqStockItem(symbol: 'SHOO', name: 'Steven Madden Ltd.', basePrice: 42.4, priceChange: -0.31, priceChangePct: -0.73),
    NasdaqStockItem(symbol: 'CAL', name: 'Caleres Inc.', basePrice: 34.2, priceChange: -0.01, priceChangePct: -0.03),
    NasdaqStockItem(symbol: 'PLCE', name: 'The Children\'s Place', basePrice: 6.8, priceChange: 0.03, priceChangePct: 0.44),
    NasdaqStockItem(symbol: 'GES', name: 'Guess? Inc.', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'AEO', name: 'American Eagle Outfitters', basePrice: 20.6, priceChange: -0.11, priceChangePct: -0.53),
    NasdaqStockItem(symbol: 'ANF', name: 'Abercrombie & Fitch', basePrice: 148.5, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'URBN', name: 'Urban Outfitters', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'BKE', name: 'The Buckle Inc.', basePrice: 42.8, priceChange: 0.36, priceChangePct: 0.84),
    NasdaqStockItem(symbol: 'TLYS', name: 'Tilly\'s Inc.', basePrice: 5.4, priceChange: -0.07, priceChangePct: -1.3),
    NasdaqStockItem(symbol: 'EXPR', name: 'Express Inc.', basePrice: 1.8, priceChange: 0.02, priceChangePct: 1.11),
    NasdaqStockItem(symbol: 'ZUMZ', name: 'Zumiez Inc.', basePrice: 24.2, priceChange: -0.03, priceChangePct: -0.12),
    NasdaqStockItem(symbol: 'BOOT', name: 'Boot Barn Holdings', basePrice: 132.4, priceChange: -1.23, priceChangePct: -0.93),
    NasdaqStockItem(symbol: 'SCVL', name: 'Shoe Carnival', basePrice: 36.8, priceChange: -0.04, priceChangePct: -0.11),
    NasdaqStockItem(symbol: 'HIBB', name: 'Hibbett Inc.', basePrice: 86.5, priceChange: 0.42, priceChangePct: 0.49),
    NasdaqStockItem(symbol: 'ASO', name: 'Academy Sports + Outdoors', basePrice: 54.2, priceChange: 0.7, priceChangePct: 1.29),
    NasdaqStockItem(symbol: 'DKS', name: 'Dick\'s Sporting Goods', basePrice: 214.5, priceChange: -1.03, priceChangePct: -0.48),
    NasdaqStockItem(symbol: 'BGFV', name: 'Big 5 Sporting Goods', basePrice: 3.85, priceChange: 0.06, priceChangePct: 1.56),
    NasdaqStockItem(symbol: 'SPWH', name: 'Sportsman\'s Warehouse', basePrice: 2.45, priceChange: -0.03, priceChangePct: -1.22),
    NasdaqStockItem(symbol: 'GCO', name: 'Genesco Inc.', basePrice: 26.4, priceChange: -0.29, priceChangePct: -1.1),
    NasdaqStockItem(symbol: 'FL', name: 'Foot Locker Inc.', basePrice: 24.8, priceChange: 0.01, priceChangePct: 0.04),
    NasdaqStockItem(symbol: 'FIVE', name: 'Five Below Inc.', basePrice: 84.6, priceChange: 0.51, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'OLLI', name: 'Ollie\'s Bargain Outlet', basePrice: 88.4, priceChange: 1.35, priceChangePct: 1.53),
    NasdaqStockItem(symbol: 'BIG', name: 'Big Lots Inc.', basePrice: 1.45, priceChange: -0.01, priceChangePct: -0.69),
    NasdaqStockItem(symbol: 'DG', name: 'Dollar General', basePrice: 86.4, priceChange: 1.22, priceChangePct: 1.41),
    NasdaqStockItem(symbol: 'TGT', name: 'Target Corp.', basePrice: 148.2, priceChange: 0.53, priceChangePct: 0.36),
    NasdaqStockItem(symbol: 'WMT', name: 'Walmart Inc.', basePrice: 74.8, priceChange: 0.99, priceChangePct: 1.32),
    NasdaqStockItem(symbol: 'BBY', name: 'Best Buy Co.', basePrice: 88.6, priceChange: -0.85, priceChangePct: -0.96),
    NasdaqStockItem(symbol: 'AAN', name: 'The Aaron\'s Company', basePrice: 9.8, priceChange: -0.0, priceChangePct: -0.0),
    NasdaqStockItem(symbol: 'RCII', name: 'Rent-A-Center Upbound', basePrice: 32.4, priceChange: -0.12, priceChangePct: -0.37),
    NasdaqStockItem(symbol: 'GME', name: 'GameStop Corp.', basePrice: 22.4, priceChange: 0.05, priceChangePct: 0.22),
    NasdaqStockItem(symbol: 'AMC', name: 'AMC Entertainment', basePrice: 4.85, priceChange: -0.03, priceChangePct: -0.62),
    NasdaqStockItem(symbol: 'CNK', name: 'Cinemark Holdings', basePrice: 24.6, priceChange: -0.18, priceChangePct: -0.73),
    NasdaqStockItem(symbol: 'IMAX', name: 'IMAX Corp.', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'MCS', name: 'Marcus Corp.', basePrice: 14.2, priceChange: 0.14, priceChangePct: 0.99),
    NasdaqStockItem(symbol: 'WWE', name: 'TKO Group Holdings', basePrice: 114.5, priceChange: -1.37, priceChangePct: -1.2),
    NasdaqStockItem(symbol: 'LYV', name: 'Live Nation Entertainment', basePrice: 98.4, priceChange: 0.56, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'MSGS', name: 'Madison Square Garden Sports', basePrice: 188.0, priceChange: 2.26, priceChangePct: 1.2),
    NasdaqStockItem(symbol: 'MSGE', name: 'Madison Square Garden Ent.', basePrice: 36.4, priceChange: 0.31, priceChangePct: 0.85),
    NasdaqStockItem(symbol: 'SPHR', name: 'Sphere Entertainment', basePrice: 44.5, priceChange: -0.48, priceChangePct: -1.08),
    NasdaqStockItem(symbol: 'BATRA', name: 'Atlanta Braves Holdings', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'FWONA', name: 'Formula One Group', basePrice: 74.2, priceChange: -0.42, priceChangePct: -0.57),
    NasdaqStockItem(symbol: 'MANU', name: 'Manchester United', basePrice: 16.4, priceChange: -0.06, priceChangePct: -0.37),
    NasdaqStockItem(symbol: 'EDR', name: 'Endeavor Group Holdings', basePrice: 28.5, priceChange: -0.07, priceChangePct: -0.25),
    NasdaqStockItem(symbol: 'SONY', name: 'Sony Group Corp.', basePrice: 88.4, priceChange: 1.35, priceChangePct: 1.53),
    NasdaqStockItem(symbol: 'KMB', name: 'Kimberly-Clark Corp.', basePrice: 138.6, priceChange: -1.83, priceChangePct: -1.32),
    NasdaqStockItem(symbol: 'CL', name: 'Colgate-Palmolive', basePrice: 98.4, priceChange: 0.56, priceChangePct: 0.57),
    NasdaqStockItem(symbol: 'EL', name: 'Estee Lauder Companies', basePrice: 92.5, priceChange: 0.11, priceChangePct: 0.12),
    NasdaqStockItem(symbol: 'COTY', name: 'Coty Inc.', basePrice: 9.4, priceChange: -0.13, priceChangePct: -1.38),
    NasdaqStockItem(symbol: 'ELF', name: 'e.l.f. Beauty Inc.', basePrice: 164.2, priceChange: -2.36, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'IPAR', name: 'Inter Parfums Inc.', basePrice: 122.4, priceChange: -1.06, priceChangePct: -0.87),
    NasdaqStockItem(symbol: 'NUS', name: 'Nu Skin Enterprises', basePrice: 7.8, priceChange: -0.04, priceChangePct: -0.51),
    NasdaqStockItem(symbol: 'HLF', name: 'Herbalife Ltd.', basePrice: 8.2, priceChange: 0.04, priceChangePct: 0.49),
    NasdaqStockItem(symbol: 'USNA', name: 'USANA Health Sciences', basePrice: 38.6, priceChange: 0.24, priceChangePct: 0.62),
    NasdaqStockItem(symbol: 'MED', name: 'Medifast Inc.', basePrice: 18.4, priceChange: 0.15, priceChangePct: 0.82),
    NasdaqStockItem(symbol: 'WW', name: 'WeightWatchers Intl', basePrice: 1.25, priceChange: -0.01, priceChangePct: -0.8),
    NasdaqStockItem(symbol: 'THC', name: 'Tenet Healthcare', basePrice: 148.5, priceChange: 0.0, priceChangePct: 0.0),
    NasdaqStockItem(symbol: 'HCA', name: 'HCA Healthcare', basePrice: 368.0, priceChange: 2.21, priceChangePct: 0.6),
    NasdaqStockItem(symbol: 'UHS', name: 'Universal Health Services', basePrice: 224.0, priceChange: -1.61, priceChangePct: -0.72),
    NasdaqStockItem(symbol: 'ACHC', name: 'Acadia Healthcare', basePrice: 78.4, priceChange: -0.87, priceChangePct: -1.11),
    NasdaqStockItem(symbol: 'AMN', name: 'AMN Healthcare', basePrice: 48.6, priceChange: 0.07, priceChangePct: 0.14),
    NasdaqStockItem(symbol: 'CCRN', name: 'Cross Country Healthcare', basePrice: 14.2, priceChange: 0.14, priceChangePct: 0.99),
    NasdaqStockItem(symbol: 'DOC', name: 'Healthpeak Properties', basePrice: 21.4, priceChange: -0.26, priceChangePct: -1.21),
    NasdaqStockItem(symbol: 'OHI', name: 'Omega Healthcare Investors', basePrice: 36.8, priceChange: -0.04, priceChangePct: -0.11),
    NasdaqStockItem(symbol: 'VTR', name: 'Ventas Inc.', basePrice: 58.4, priceChange: 0.21, priceChangePct: 0.36),
    NasdaqStockItem(symbol: 'WELL', name: 'Welltower Inc.', basePrice: 118.6, priceChange: -1.71, priceChangePct: -1.44),
    NasdaqStockItem(symbol: 'SBRA', name: 'Sabra Health Care REIT', basePrice: 15.4, priceChange: -0.03, priceChangePct: -0.19),
    NasdaqStockItem(symbol: 'NHI', name: 'National Health Investors', basePrice: 68.2, priceChange: 0.59, priceChangePct: 0.87),
    NasdaqStockItem(symbol: 'LTC', name: 'LTC Properties', basePrice: 34.8, priceChange: 0.5, priceChangePct: 1.44),
    NasdaqStockItem(symbol: 'CHCT', name: 'Community Healthcare Trust', basePrice: 24.2, priceChange: -0.03, priceChangePct: -0.12),
  ];
}

// =============================================================================
// SECTION 3: ORDER BOOK ROW DATA MODEL
// =============================================================================

/// Immutable model representing a single depth level row in the 50-level order book.
@immutable
class OrderBookRowData {
  const OrderBookRowData({
    required this.level,
    required this.price,
    required this.volume,
    required this.volumeRatio,
    required this.isAsk,
    this.flashType = FlashType.none,
    this.flashTimestampMs = 0,
  });

  final int level;
  final double price;
  final int volume;
  final double volumeRatio;
  final bool isAsk;
  final FlashType flashType;
  final int flashTimestampMs;

  OrderBookRowData copyWith({
    int? level,
    double? price,
    int? volume,
    double? volumeRatio,
    bool? isAsk,
    FlashType? flashType,
    int? flashTimestampMs,
  }) {
    return OrderBookRowData(
      level: level ?? this.level,
      price: price ?? this.price,
      volume: volume ?? this.volume,
      volumeRatio: volumeRatio ?? this.volumeRatio,
      isAsk: isAsk ?? this.isAsk,
      flashType: flashType ?? this.flashType,
      flashTimestampMs: flashTimestampMs ?? this.flashTimestampMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderBookRowData &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          price == other.price &&
          volume == other.volume &&
          (volumeRatio - other.volumeRatio).abs() < 0.002 &&
          isAsk == other.isAsk &&
          flashType == other.flashType;

  @override
  int get hashCode =>
      level.hashCode ^
      price.hashCode ^
      volume.hashCode ^
      volumeRatio.hashCode ^
      isAsk.hashCode ^
      flashType.hashCode;
}

// =============================================================================
// SECTION 4: TRADE TICK MODEL
// =============================================================================

/// Immutable model representing a single executed trade tick.
@immutable
class TradeTick {
  const TradeTick({
    required this.price,
    required this.volume,
    required this.isBuy,
    required this.timestampMs,
  });

  final double price;
  final int volume;
  final bool isBuy;
  final int timestampMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeTick &&
          runtimeType == other.runtimeType &&
          price == other.price &&
          volume == other.volume &&
          isBuy == other.isBuy &&
          timestampMs == other.timestampMs;

  @override
  int get hashCode =>
      price.hashCode ^ volume.hashCode ^ isBuy.hashCode ^ timestampMs.hashCode;
}

// =============================================================================
// SECTION 5: ORDER BOOK SNAPSHOT MODEL
// =============================================================================

/// Immutable snapshot representing the full 50-level order book depth (25 Asks + 25 Bids + Spread).
@immutable
class OrderBookSnapshot {
  const OrderBookSnapshot({
    required this.ticker,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePct,
    required this.asks,
    required this.bids,
    required this.maxVolume,
    required this.totalVolume,
    required this.totalTicksProcessed,
    required this.timestampMs,
  });

  final String ticker;
  final double lastPrice;
  final double priceChange;
  final double priceChangePct;
  final List<OrderBookRowData> asks;
  final List<OrderBookRowData> bids;
  final int maxVolume;
  final int totalVolume;
  final int totalTicksProcessed;
  final int timestampMs;

  /// Creates initial OrderBookSnapshot populated with realistic sample data walls and spreads.
  static OrderBookSnapshot initial({String ticker = 'NVDA', double basePrice = 135.50}) {
    int maxVol = 1;
    int totalVol = 0;

    final asks = List<OrderBookRowData>.generate(25, (i) {
      final level = 25 - i;
      final price = basePrice + (level * 0.05);
      final isWall = (i % 6 == 1) || (i == 12) || (i == 24);
      final isThin = (i % 4 == 0);
      final vol =
          isWall ? 1800000 + (i * 95000) : (isThin ? 8500 + (i * 1200) : 120000 + (i * 24000));

      if (vol > maxVol) maxVol = vol;
      totalVol += vol;

      return OrderBookRowData(
        level: level,
        price: price,
        volume: vol,
        volumeRatio: 0.5,
        isAsk: true,
      );
    });

    final bids = List<OrderBookRowData>.generate(25, (i) {
      final level = i + 1;
      final price = basePrice - (level * 0.05);
      final isWall = (i % 5 == 2) || (i == 10) || (i == 20);
      final isThin = (i % 3 == 1);
      final vol =
          isWall ? 1650000 + (i * 88000) : (isThin ? 9200 + (i * 1500) : 105000 + (i * 21000));

      if (vol > maxVol) maxVol = vol;
      totalVol += vol;

      return OrderBookRowData(
        level: level,
        price: price,
        volume: vol,
        volumeRatio: 0.5,
        isAsk: false,
      );
    });

    final asksWithRatio = List<OrderBookRowData>.generate(25, (i) {
      return asks[i].copyWith(volumeRatio: (asks[i].volume / maxVol).clamp(0.05, 1.0));
    });

    final bidsWithRatio = List<OrderBookRowData>.generate(25, (i) {
      return bids[i].copyWith(volumeRatio: (bids[i].volume / maxVol).clamp(0.05, 1.0));
    });

    return OrderBookSnapshot(
      ticker: ticker,
      lastPrice: basePrice,
      priceChange: 1.85,
      priceChangePct: 1.38,
      asks: asksWithRatio,
      bids: bidsWithRatio,
      maxVolume: maxVol,
      totalVolume: totalVol,
      totalTicksProcessed: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Represents the execution progress of multi-set / multi-framework benchmarks.
class BenchmarkProgress {
  const BenchmarkProgress({
    this.currentSet = 1,
    this.totalSets = 1,
    this.currentBench = 1,
    this.totalBenches = 1,
    this.currentRun = 1,
    this.totalRuns = 1,
  });

  final int currentSet;
  final int totalSets;
  final int currentBench;
  final int totalBenches;
  final int currentRun;
  final int totalRuns;

  /// Returns user-friendly Swiss Monospace badge text.
  /// Example: "SET 3/10 • BENCH 2/5 (12/50)"
  String get displayText {
    if (totalRuns > 1) {
      return 'SET $currentSet/$totalSets • BENCH $currentBench/$totalBenches ($currentRun/$totalRuns)';
    }
    return 'SET $currentSet/$totalSets • BENCH $currentBench/$totalBenches';
  }
}
