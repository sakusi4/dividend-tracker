
class StockPosition {
  final String symbol;
  final double quantity;
  final double avgCost;
  double currentPrice;
  double dividendYield;
  double dividendGrowthRate;
  double priceGrowthRate;
  double allocationRate;

  StockPosition({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
    required this.currentPrice,
    this.dividendYield = 0.0,
    this.dividendGrowthRate = 0.0,
    this.priceGrowthRate = 0.0,
    this.allocationRate = 0.0,
  });

  double get evaluation => quantity * currentPrice;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgCost': avgCost,
        'currentPrice': currentPrice,
        'dividendYield': dividendYield,
        'dividendGrowthRate': dividendGrowthRate,
        'priceGrowthRate': priceGrowthRate,
        'allocationRate': allocationRate,
      };

  factory StockPosition.fromJson(Map<String, dynamic> m) => StockPosition(
        symbol: m['symbol'],
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
        avgCost: (m['avgCost'] as num?)?.toDouble() ?? 0.0,
        currentPrice: (m['currentPrice'] as num?)?.toDouble() ?? 0.0,
        dividendYield: (m['dividendYield'] as num?)?.toDouble() ?? 0.0,
        dividendGrowthRate: (m['dividendGrowthRate'] as num?)?.toDouble() ?? 0.0,
        priceGrowthRate: (m['priceGrowthRate'] as num?)?.toDouble() ?? 0.0,
        allocationRate:  (m['allocationRate'] as num?)?.toDouble() ?? 0.0,
      );
}