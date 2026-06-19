import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../providers/menu_provider.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _searchQuery = '';
  bool _onlyLowStock = false;

  void _showRefillDialog(Product product, ProductVariant variant) {
    final menu = Provider.of<MenuProvider>(context, listen: false);
    final refillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final double addedQty = double.tryParse(refillController.text.trim()) ?? 0.0;
            final double newStock = variant.stock + addedQty;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.add_business_rounded, color: Color(0xFF6F4E37)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Refill Stok: ${product.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Varian: ${variant.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Stok Saat Ini: ${variant.stock.toStringAsFixed(0)} ${variant.unit}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: refillController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Tambahan Stok',
                      suffixText: variant.unit,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setStateDialog(() {}); // Recalculate preview stock
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Preview Stok Baru:', style: TextStyle(color: Colors.black54)),
                      Text(
                        '${newStock.toStringAsFixed(0)} ${variant.unit}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37), foregroundColor: Colors.white),
                  onPressed: addedQty <= 0 ? null : () async {
                    try {
                      await menu.updateVariant(ProductVariant(
                        id: variant.id,
                        productId: variant.productId,
                        name: variant.name,
                        price: variant.price,
                        stock: newStock,
                        unit: variant.unit,
                      ));
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Stok ${product.name} (${variant.name}) berhasil ditambah!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Tambah Stok'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = Provider.of<MenuProvider>(context);

    // Collect all variants with their parent products
    final List<Map<String, dynamic>> items = [];
    for (var prod in menu.products) {
      for (var variant in prod.variants) {
        final matchesSearch = prod.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            variant.name.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final isOutOfStock = variant.stock <= 0;
        final isLowStock = isOutOfStock || 
            ((variant.unit == 'gr' && variant.stock < 1.0) || (variant.unit != 'gr' && variant.stock < 5.0));

        final matchesLowFilter = !_onlyLowStock || isLowStock;

        if (matchesSearch && matchesLowFilter) {
          items.add({
            'product': prod,
            'variant': variant,
            'isOutOfStock': isOutOfStock,
            'isLowStock': isLowStock,
          });
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok Kopi Jo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => menu.fetchMenu(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari Produk / Varian...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Low stock filter switch
                    Row(
                      children: [
                        const Text('Stok Tipis / Habis saja', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Switch(
                          value: _onlyLowStock,
                          activeColor: const Color(0xFF6F4E37),
                          onChanged: (val) {
                            setState(() {
                              _onlyLowStock = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stock list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Tidak ada stok terdaftar / menipis.', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final Product prod = item['product'];
                      final ProductVariant variant = item['variant'];
                      final bool isOutOfStock = item['isOutOfStock'];
                      final bool isLowStock = item['isLowStock'];

                      Color badgeColor;
                      String statusText;
                      if (isOutOfStock) {
                        badgeColor = Colors.red;
                        statusText = 'HABIS';
                      } else if (isLowStock) {
                        badgeColor = Colors.orange;
                        statusText = 'MENIPIS';
                      } else {
                        badgeColor = Colors.green;
                        statusText = 'AMAN';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(
                                '(${variant.name})',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          subtitle: Text('Kategori: ${prod.type.toUpperCase()} • Satuan: ${variant.unit}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stock level text
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${variant.stock.toStringAsFixed(0)} ${variant.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : Colors.green[800]),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Refill Button
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF6F4E37), size: 28),
                                onPressed: () => _showRefillDialog(prod, variant),
                                tooltip: 'Tambah Stok',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
