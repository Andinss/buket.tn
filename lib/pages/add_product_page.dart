import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';

import '../models/bouquet.dart';
import '../services/firebase_service.dart';

class AddProductPage extends StatefulWidget {
  final String sellerId;

  const AddProductPage({super.key, required this.sellerId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final categoryController = TextEditingController();
  final detailsController = TextEditingController();
  final estimationController = TextEditingController();
  
  List<XFile> selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    categoryController.dispose();
    detailsController.dispose();
    estimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 gambar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        selectedImages.add(image);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 gambar'),
          backgroundColor: Colors.red,
        ),
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

      final estimationDays = estimationController.text.isEmpty
          ? 0
          : (int.tryParse(estimationController.text) ?? 0);

      final newBouquet = Bouquet(
        id: '',
        name: nameController.text,
        description: descriptionController.text,
        price: int.parse(priceController.text),
        images: imageBase64List,
        category: categoryController.text.isNotEmpty ? categoryController.text : 'Bunga',
        details: detailsController.text,
        sellerId: widget.sellerId,
        estimationDays: estimationDays,
      );

      final service = FirebaseService();
      await service.addBouquet(newBouquet);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Color(0xFFFF6B9D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tambah Produk Baru',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Gambar Produk (Maks. 3)'),
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
                            onTap: _pickImage,
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
                    _buildSectionHeader('Informasi Produk'),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk',
                        hintText: 'Contoh: Buket Mawar Merah',
                        prefixIcon: const Icon(Icons.local_florist, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Nama produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Singkat',
                        hintText: 'Deskripsi produk...',
                        prefixIcon: const Icon(Icons.description, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        hintText: 'Contoh: 150000',
                        prefixIcon: const Icon(Icons.money, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Harga tidak boleh kosong';
                        }
                        final price = int.tryParse(value!);
                        if (price == null || price < 0) {
                          return 'Harga tidak valid';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        hintText: 'Contoh: Romantis, Elegant',
                        prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: estimationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimasi Pembuatan (Hari)',
                        hintText: 'Kosongkan jika ready stock',
                        prefixIcon: const Icon(Icons.schedule, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                        helperText: 'Isi 0 atau kosongkan untuk ready stock',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detail Produk',
                        hintText: 'Jelaskan detail produk Anda...',
                        prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Detail produk tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom bar dengan tombol simpan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Tambahkan Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }
}