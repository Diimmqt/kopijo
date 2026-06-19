import 'variant.dart';

class Product {
  final int? id;
  final int categoryId;
  final String name;
  final String? description;
  final String? image;
  final String type; // 'kopi', 'bubuk kopi', 'makanan'
  final double basePrice;
  final bool isActive;
  final String? categoryName;
  List<ProductVariant> variants;

  Product({
    this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.image,
    required this.type,
    required this.basePrice,
    this.isActive = true,
    this.categoryName,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      type: json['type'] as String? ?? 'kopi',
      basePrice: ConvertToDouble(json['base_price']),
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      categoryName: json['category_name'] as String?,
      variants: [], // Populated separately or from sub-fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'name': name,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      'type': type,
      'base_price': basePrice,
      'is_active': isActive ? 1 : 0,
    };
  }

  static double ConvertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
