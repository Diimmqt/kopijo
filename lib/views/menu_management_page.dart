import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/variant.dart';
import '../models/modifier.dart';
import '../providers/menu_provider.dart';
import '../services/api_service.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // CATEGORY DIALOGS
  // ==========================================
  void _showCategoryDialog({Category? category}) {
    final menu = Provider.of<MenuProvider>(context, listen: false);
    final controller = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nama Kategori', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                try {
                  if (category == null) {
                    await menu.addCategory(name);
                  } else {
                    await menu.updateCategory(Category(id: category.id, name: name));
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // PRODUCT DIALOGS
  // ==========================================
  void _showProductDialog({Product? product}) {
    final menu = Provider.of<MenuProvider>(context, listen: false);
    
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product != null ? product.basePrice.toInt().toString() : '');
    
    int? selectedCatId = product?.categoryId ?? (menu.categories.isNotEmpty ? menu.categories.first.id : null);
    const validTypes = ['kopi', 'bubuk kopi', 'makanan'];
    String selectedType = (product?.type != null && validTypes.contains(product!.type))
        ? product.type
        : 'kopi'; // fallback jika type kosong/tidak dikenal

    XFile? pickedImageFile;
    Uint8List? pickedImageBytes;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUploadingImage) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Color(0xFF6F4E37)),
                        const SizedBox(height: 12),
                        const Text('Mengunggah gambar produk...', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 20),
                      ] else ...[
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedCatId,
                          decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                          items: menu.categories.map((c) {
                            return DropdownMenuItem(value: c.id, child: Text(c.name));
                          }).toList(),
                          onChanged: (val) => setStateDialog(() => selectedCatId = val),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Tipe Produk', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'kopi', child: Text('Kopi (Minuman)')),
                            DropdownMenuItem(value: 'bubuk kopi', child: Text('Bubuk Kopi (Kiloan)')),
                            DropdownMenuItem(value: 'makanan', child: Text('Makanan')),
                          ],
                          onChanged: (val) => setStateDialog(() => selectedType = val ?? 'kopi'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Harga Dasar (Rp)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        
                        // Interactive image picker container
                        InkWell(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setStateDialog(() {
                                pickedImageFile = image;
                                pickedImageBytes = bytes;
                              });
                            }
                          },
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: pickedImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(
                                      pickedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (product?.image != null && product!.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(
                                          product.image!.startsWith('/uploads')
                                              ? '${ApiService.baseUrl}${product.image}'
                                              : product.image!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF6F4E37)),
                                          SizedBox(height: 8),
                                          Text('Pilih Foto Produk', style: TextStyle(color: Colors.black54)),
                                        ],
                                      )),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: isUploadingImage
                  ? []
                  : [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                          if (name.isEmpty || selectedCatId == null) return;

                          setStateDialog(() => isUploadingImage = true);

                          try {
                            String imageUrl = product?.image ?? '';
                            if (pickedImageBytes != null && pickedImageFile != null) {
                              imageUrl = await ApiService.uploadImage(
                                pickedImageBytes!,
                                pickedImageFile!.name,
                              );
                            }

                            if (product == null) {
                              await menu.addProduct(Product(
                                categoryId: selectedCatId!,
                                name: name,
                                description: descController.text.trim(),
                                image: imageUrl,
                                type: selectedType,
                                basePrice: price,
                              ));
                            } else {
                              await menu.updateProduct(Product(
                                id: product.id,
                                categoryId: selectedCatId!,
                                name: name,
                                description: descController.text.trim(),
                                image: imageUrl,
                                type: selectedType,
                                basePrice: price,
                                isActive: product.isActive,
                              ));
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            setStateDialog(() => isUploadingImage = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VARIANT DIALOGS
  // ==========================================
  void _showVariantDialog(int productId, {ProductVariant? variant}) {
    final menu = Provider.of<MenuProvider>(context, listen: false);
    
    final nameController = TextEditingController(text: variant?.name ?? '');
    final priceController = TextEditingController(text: variant != null ? variant.price.toInt().toString() : '');
    final stockController = TextEditingController(text: variant != null ? variant.stock.toInt().toString() : '');
    final unitController = TextEditingController(text: variant?.unit ?? 'pcs');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(variant == null ? 'Tambah Varian' : 'Edit Varian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Varian (contoh: Large, 250gr)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Varian (Rp)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Satuan Unit (pcs, gr)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final stock = double.tryParse(stockController.text.trim()) ?? 0.0;
                final unit = unitController.text.trim();
                
                if (name.isEmpty) return;

                try {
                  if (variant == null) {
                    await menu.addVariant(ProductVariant(
                      productId: productId,
                      name: name,
                      price: price,
                      stock: stock,
                      unit: unit,
                    ));
                  } else {
                    await menu.updateVariant(ProductVariant(
                      id: variant.id,
                      productId: productId,
                      name: name,
                      price: price,
                      stock: stock,
                      unit: unit,
                    ));
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // MODIFIER DIALOGS
  // ==========================================
  void _showModifierDialog({Modifier? modifier}) {
    final menu = Provider.of<MenuProvider>(context, listen: false);
    
    final groupController = TextEditingController(text: modifier?.modifierGroup ?? '');
    final nameController = TextEditingController(text: modifier?.name ?? '');
    final adjController = TextEditingController(text: modifier != null ? modifier.priceAdjustment.toInt().toString() : '0');
    int? selectedCatId = modifier?.categoryId ?? (menu.categories.isNotEmpty ? menu.categories.first.id : null);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(modifier == null ? 'Tambah Modifier' : 'Edit Modifier'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCatId,
                    decoration: const InputDecoration(labelText: 'Kategori Produk', border: OutlineInputBorder()),
                    items: menu.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => selectedCatId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: groupController,
                    decoration: const InputDecoration(labelText: 'Grup Modifier (contoh: Suhu, Ekstra)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Modifier (contoh: Dingin, Oatmilk)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adjController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tambahan Harga (Rp)', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    final group = groupController.text.trim();
                    final name = nameController.text.trim();
                    final adj = double.tryParse(adjController.text.trim()) ?? 0.0;
                    if (group.isEmpty || name.isEmpty || selectedCatId == null) return;

                    try {
                      if (modifier == null) {
                        await menu.addModifier(Modifier(
                          categoryId: selectedCatId!,
                          modifierGroup: group,
                          name: name,
                          priceAdjustment: adj,
                        ));
                      } else {
                        await menu.updateModifier(Modifier(
                          id: modifier.id,
                          categoryId: selectedCatId!,
                          modifierGroup: group,
                          name: name,
                          priceAdjustment: adj,
                        ));
                      }
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Simpan'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu & Harga'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Produk & Varian'),
            Tab(icon: Icon(Icons.category), text: 'Kategori'),
            Tab(icon: Icon(Icons.tune), text: 'Modifiers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. PRODUCTS & VARIANTS TAB
          _buildProductsTab(menu),

          // 2. CATEGORIES TAB
          _buildCategoriesTab(menu),

          // 3. MODIFIERS TAB
          _buildModifiersTab(menu),
        ],
      ),
    );
  }

  Widget _buildProductsTab(MenuProvider menu) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar Produk Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Produk'),
                onPressed: () => _showProductDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menu.products.length,
            itemBuilder: (context, index) {
              final product = menu.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        '(${product.type.toUpperCase()})',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  subtitle: Text('Harga Dasar: ${_currencyFormat.format(product.basePrice)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          title: 'Hapus Produk?',
                          message: 'Apakah Anda yakin ingin menghapus produk ini?',
                          onDelete: () => menu.deleteProduct(product.id!),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Varian Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Tambah Varian', style: TextStyle(fontSize: 12)),
                                onPressed: () => _showVariantDialog(product.id!),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (product.variants.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('Belum ada varian. Gunakan varian untuk melacak stok & harga khusus.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            )
                          else
                            ...product.variants.map((v) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${v.name} - ${_currencyFormat.format(v.price)} (Stok: ${v.stock.toStringAsFixed(0)} ${v.unit})'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                          onPressed: () => _showVariantDialog(product.id!, variant: v),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                          onPressed: () => _confirmDelete(
                                            context,
                                            title: 'Hapus Varian?',
                                            message: 'Apakah Anda yakin ingin menghapus varian ini?',
                                            onDelete: () => menu.deleteVariant(v.id!, product.id!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(MenuProvider menu) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kategori Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kategori'),
                onPressed: () => _showCategoryDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menu.categories.length,
            itemBuilder: (context, index) {
              final cat = menu.categories[index];
              return Card(
                child: ListTile(
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCategoryDialog(category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          title: 'Hapus Kategori?',
                          message: 'Menghapus kategori ini juga akan menghapus semua produk di dalamnya!',
                          onDelete: () => menu.deleteCategory(cat.id!),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModifiersTab(MenuProvider menu) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Modifier Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Modifier'),
                onPressed: () => _showModifierDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menu.modifiers.length,
            itemBuilder: (context, index) {
              final mod = menu.modifiers[index];
              final cat = menu.categories.firstWhere((c) => c.id == mod.categoryId, orElse: () => Category(name: '-'));
              
              return Card(
                child: ListTile(
                  title: Text(mod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Grup: ${mod.modifierGroup} • Kategori: ${cat.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mod.priceAdjustment > 0 ? '+ ${_currencyFormat.format(mod.priceAdjustment)}' : 'Gratis',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6F4E37)),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showModifierDialog(modifier: mod),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(
                          context,
                          title: 'Hapus Modifier?',
                          message: 'Apakah Anda yakin ingin menghapus modifier ini?',
                          onDelete: () => menu.deleteModifier(mod.id!),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, {required String title, required String message, required VoidCallback onDelete}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
