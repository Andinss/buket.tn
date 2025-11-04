import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';
import '../utils/helpers.dart';
import '../pages/address_list_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final int total;
  final AuthProvider auth;
  final CartProvider cart;

  const CheckoutPage({
    super.key,
    required this.items,
    required this.total,
    required this.auth,
    required this.cart,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedPaymentMethod = 'Transfer Bank';
  Address? _selectedAddress;
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    'Transfer Bank',
    'E-Wallet',
    'Bayar di Tempat (COD)'
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    if (addressProvider.addresses.isNotEmpty) {
      setState(() {
        _selectedAddress = addressProvider.defaultAddress;
      });
    }
  }

  Future<void> _processCheckout() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alamat pengiriman terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update profile jika perlu
      if (widget.auth.phoneNumber.isEmpty) {
        await widget.auth.updateProfile(
          widget.auth.user?.displayName ?? 'User',
          _selectedAddress!.phoneNumber,
          _selectedAddress!.fullAddress,
          _selectedAddress!.city,
          _selectedAddress!.postalCode,
          _selectedPaymentMethod,
        );
      }

      // Place order
      final service = FirebaseService();
      await service.placeOrder(
        widget.auth.user!.uid,
        widget.items,
        widget.total.toDouble(),
        _selectedPaymentMethod,
      );

      // Remove items from cart
      for (var item in widget.items) {
        await widget.cart.removeItem(item.bouquet.id);
      }

      if (!mounted) return;

      // Navigate back to home
      Navigator.popUntil(context, (route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat!'),
          backgroundColor: Color(0xFFFF6B9D),
          behavior: SnackBarBehavior.floating,
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
        setState(() => _isProcessing = false);
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
          'Checkout',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Alamat Pengiriman'),
                  const SizedBox(height: 12),
                  _selectedAddress != null
                      ? _buildSelectedAddress(_selectedAddress!)
                      : _buildNoAddress(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Catatan Pesanan (Opsional)'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan untuk penjual...',
                      prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
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
                  _buildSectionHeader('Metode Pembayaran'),
                  const SizedBox(height: 12),
                  ..._buildPaymentMethods(),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Ringkasan Pesanan'),
                  const SizedBox(height: 12),
                  _buildOrderSummary(),
                ],
              ),
            ),
          ),
          
          // Bottom bar dengan total dan tombol bayar
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Text(
                        formatRupiah(widget.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B9D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing || _selectedAddress == null
                          ? null
                          : _processCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAddress == null
                            ? Colors.grey
                            : const Color(0xFFFF6B9D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedAddress == null
                                  ? 'Pilih Alamat Terlebih Dahulu'
                                  : 'Bayar ${formatRupiah(widget.total)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildSelectedAddress(Address address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B9D), width: 2),
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
                  address.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final selected = await Navigator.push<Address>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressListPage(isSelectMode: true),
                    ),
                  );
                  
                  if (selected != null) {
                    setState(() {
                      _selectedAddress = selected;
                    });
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Ubah'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B9D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.recipientName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(address.phoneNumber),
          const SizedBox(height: 8),
          Text(address.formattedAddress),
        ],
      ),
    );
  }

  Widget _buildNoAddress() {
    return Container(
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressListPage(),
                ),
              );
              _loadDefaultAddress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
            ),
            child: const Text('Tambah Alamat'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentMethods() {
    return _paymentMethods.map((method) {
      final bool isSelected = _selectedPaymentMethod == method;
      
      String description = '';
      if (method == 'Transfer Bank') {
        description = 'BCA, BNI, Mandiri, BRI';
      } else if (method == 'E-Wallet') {
        description = 'Gopay, OVO, Dana, LinkAja';
      } else {
        description = 'Bayar saat barang diterima';
      }
      
      return GestureDetector(
        onTap: () {
          setState(() => _selectedPaymentMethod = method);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFF6B9D) : Colors.transparent,
border: Border.all(
                    color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFF2D3142),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Produk',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Subtotal',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          ...widget.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.bouquet.name} × ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    formatRupiah(item.price * item.quantity),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  formatRupiah(widget.total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B9D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}