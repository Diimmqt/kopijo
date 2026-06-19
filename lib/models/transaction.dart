class Transaction {
  final int? id;
  final int? userId;
  final String? transactionCode;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final String status;
  final DateTime? createdAt;
  List<TransactionItem> items;

  Transaction({
    this.id,
    this.userId,
    this.transactionCode,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    this.status = 'paid',
    this.createdAt,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    List<TransactionItem> parsedItems = itemsList != null
        ? itemsList.map((i) => TransactionItem.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    return Transaction(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      transactionCode: json['transaction_code'] as String?,
      subtotal: ConvertToDouble(json['subtotal']),
      discount: ConvertToDouble(json['discount']),
      tax: ConvertToDouble(json['tax']),
      total: ConvertToDouble(json['total']),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      amountPaid: ConvertToDouble(json['amount_paid']),
      changeAmount: ConvertToDouble(json['change_amount']),
      status: json['status'] as String? ?? 'paid',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (transactionCode != null) 'transaction_code': transactionCode,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'status': status,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  static double ConvertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class TransactionItem {
  final int? id;
  final int? transactionId;
  final int productId;
  final int? variantId;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final String? productName;
  final String? variantName;
  List<TransactionItemModifier> modifiers;

  TransactionItem({
    this.id,
    this.transactionId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.productName,
    this.variantName,
    this.modifiers = const [],
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    var modsList = json['modifiers'] as List?;
    List<TransactionItemModifier> parsedMods = modsList != null
        ? modsList.map((m) => TransactionItemModifier.fromJson(m as Map<String, dynamic>)).toList()
        : [];

    return TransactionItem(
      id: json['id'] as int?,
      transactionId: json['transaction_id'] as int?,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int?,
      quantity: ConvertToDouble(json['quantity']),
      unitPrice: ConvertToDouble(json['unit_price']),
      subtotal: ConvertToDouble(json['subtotal']),
      productName: json['product_name'] as String?,
      variantName: json['variant_name'] as String?,
      modifiers: parsedMods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
    };
  }

  static double ConvertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class TransactionItemModifier {
  final int? id;
  final int? transactionItemId;
  final int modifierId;
  final double priceAdjustment;
  final String? modifierName;
  final String? modifierGroup;

  TransactionItemModifier({
    this.id,
    this.transactionItemId,
    required this.modifierId,
    required this.priceAdjustment,
    this.modifierName,
    this.modifierGroup,
  });

  factory TransactionItemModifier.fromJson(Map<String, dynamic> json) {
    return TransactionItemModifier(
      id: json['id'] as int?,
      transactionItemId: json['transaction_item_id'] as int?,
      modifierId: json['modifier_id'] as int,
      priceAdjustment: ConvertToDouble(json['price_adjustment']),
      modifierName: json['modifier_name'] as String?,
      modifierGroup: json['modifier_group'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (transactionItemId != null) 'transaction_item_id': transactionItemId,
      'modifier_id': modifierId,
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
