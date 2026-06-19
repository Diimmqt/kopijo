import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../models/modifier.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'role_selection_page.dart';
import 'history_page.dart';
import 'reports_page.dart';
import 'menu_management_page.dart';
import 'stock_page.dart';
import 'checkout_page.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDetailsDialog(Product product) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Filter modifiers that belong to the category of this product
    final categoryMods = menuProvider.modifiers.where((m) => m.categoryId == product.categoryId).toList();

    // Group modifiers by modifier_group (e.g., 'Suhu', 'Susu', 'Gilingan')
    final Map<String, List<Modifier>> groupedMods = {};
    for (var m in categoryMods) {
      groupedMods.putIfAbsent(m.modifierGroup, () => []).add(m);
    }

    ProductVariant? selectedVariant = product.variants.isNotEmpty ? product.variants.first : null;
    final Set<Modifier> selectedModifiers = {};
    double quantity = 1.0;
    
    // For single-select modifier groups (like 'Suhu' or 'Gilingan'), select first by default
    groupedMods.forEach((groupName, mods) {
      if (groupName.toLowerCase() == 'suhu' || groupName.toLowerCase() == 'gilingan' || groupName.toLowerCase() == 'ukuran') {
        if (mods.isNotEmpty) {
          selectedModifiers.add(mods.first);
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final currentVar = selectedVariant;
            final double currentUnitPrice = currentVar != null ? currentVar.price : product.basePrice;
            final double currentModsAdj = selectedModifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
            final double currentSubtotal = (currentUnitPrice + currentModsAdj) * quantity;

            // Get available stock
            final double availableStock = currentVar != null ? currentVar.stock : 0.0;
            final String unit = currentVar != null ? currentVar.unit : 'pcs';

            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image & Description
                      if (product.image != null && product.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.image!.startsWith('/uploads')
                                ? '${ApiService.baseUrl}${product.image}'
                                : product.image!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        Text(
                          product.description!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // VARIANTS SECTION
                      if (product.variants.isNotEmpty) ...[
                        const Text(
                          'Pilih Varian',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4E3629)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.variants.map((v) {
                            final isSelected = selectedVariant?.id == v.id;
                            final isOutOfStock = v.stock <= 0;
                            return ChoiceChip(
                              label: Text('${v.name} (${_currencyFormat.format(v.price)})'),
                              selected: isSelected,
                              selectedColor: const Color(0xFF6F4E37).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF6F4E37)
                                    : (isOutOfStock ? Colors.grey : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: isOutOfStock
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setStateDialog(() {
                                          selectedVariant = v;
                                          if (quantity > v.stock) quantity = v.stock;
                                          if (quantity < 1.0 && v.stock >= 1.0) quantity = 1.0;
                                        });
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // MODIFIERS SECTION (grouped)
                      if (groupedMods.isNotEmpty) ...[
                        ...groupedMods.entries.map((entry) {
                          final groupName = entry.key;
                          final mods = entry.value;
                          
                          // Determine if it should be single-select (Suhu, Gilingan) or multi-select (Extras)
                          final isSingleSelect = groupName.toLowerCase() == 'suhu' || 
                                                 groupName.toLowerCase() == 'gilingan' || 
                                                 groupName.toLowerCase() == 'ukuran';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4E3629)),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: mods.map((m) {
                                  final isSelected = selectedModifiers.contains(m);
                                  return FilterChip(
                                    label: Text(
                                      m.name + (m.priceAdjustment > 0 ? ' (+${_currencyFormat.format(m.priceAdjustment)})' : ''),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF6F4E37).withOpacity(0.2),
                                    checkmarkColor: const Color(0xFF6F4E37),
                                    labelStyle: TextStyle(
                                      color: isSelected ? const Color(0xFF6F4E37) : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      setStateDialog(() {
                                        if (isSingleSelect) {
                                          if (selected) {
                                            // Remove other options of this group
                                            selectedModifiers.removeWhere((x) => x.modifierGroup == groupName);
                                            selectedModifiers.add(m);
                                          }
                                        } else {
                                          if (selected) {
                                            selectedModifiers.add(m);
                                          } else {
                                            selectedModifiers.remove(m);
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),
                      ],

                      // QUANTITY INPUT
                      const Text(
                        'Jumlah',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4E3629)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            onPressed: () {
                              if (quantity > 1) {
                                setStateDialog(() => quantity--);
                              } else if (quantity > 0.1 && selectedVariant?.unit == 'gr') {
                                // For gram-based stock, can reduce in decimals
                                setStateDialog(() => quantity = (quantity - 0.1).clamp(0.1, 999.0));
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedVariant?.unit == 'gr' 
                                  ? quantity.toStringAsFixed(1)
                                  : quantity.toInt().toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            onPressed: () {
                              if (quantity < availableStock) {
                                setStateDialog(() => quantity++);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Stok tidak mencukupi!')),
                                );
                              }
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Stok tersedia: ${availableStock.toStringAsFixed(0)} $unit',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currencyFormat.format(currentSubtotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: availableStock <= 0 ? null : () {
                        cartProvider.addToCart(
                          product,
                          variant: selectedVariant,
                          modifiers: selectedModifiers.toList(),
                          quantity: quantity,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} dimasukkan ke keranjang!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Text('Tambah ke Keranjang'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4E3629)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                auth.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: const Color(0xFF4E3629),
                size: 36,
              ),
            ),
            accountName: Text(
              auth.isAdmin ? 'Administrator' : 'Kasir Kopi Jo',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              auth.isAdmin ? 'Akses Penuh Kelola Toko' : 'Akses Transaksi Penjualan',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF6F4E37)),
            title: const Text('Kasir POS (Transaksi)'),
            selected: true,
            selectedColor: const Color(0xFF6F4E37),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Color(0xFF6F4E37)),
            title: const Text('Riwayat Transaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_rounded, color: Color(0xFF6F4E37)),
            title: const Text('Manajemen Stok'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StockPage()));
            },
          ),
          if (auth.isAdmin) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ADMIN MENU',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Color(0xFF4E3629)),
              title: const Text('Laporan & Grafik Penjualan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF4E3629)),
              title: const Text('Manajemen Produk & Menu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementPage()));
              },
            ),
          ],
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
            title: const Text('Keluar / Ganti Role', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_cafe_rounded),
            const SizedBox(width: 8),
            const Text('POS Kopi Jo'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: auth.isAdmin ? Colors.red[700] : Colors.green[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                auth.isAdmin ? 'ADMIN' : 'KASIR',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => menuProvider.fetchMenu(),
            tooltip: 'Segarkan Menu',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: menuProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37)))
          : Row(
              children: [
                // Main menu area
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Search & Filtering Bar
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari kopi, bubuk, atau makanan...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF6F4E37)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      menuProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          onChanged: (val) => menuProvider.setSearchQuery(val),
                        ),
                      ),

                      // Horizontal Categories filter
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const Text('Semua Menu'),
                                selected: menuProvider.selectedCategoryId == null,
                                selectedColor: const Color(0xFF6F4E37),
                                labelStyle: TextStyle(
                                  color: menuProvider.selectedCategoryId == null ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) => menuProvider.selectCategory(null),
                              ),
                            ),
                            ...menuProvider.categories.map((cat) {
                              final isSelected = menuProvider.selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF6F4E37),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (_) => menuProvider.selectCategory(cat.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Products Grid
                      Expanded(
                        child: menuProvider.filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada produk ditemukan.',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop ? 3 : 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: menuProvider.filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = menuProvider.filteredProducts[index];
                                  return _buildProductCard(product);
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Right Sidebar Cart (Only on Desktop)
                if (isDesktop)
                  Container(
                    width: 380,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey[200]!)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: _buildCartWidget(context),
                  ),
              ],
            ),
      // Mobile Cart Floating Button
      floatingActionButton: !isDesktop && cartProvider.items.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6F4E37),
              foregroundColor: Colors.white,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) {
                    return FractionallySizedBox(
                      heightFactor: 0.85,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: _buildCartWidget(context),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.shopping_basket_rounded),
              label: Text('Keranjang (${cartProvider.items.length})'),
            )
          : null,
    );
  }

  Widget _buildProductCard(Product product) {
    // Check stock warning levels across all variants
    double totalStock = 0.0;
    bool hasStock = false;
    String unit = 'pcs';
    if (product.variants.isNotEmpty) {
      totalStock = product.variants.fold(0.0, (sum, v) => sum + v.stock);
      hasStock = product.variants.any((v) => v.stock > 0);
      unit = product.variants.first.unit;
    }

    final isLowStock = hasStock && 
        ((unit == 'gr' && totalStock < 1.0) || (unit != 'gr' && totalStock < 5.0));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetailsDialog(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.image != null && product.image!.isNotEmpty)
                    Image.network(
                      product.image!.startsWith('/uploads')
                          ? '${ApiService.baseUrl}${product.image}'
                          : product.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFAF7F5),
                        child: const Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF6F4E37)),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFFFAF7F5),
                      child: const Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF6F4E37)),
                    ),
                  
                  // Stock overlay badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: !hasStock 
                            ? Colors.red[800]?.withOpacity(0.9) 
                            : (isLowStock ? Colors.orange[800]?.withOpacity(0.9) : Colors.green[800]?.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        !hasStock 
                            ? 'Habis' 
                            : (isLowStock ? 'Stok Tipis' : 'Ready'),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Category tag
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryName ?? (product.categoryId == 1 ? 'Kopi' : (product.categoryId == 2 ? 'Bubuk' : 'Makanan')),
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4E3629)),
                        ),
                        if (product.description != null && product.description!.isNotEmpty)
                          Text(
                            product.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.variants.length > 1 
                              ? '${_currencyFormat.format(product.variants.first.price)} +'
                              : _currencyFormat.format(product.basePrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF6F4E37),
                          ),
                        ),
                        if (product.variants.isNotEmpty)
                          Text(
                            '${totalStock.toStringAsFixed(0)} ${product.variants.first.unit}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWidget(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.shopping_basket_rounded, color: Color(0xFF6F4E37)),
              const SizedBox(width: 8),
              const Text(
                'Keranjang Belanja',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
              ),
              const Spacer(),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () => cart.clearCart(),
                  child: const Text('Bersihkan', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Cart items list
        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Keranjang kosong',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItemTile(item);
                  },
                ),
        ),

        // Checkout calculations panel
        if (cart.items.isNotEmpty) ...[
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: Colors.black54)),
                    Text(_currencyFormat.format(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                // Tax Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Pajak PPN (11%)', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(_currencyFormat.format(cart.taxAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Switch(
                          value: cart.isTaxEnabled,
                          activeColor: const Color(0xFF6F4E37),
                          onChanged: (val) => cart.toggleTax(val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Discount field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon', style: TextStyle(color: Colors.black54)),
                    SizedBox(
                      width: 120,
                      height: 35,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Rp 0',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          border: const OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                          prefixText: cart.discount > 0 ? 'Rp ' : null,
                        ),
                        onChanged: (val) {
                          final double discountVal = double.tryParse(val) ?? 0.0;
                          cart.setDiscount(discountVal);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4E3629)),
                    ),
                    Text(
                      _currencyFormat.format(cart.total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF6F4E37)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Checkout button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Close bottom sheet if on mobile
                      if (MediaQuery.of(context).size.width <= 900) {
                        Navigator.pop(context);
                      }
                      
                      // Go to Checkout/Payment Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutPage()),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_rounded),
                        SizedBox(width: 8),
                        Text('Bayar / Selesaikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4E3629)),
                ),
                if (item.variant != null)
                  Text(
                    'Varian: ${item.variant!.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                if (item.modifiers.isNotEmpty)
                  Text(
                    'Pilihan: ' + item.modifiers.map((m) => m.name).join(', '),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                const SizedBox(height: 8),
                Text(
                  _currencyFormat.format(item.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6F4E37)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).removeFromCart(item);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      if (item.variant?.unit == 'gr' && item.quantity > 0.1) {
                        cart.updateQuantity(item, double.parse((item.quantity - 0.1).toStringAsFixed(1)));
                      } else {
                        cart.updateQuantity(item, item.quantity - 1);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.remove, size: 14, color: Colors.black54),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      item.variant?.unit == 'gr' 
                          ? '${item.quantity.toStringAsFixed(1)}'
                          : '${item.quantity.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final cart = Provider.of<CartProvider>(context, listen: false);
                      final double maxStock = item.variant != null ? item.variant!.stock : 999.0;
                      if (item.quantity < maxStock) {
                        if (item.variant?.unit == 'gr') {
                          cart.updateQuantity(item, double.parse((item.quantity + 0.1).toStringAsFixed(1)));
                        } else {
                          cart.updateQuantity(item, item.quantity + 1);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Batas stok maksimum tercapai!')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.add, size: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
