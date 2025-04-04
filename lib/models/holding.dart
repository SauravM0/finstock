class Holding {
  final String symbol;
  final double quantity;
  final double averageCost;
  
  Holding({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
  });
  
  double get totalCost => quantity * averageCost;
  
  Holding copyWith({
    String? symbol,
    double? quantity,
    double? averageCost,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
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
    );
  }
} 