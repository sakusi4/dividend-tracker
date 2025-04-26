
class StockPosition {
  final String symbol;
  final double quantity;
  final double avgCost;
  double currentPrice;
  double dividendYield;
  double dividendGrowthRate;
  double priceGrowthRate;

  StockPosition({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
    required this.currentPrice,
    this.dividendYield = 0,
    this.dividendGrowthRate = 0,
    this.priceGrowthRate = 0,
  });

  double get evaluation => quantity * currentPrice;

  // ── JSON 직렬화 ──
  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgCost': avgCost,
        'currentPrice': currentPrice,
        'dividendYield': dividendYield,
        'dividendGrowthRate': dividendGrowthRate,
        'priceGrowthRate': priceGrowthRate,
      };

  factory StockPosition.fromJson(Map<String, dynamic> m) => StockPosition(
        symbol: m['symbol'],
        quantity: (m['quantity'] as num).toDouble(),
        avgCost: (m['avgCost'] as num).toDouble(),
        currentPrice: (m['currentPrice'] as num).toDouble(),
        dividendYield: (m['dividendYield'] as num).toDouble(),
        dividendGrowthRate: (m['dividendGrowthRate'] as num).toDouble(),
        priceGrowthRate: (m['priceGrowthRate'] as num).toDouble(),
      );
}