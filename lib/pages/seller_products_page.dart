import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';

// ignore: unused_import
import '../pages/add_product_page.dart'; // TAMBAHKAN ini di bagian atas
import '../providers/auth_provider.dart';
import '../providers/bouquet_provider.dart';
import '../services/firebase_service.dart';
import '../models/bouquet.dart';
import '../utils/helpers.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bouquets = Provider.of<BouquetProvider>(context).bouquets;
    
    final sellerProducts = bouquets.where((b) => 
      b.sellerId == auth.user?.uid || b.sellerId == 'admin'
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Produk Saya', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, auth.user!.uid),
        backgroundColor: const Color(0xFFFF6B9D),
        child: const Icon(Icons.add),
      ),
      body: sellerProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: const BoxDecoration(color: Color(0xFFFFE8F0), shape: BoxShape.circle),
                    child: const Icon(Icons.store_rounded, size: 80, color: Color(0xFFFF6B9D)),
                  ),
                  const SizedBox(height: 30),
                  const Text('Belum Ada Produk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 12),
                  Text('Mulai tambah produk bunga Anda', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sellerProducts.length,
              itemBuilder: (context, index) {
                final product = sellerProducts[index];
                final isAdminProduct = product.sellerId == 'admin';
                
                return GestureDetector(
                  onTap: () => _showEditProductPage(context, product),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      border: isAdminProduct ? Border.all(color: Colors.orange, width: 1) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFFFE8F0),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: product.images.isNotEmpty 
                                    ? buildProductImage(product.images[0])
                                    : const Icon(Icons.image, color: Color(0xFFFF6B9D)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name, 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                        ),
                                      ),
                                      if (isAdminProduct)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Sample', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(formatRupiah(product.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D))),
                                  const SizedBox(height: 6),
                                  Text(product.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  if (product.estimationDays > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        product.estimationText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC78500),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditProductPage(context, product),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF6B9D),
                                  side: const BorderSide(color: Color(0xFFFF6B9D)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showDeleteProductDialog(context, product.id),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Hapus'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddProductDialog(BuildContext context, String sellerId) {
    // NAVIGASI KE HALAMAN FULL SCREEN
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(sellerId: sellerId),
      ),
    );
  }

  void _showEditProductPage(BuildContext context, Bouquet product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk?'),
        content: const Text('Yakin ingin menghapus produk ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final service = FirebaseService();
                await service.deleteBouquet(productId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk berhasil dihapus!'), backgroundColor: Color(0xFFFF6B9D)),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Halaman Tambah Produk Fullscreen
class AddProductPage extends StatefulWidget {
  final String sellerId;

  const AddProductPage({super.key, required this.sellerId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _estimationController = TextEditingController();
  List<XFile> selectedImages = [];
  bool _isLoading = false;

  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga tidak boleh kosong'), backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 gambar'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageBase64List = [];
      for (var image in selectedImages) {
        final bytes = await image.readAsBytes();
        imageBase64List.add(base64Encode(bytes));
      }

      final estimationDays = _estimationController.text.isEmpty 
          ? 0 
          : (int.tryParse(_estimationController.text) ?? 0);

      final newBouquet = Bouquet(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
        images: imageBase64List,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : 'Bunga',
        details: _detailsController.text,
        sellerId: widget.sellerId,
        estimationDays: estimationDays,
      );

      final service = FirebaseService();
      await service.addBouquet(newBouquet);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan!'), backgroundColor: Color(0xFFFF6B9D)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tambah Produk Baru', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gambar Produk (Maks. 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B9D), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(image.path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
                if (selectedImages.length < 3)
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          selectedImages.add(image);
                        });
                      }
                    },
                    child: DottedBorder(
                      color: const Color(0xFFFF6B9D),
                      strokeWidth: 2,
                      dashPattern: [6, 3],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFFFE8F0),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 30, color: Color(0xFFFF6B9D)),
                            SizedBox(height: 4),
                            Text('Tambah', style: TextStyle(fontSize: 11, color: Color(0xFFFF6B9D))),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Produk',
                prefixIcon: const Icon(Icons.local_florist, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Deskripsi Singkat',
                prefixIcon: const Icon(Icons.description, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Harga (Rp)',
                prefixIcon: const Icon(Icons.money, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Kategori',
                prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _estimationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimasi Pembuatan (Hari) - Opsional',
                hintText: 'Kosongkan jika ready stock',
                prefixIcon: const Icon(Icons.schedule, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Detail Produk',
                prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Tambahkan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Halaman Edit Produk Fullscreen
class EditProductPage extends StatefulWidget {
  final Bouquet product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _detailsController;
  late TextEditingController _estimationController;
  List<XFile> newImages = [];
  List<String> existingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _categoryController = TextEditingController(text: widget.product.category);
    _detailsController = TextEditingController(text: widget.product.details);
    _estimationController = TextEditingController(
      text: widget.product.estimationDays > 0 ? widget.product.estimationDays.toString() : ''
    );
    existingImages = List.from(widget.product.images);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _detailsController.dispose();
    _estimationController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga tidak boleh kosong'), backgroundColor: Colors.red),
      );
      return;
    }

    if (existingImages.isEmpty && newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 gambar diperlukan'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> allImages = List.from(existingImages);

      for (var image in newImages) {
        final bytes = await image.readAsBytes();
        allImages.add(base64Encode(bytes));
      }

      final estimationDays = _estimationController.text.isEmpty 
          ? 0 
          : (int.tryParse(_estimationController.text) ?? 0);

      final updatedBouquet = Bouquet(
        id: widget.product.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.parse(_priceController.text),
        images: allImages,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : 'Bunga',
        details: _detailsController.text,
        sellerId: widget.product.sellerId,
        estimationDays: estimationDays,
      );

      final service = FirebaseService();
      await service.updateBouquet(widget.product.id, updatedBouquet);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diperbarui!'), backgroundColor: Color(0xFFFF6B9D)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Produk', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gambar Produk (Maks. 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...existingImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imageData = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B9D), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: buildProductImage(imageData),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              existingImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
                ...newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B9D), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(image.path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              newImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }),
                if (existingImages.length + newImages.length < 3)
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          newImages.add(image);
                        });
                      }
                    },
                    child: DottedBorder(
                      color: const Color(0xFFFF6B9D),
                      strokeWidth: 2,
                      dashPattern: [6, 3],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFFFE8F0),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 30, color: Color(0xFFFF6B9D)),
                            SizedBox(height: 4),
                            Text('Tambah', style: TextStyle(fontSize: 11, color: Color(0xFFFF6B9D))),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Produk',
                prefixIcon: const Icon(Icons.local_florist, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Deskripsi Singkat',
                prefixIcon: const Icon(Icons.description, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Harga (Rp)',
                prefixIcon: const Icon(Icons.money, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Kategori',
                prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _estimationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Estimasi Pembuatan (Hari) - Opsional',
                hintText: 'Kosongkan jika ready stock',
                prefixIcon: const Icon(Icons.schedule, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Detail Produk',
                prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}