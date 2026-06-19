import 'package:flutter/material.dart';
import '../models/modifier.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../services/api_service.dart';

class CartItem {
  final Product product;
  final ProductVariant? variant;
  final List<Modifier> modifiers;
  double quantity;

  CartItem({
    required this.product,
    this.variant,
    this.modifiers = const [],
    this.quantity = 1.0,
  });

  double get unitPrice => variant != null ? variant!.price : product.basePrice;

  double get modifierTotalAdjustment {
    return modifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
  }

  double get subtotal => (unitPrice + modifierTotalAdjustment) * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _discount = 0.0;
  bool _isTaxEnabled = true; // Auto PPN 11%
  bool _isLoading = false;

  List<CartItem> get items => _items;
  double get discount => _discount;
  bool get isTaxEnabled => _isTaxEnabled;
  bool get isLoading => _isLoading;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get taxAmount {
    return _isTaxEnabled ? subtotal * 0.11 : 0.0;
  }

  double get total {
    final val = subtotal - _discount + taxAmount;
    return val < 0 ? 0.0 : val;
  }

  void toggleTax(bool enabled) {
    _isTaxEnabled = enabled;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void addToCart(Product product, {ProductVariant? variant, List<Modifier> modifiers = const [], double quantity = 1.0}) {
    // Check if item with same product, variant and modifiers already exists
    int existingIdx = _items.indexWhere((item) {
      if (item.product.id != product.id) return false;
      if (item.variant?.id != variant?.id) return false;
      
      // Check if modifiers lists match
      if (item.modifiers.length != modifiers.length) return false;
      final itemModIds = item.modifiers.map((m) => m.id).toSet();
      final targetModIds = modifiers.map((m) => m.id).toSet();
      return itemModIds.difference(targetModIds).isEmpty;
    });

    if (existingIdx != -1) {
      _items[existingIdx].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        variant: variant,
        modifiers: modifiers,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItem item, double quantity) {
    if (quantity <= 0) {
      removeFromCart(item);
    } else {
      item.quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _discount = 0.0;
    notifyListeners();
  }

  // Checkout call
  Future<Map<String, dynamic>> checkout({
    required String paymentMethod,
    required double amountPaid,
    int? userId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final itemsPayload = _items.map((item) {
        return {
          'product_id': item.product.id,
          'variant_id': item.variant?.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'modifiers': item.modifiers.map((m) => {
            'modifier_id': m.id,
            'price_adjustment': m.priceAdjustment,
          }).toList(),
        };
      }).toList();

      final result = await ApiService.checkout(
        userId: userId,
        paymentMethod: paymentMethod,
        discount: _discount,
        tax: taxAmount,
        amountPaid: amountPaid,
        items: itemsPayload,
      );

      clearCart();
      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
