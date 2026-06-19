class ProductVariant {
  final int? id;
  final int productId;
  final String name;
  final double price;
  final double stock;
  final String unit;

  ProductVariant({
    this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      price: ConvertToDouble(json['price']),
      stock: ConvertToDouble(json['stock']),
      unit: json['unit'] as String? ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'stock': stock,
      'unit': unit,
    };
  }

  static double ConvertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
