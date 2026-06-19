class Modifier {
  final int? id;
  final int categoryId;
  final String modifierGroup;
  final String name;
  final double priceAdjustment;

  Modifier({
    this.id,
    required this.categoryId,
    required this.modifierGroup,
    required this.name,
    required this.priceAdjustment,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int,
      modifierGroup: json['modifier_group'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceAdjustment: ConvertToDouble(json['price_adjustment']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'modifier_group': modifierGroup,
      'name': name,
      'price_adjustment': priceAdjustment,
    };
  }

  static double ConvertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
