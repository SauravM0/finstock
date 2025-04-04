class Holding {
  final String symbol;
  final double quantity;
  final double averageCost;
  final String sector;
  final double currentPrice;
  
  Holding({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
    this.sector = 'Unknown',
    this.currentPrice = 0.0,
  });
  
  double get totalCost => quantity * averageCost;
  double get currentValue => quantity * currentPrice;
  double get profitLoss => currentValue - totalCost;
  double get profitLossPercentage => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
  
  Holding copyWith({
    String? symbol,
    double? quantity,
    double? averageCost,
    String? sector,
    double? currentPrice,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      sector: sector ?? this.sector,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
  
  // Calculate new average cost when buying more shares
  static Holding combine(Holding existing, double newQuantity, double newPrice) {
    final totalQuantity = existing.quantity + newQuantity;
    final totalCost = existing.totalCost + (newQuantity * newPrice);
    final newAverageCost = totalCost / totalQuantity;
    
    return Holding(
      symbol: existing.symbol,
      quantity: totalQuantity,
      averageCost: newAverageCost,
      sector: existing.sector,
      currentPrice: existing.currentPrice,
    );
  }
} 