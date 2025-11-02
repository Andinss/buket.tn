import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../services/firebase_service.dart';
import '../models/custom_order.dart';
import '../pages/address_list_page.dart';

class CustomOrderPage extends StatefulWidget {
  const CustomOrderPage({super.key});

  @override
  State<CustomOrderPage> createState() => _CustomOrderPageState();
}

class _CustomOrderPageState extends State<CustomOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  
  String _selectedFlowerType = 'Campuran';
  String _selectedColor = 'Bebas';
  String _selectedOccasion = 'Ulang Tahun';
  bool _isLoading = false;

  final List<String> _flowerTypes = [
    'Campuran',
    'Mawar',
    'Tulip',
    'Lily',
    'Anggrek',
    'Carnation',
    'Hydrangea',
  ];

  final List<String> _colors = [
    'Bebas',
    'Merah',
    'Pink',
    'Putih',
    'Kuning',
    'Ungu',
    'Biru',
    'Orange',
  ];

  final List<String> _occasions = [
    'Ulang Tahun',
    'Anniversary',
    'Wisuda',
    'Pernikahan',
    'Duka Cita',
    'Ucapan Terima Kasih',
    'Get Well Soon',
    'Lainnya',
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitCustomOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final defaultAddress = addressProvider.defaultAddress;
    if (defaultAddress == null || defaultAddress.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan alamat pengiriman terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customOrder = CustomOrder(
        id: '',
        buyerId: auth.user!.uid,
        buyerName: auth.user!.displayName ?? '',
        buyerPhone: auth.phoneNumber.isEmpty ? defaultAddress.phoneNumber : auth.phoneNumber,
        budget: int.parse(_budgetController.text),
        flowerType: _selectedFlowerType,
        colorPreference: _selectedColor,
        occasion: _selectedOccasion,
        additionalNotes: _additionalNotesController.text.trim(),
        deliveryAddress: defaultAddress.fullAddress,
        deliveryCity: defaultAddress.city,
        deliveryPostalCode: defaultAddress.postalCode,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final service = FirebaseService();
      await service.createCustomOrder(customOrder);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan custom berhasil dibuat! Tunggu konfirmasi dari penjual.'),
          backgroundColor: Color(0xFFFF6B9D),
          duration: Duration(seconds: 3),
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
    final addressProvider = Provider.of<AddressProvider>(context);
    final defaultAddress = addressProvider.defaultAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Custom Bouquet',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Bouquet Impianmu!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sesuaikan dengan budget dan preferensimu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Budget Kamu'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Masukkan Budget (Rp)',
                  hintText: 'Contoh: 150000',
                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFF6B9D)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Budget tidak boleh kosong';
                  }
                  final budget = int.tryParse(value!);
                  if (budget == null || budget < 50000) {
                    return 'Budget minimal Rp 50.000';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Jenis Bunga'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFlowerType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B9D)),
                    items: _flowerTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFlowerType = value!);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Warna Preferensi'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return ChoiceChip(
                    label: Text(color),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedColor = color);
                    },
                    selectedColor: const Color(0xFFFF6B9D),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Keperluan/Acara'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOccasion,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B9D)),
                    items: _occasions.map((occasion) {
                      return DropdownMenuItem(
                        value: occasion,
                        child: Text(occasion),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedOccasion = value!);
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Catatan Tambahan'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Saya ingin bouquet yang romantis dengan pita merah...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader('Alamat Pengiriman'),
              const SizedBox(height: 12),
              
              defaultAddress != null && defaultAddress.id.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6B9D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B9D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  defaultAddress.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressListPage(),
                                    ),
                                  );
                                },
                                child: const Text('Ubah'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            defaultAddress.recipientName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(defaultAddress.phoneNumber),
                          const SizedBox(height: 8),
                          Text(
                            defaultAddress.formattedAddress,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Belum ada alamat'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddressListPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                            ),
                            child: const Text('Tambah Alamat'),
                          ),
                        ],
                      ),
                    ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCustomOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Kirim Pesanan Custom',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pesanan custom akan diproses dalam 1-2 hari kerja',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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