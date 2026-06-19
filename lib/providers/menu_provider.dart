import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/modifier.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Modifier> _modifiers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  int? _selectedCategoryId;
  String _searchQuery = '';

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Modifier> get modifiers => _modifiers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // Filter products based on search and selected category
  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _selectedCategoryId == null || product.categoryId == _selectedCategoryId;
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description != null && product.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch && product.isActive;
    }).toList();
  }

  // Reload everything
  Future<void> fetchMenu() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await ApiService.getCategories();
      _products = await ApiService.getProducts();
      _modifiers = await ApiService.getModifiers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ==========================================
  // CATEGORIES CRUD
  // ==========================================
  Future<void> addCategory(String name) async {
    final cat = await ApiService.createCategory(Category(name: name));
    _categories.add(cat);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await ApiService.updateCategory(category);
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories[idx] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int id) async {
    await ApiService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    notifyListeners();
  }

  // ==========================================
  // PRODUCTS CRUD
  // ==========================================
  Future<void> addProduct(Product product) async {
    final newProduct = await ApiService.createProduct(product);
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await ApiService.updateProduct(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      product.variants = _products[idx].variants; // Preserve variants locally
      _products[idx] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    await ApiService.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ==========================================
  // VARIANTS CRUD
  // ==========================================
  Future<void> addVariant(ProductVariant variant) async {
    final newVariant = await ApiService.createVariant(variant);
    final pIdx = _products.indexWhere((p) => p.id == variant.productId);
    if (pIdx != -1) {
      // Create new list to force widget rebuild if using const lists
      _products[pIdx].variants = List.from(_products[pIdx].variants)..add(newVariant);
      notifyListeners();
    }
  }

  Future<void> updateVariant(ProductVariant variant) async {
    await ApiService.updateVariant(variant);
    final pIdx = _products.indexWhere((p) => p.id == variant.productId);
    if (pIdx != -1) {
      final vIdx = _products[pIdx].variants.indexWhere((v) => v.id == variant.id);
      if (vIdx != -1) {
        _products[pIdx].variants = List.from(_products[pIdx].variants)..[vIdx] = variant;
        notifyListeners();
      }
    }
  }

  Future<void> deleteVariant(int id, int productId) async {
    await ApiService.deleteVariant(id);
    final pIdx = _products.indexWhere((p) => p.id == productId);
    if (pIdx != -1) {
      _products[pIdx].variants = List.from(_products[pIdx].variants)..removeWhere((v) => v.id == id);
      notifyListeners();
    }
  }

  // ==========================================
  // MODIFIERS CRUD
  // ==========================================
  Future<void> addModifier(Modifier modifier) async {
    final newModifier = await ApiService.createModifier(modifier);
    _modifiers.add(newModifier);
    notifyListeners();
  }

  Future<void> updateModifier(Modifier modifier) async {
    await ApiService.updateModifier(modifier);
    final idx = _modifiers.indexWhere((m) => m.id == modifier.id);
    if (idx != -1) {
      _modifiers[idx] = modifier;
      notifyListeners();
    }
  }

  Future<void> deleteModifier(int id) async {
    await ApiService.deleteModifier(id);
    _modifiers.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
