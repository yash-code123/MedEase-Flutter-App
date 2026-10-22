class MedicineStock {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final int minStock;
  final String? expiry;

  MedicineStock({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minStock,
    this.expiry,
  });

  bool get isLowStock => quantity <= minStock;

  factory MedicineStock.fromJson(Map<String, dynamic> json) => MedicineStock(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        quantity: json['quantity'] is int ? json['quantity'] as int : int.tryParse('${json['quantity']}') ?? 0,
        minStock: json['min_stock'] is int
            ? json['min_stock'] as int
            : int.tryParse('${json['min_stock'] ?? json['minStock']}') ?? 0,
        expiry: json['expiry']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'min_stock': minStock,
        if (expiry != null) 'expiry': expiry,
      };
}
