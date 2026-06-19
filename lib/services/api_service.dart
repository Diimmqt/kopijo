import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/modifier.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../models/transaction.dart';

class ApiService {
  static String _baseUrl = 'http://localhost:3000'; // Default URL

  static String get baseUrl => _baseUrl;

  // Initialize and load the saved API base URL
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  // Update base URL
  static Future<void> updateBaseUrl(String newUrl) async {
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      newUrl = 'http://$newUrl';
    }
    // Remove trailing slash if present
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }
    _baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', newUrl);
  }

  // Helper GET request
  static Future<dynamic> _get(String path) async {
    final response = await http.get(Uri.parse('$_baseUrl$path'));
    return _handleResponse(response);
  }

  // Helper POST request
  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Helper PUT request
  static Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // Helper DELETE request
  static Future<dynamic> _delete(String path) async {
    final response = await http.delete(Uri.parse('$_baseUrl$path'));
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String message = 'API Error (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'];
        } else if (decoded is Map && decoded.containsKey('error')) {
          message = decoded['error'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  // ==========================================
  // CATEGORIES API
  // ==========================================
  static Future<List<Category>> getCategories() async {
    final data = await _get('/categories');
    return (data as List).map((item) => Category.fromJson(item)).toList();
  }

  static Future<Category> createCategory(Category category) async {
    final data = await _post('/categories', category.toJson());
    return Category(id: data['id'] as int?, name: category.name);
  }

  static Future<void> updateCategory(Category category) async {
    await _put('/categories/${category.id}', category.toJson());
  }

  static Future<void> deleteCategory(int id) async {
    await _delete('/categories/$id');
  }

  // ==========================================
  // MODIFIERS API
  // ==========================================
  static Future<List<Modifier>> getModifiers({int? categoryId}) async {
    final path = categoryId != null ? '/modifiers?category_id=$categoryId' : '/modifiers';
    final data = await _get(path);
    return (data as List).map((item) => Modifier.fromJson(item)).toList();
  }

  static Future<Modifier> createModifier(Modifier modifier) async {
    final data = await _post('/modifiers', modifier.toJson());
    return Modifier(
      id: data['id'] as int?,
      categoryId: modifier.categoryId,
      modifierGroup: modifier.modifierGroup,
      name: modifier.name,
      priceAdjustment: modifier.priceAdjustment,
    );
  }

  static Future<void> updateModifier(Modifier modifier) async {
    await _put('/modifiers/${modifier.id}', modifier.toJson());
  }

  static Future<void> deleteModifier(int id) async {
    await _delete('/modifiers/$id');
  }

  // ==========================================
  // PRODUCTS API
  // ==========================================
  static Future<List<Product>> getProducts() async {
    final data = await _get('/products');
    final products = (data as List).map((item) => Product.fromJson(item)).toList();
    
    // Load variants for all products automatically
    for (var product in products) {
      if (product.id != null) {
        product.variants = await getVariants(productId: product.id!);
      }
    }
    return products;
  }

  static Future<Product> createProduct(Product product) async {
    final data = await _post('/products', product.toJson());
    final createdProduct = Product(
      id: data['id'] as int?,
      categoryId: product.categoryId,
      name: product.name,
      description: product.description,
      image: product.image,
      type: product.type,
      basePrice: product.basePrice,
      isActive: product.isActive,
    );

    // If there are variants defined, save them as well
    for (var variant in product.variants) {
      final createdVariant = await createVariant(
        ProductVariant(
          productId: createdProduct.id!,
          name: variant.name,
          price: variant.price,
          stock: variant.stock,
          unit: variant.unit,
        ),
      );
      createdProduct.variants.add(createdVariant);
    }
    return createdProduct;
  }

  static Future<void> updateProduct(Product product) async {
    await _put('/products/${product.id}', product.toJson());
  }

  static Future<void> deleteProduct(int id) async {
    await _delete('/products/$id');
  }

  // ==========================================
  // VARIANTS API
  // ==========================================
  static Future<List<ProductVariant>> getVariants({int? productId}) async {
    final path = productId != null ? '/variants?product_id=$productId' : '/variants';
    final data = await _get(path);
    return (data as List).map((item) => ProductVariant.fromJson(item)).toList();
  }

  static Future<ProductVariant> createVariant(ProductVariant variant) async {
    final data = await _post('/variants', variant.toJson());
    return ProductVariant(
      id: data['id'] as int?,
      productId: variant.productId,
      name: variant.name,
      price: variant.price,
      stock: variant.stock,
      unit: variant.unit,
    );
  }

  static Future<void> updateVariant(ProductVariant variant) async {
    await _put('/variants/${variant.id}', variant.toJson());
  }

  static Future<void> deleteVariant(int id) async {
    await _delete('/variants/$id');
  }

  // ==========================================
  // TRANSACTIONS API
  // ==========================================
  static Future<List<Transaction>> getTransactions() async {
    final data = await _get('/transactions');
    return (data as List).map((item) => Transaction.fromJson(item)).toList();
  }

  static Future<Transaction> getTransactionById(int id) async {
    final data = await _get('/transactions/$id');
    return Transaction.fromJson(data);
  }

  static Future<Map<String, dynamic>> checkout({
    int? userId,
    required String paymentMethod,
    required double discount,
    required double tax,
    required double amountPaid,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _post('/transactions/checkout', {
      if (userId != null) 'user_id': userId,
      'payment_method': paymentMethod,
      'discount': discount,
      'tax': tax,
      'amount_paid': amountPaid,
      'items': items,
    });
    return response as Map<String, dynamic>;
  }

  static Future<void> updateTransactionStatus(int id, String status) async {
    await _put('/transactions/$id', {'status': status});
  }

  // ==========================================
  // REPORTS API
  // ==========================================
  static Future<Map<String, dynamic>> getSalesReport() async {
    final data = await _get('/reports/sales');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPopularProductsReport() async {
    final data = await _get('/reports/popular');
    return data as List;
  }

  // Upload product image bytes
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    ));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response);
    return data['url'] as String;
  }
}
