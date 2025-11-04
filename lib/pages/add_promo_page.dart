import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';
import '../models/promo.dart';

class AddPromoPage extends StatefulWidget {
  final Promo? promo; // Null jika tambah baru, ada value jika edit

  const AddPromoPage({super.key, this.promo});

  @override
  State<AddPromoPage> createState() => _AddPromoPageState();
}

class _AddPromoPageState extends State<AddPromoPage> {
  final FirebaseService _service = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _orderController = TextEditingController(text: '0');
  
  String _color1 = 'FF6B9D';
  String _color2 = 'FF8FAB';
  bool _isActive = true;
  bool _isLoading = false;

  final Map<String, String> _colorOptions = {
    'FF6B9D': 'Pink',
    'FF8FAB': 'Light Pink',
    '6366F1': 'Blue',
    '8B5CF6': 'Purple',
    '10B981': 'Green',
    '34D399': 'Light Green',
    'F59E0B': 'Orange',
    'EF4444': 'Red',
  };

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      _titleController.text = widget.promo!.title;
      _subtitleController.text = widget.promo!.subtitle;
      _orderController.text = widget.promo!.order.toString();
      _color1 = widget.promo!.color1;
      _color2 = widget.promo!.color2;
      _isActive = widget.promo!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _savePromo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.promo == null) {
        // Tambah baru
        await _service.db.collection('promos').add({
          'title': _titleController.text.trim(),
          'subtitle': _subtitleController.text.trim(),
          'color1': _color1,
          'color2': _color2,
          'isActive': _isActive,
          'order': int.tryParse(_orderController.text) ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update
        await _service.db.collection('promos').doc(widget.promo!.id).update({
          'title': _titleController.text.trim(),
          'subtitle': _subtitleController.text.trim(),
          'color1': _color1,
          'color2': _color2,
          'isActive': _isActive,
          'order': int.tryParse(_orderController.text) ?? 0,
        });
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.promo == null ? 'Promo berhasil ditambahkan!' : 'Promo berhasil diperbarui!'),
          backgroundColor: const Color(0xFFFF6B9D),
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
    final isEdit = widget.promo != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Promo' : 'Tambah Promo Baru',
          style: const TextStyle(
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
                    // Preview Promo
                    _buildSectionHeader('Preview Promo'),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(int.parse('0xFF$_color1')),
                            Color(int.parse('0xFF$_color2')),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController.text.isEmpty ? 'Judul Promo' : _titleController.text,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _subtitleController.text.isEmpty ? 'Deskripsi promo...' : _subtitleController.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Shop Now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(int.parse('0xFF$_color1')),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Informasi Promo'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Judul Promo',
                        hintText: 'Contoh: Big Sale',
                        prefixIcon: const Icon(Icons.title, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      onChanged: (value) => setState(() {}),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Contoh: Get Up To 50% Off\\non all flowers this week!',
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
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Urutan (0 = paling awal)',
                        prefixIcon: const Icon(Icons.sort, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                        helperText: 'Semakin kecil angka, semakin awal urutan',
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Warna Gradient'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Warna 1',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildColorDropdown(_color1, (value) {
                                setState(() => _color1 = value);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Warna 2',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildColorDropdown(_color2, (value) {
                                setState(() => _color2 = value);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Status'),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Aktifkan Promo'),
                      subtitle: Text(_isActive ? 'Promo ditampilkan di halaman utama' : 'Promo tidak ditampilkan'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      activeColor: const Color(0xFFFF6B9D),
                      contentPadding: EdgeInsets.zero,
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
                    onPressed: _isLoading ? null : _savePromo,
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
                        : Text(
                            isEdit ? 'Perbarui Promo' : 'Tambahkan Promo',
                            style: const TextStyle(
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

  Widget _buildColorDropdown(String currentColor, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentColor,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B9D)),
          items: _colorOptions.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${entry.key}')),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}