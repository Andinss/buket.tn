import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';

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
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    border: isAdminProduct ? Border.all(color: Colors.orange, width: 1) : null,
                  ),
                  child: Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                if (isAdminProduct)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Sample', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formatRupiah(product.price), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D))),
                            const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(product.category, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: product.estimationDays == 0 
                                          ? const Color(0xFFDCFCE7) 
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      product.estimationText,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: product.estimationDays == 0 
                                            ? const Color(0xFF16A34A) 
                                            : const Color(0xFFC78500),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showEditProductDialog(context, product),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFFFE8F0), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.edit, size: 18, color: Color(0xFFFF6B9D)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showDeleteProductDialog(context, product.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddProductDialog(BuildContext context, String sellerId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final detailsController = TextEditingController();
    final estimationController = TextEditingController(text: '1');
    List<XFile> selectedImages = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gambar Produk (Maks. 3)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                            width: 80,
                            height: 80,
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
                            width: 80,
                            height: 80,
                            color: const Color(0xFFFFE8F0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 24, color: Color(0xFFFF6B9D)),
                                SizedBox(height: 4),
                                Text('Tambah', style: TextStyle(fontSize: 10, color: Color(0xFFFF6B9D))),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    prefixIcon: const Icon(Icons.local_florist, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    prefixIcon: const Icon(Icons.description, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixIcon: const Icon(Icons.money, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: estimationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Estimasi Pembuatan (Hari)',
                    hintText: '0 = Ready Stock, 1+ = Pre-order',
                    prefixIcon: const Icon(Icons.schedule, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Detail Produk',
                    prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
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

                try {
                  List<String> imageBase64List = [];
                  for (var image in selectedImages) {
                    final bytes = await image.readAsBytes();
                    imageBase64List.add(base64Encode(bytes));
                  }

                  final newBouquet = Bouquet(
                    id: '',
                    name: nameController.text,
                    description: descriptionController.text,
                    price: int.parse(priceController.text),
                    images: imageBase64List,
                    category: categoryController.text.isNotEmpty ? categoryController.text : 'Bunga',
                    details: detailsController.text,
                    sellerId: sellerId,
                    estimationDays: int.tryParse(estimationController.text) ?? 1,
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
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B9D)),
              child: const Text('Tambahkan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Bouquet product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final categoryController = TextEditingController(text: product.category);
    final detailsController = TextEditingController(text: product.details);
    final estimationController = TextEditingController(text: product.estimationDays.toString());
    List<XFile> newImages = [];
    List<String> existingImages = List.from(product.images);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gambar Produk (Maks. 3)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                            width: 80,
                            height: 80,
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
                            width: 80,
                            height: 80,
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
                          dashPattern: [6, 3], // panjang garis, jarak antar putus-putus
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(12),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFFFE8F0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 24, color: Color(0xFFFF6B9D)),
                                SizedBox(height: 4),
                                Text('Tambah', style: TextStyle(fontSize: 10, color: Color(0xFFFF6B9D))),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    prefixIcon: const Icon(Icons.local_florist, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    prefixIcon: const Icon(Icons.description, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga (Rp)',
                    prefixIcon: const Icon(Icons.money, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: estimationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Estimasi Pembuatan (Hari)',
                    hintText: '0 = Ready Stock, 1+ = Pre-order',
                    prefixIcon: const Icon(Icons.schedule, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Detail Produk',
                    prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
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
                
                try {
                  List<String> allImages = List.from(existingImages);
                  
                  for (var image in newImages) {
                    final bytes = await image.readAsBytes();
                    allImages.add(base64Encode(bytes));
                  }

                  final updatedBouquet = Bouquet(
                    id: product.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    price: int.parse(priceController.text),
                    images: allImages,
                    category: categoryController.text.isNotEmpty ? categoryController.text : 'Bunga',
                    details: detailsController.text,
                    sellerId: product.sellerId,
                    estimationDays: int.tryParse(estimationController.text) ?? 1,
                  );

                  final service = FirebaseService();
                  await service.updateBouquet(product.id, updatedBouquet);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produk berhasil diperbarui!'), backgroundColor: Color(0xFFFF6B9D)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B9D)),
              child: const Text('Perbarui', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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