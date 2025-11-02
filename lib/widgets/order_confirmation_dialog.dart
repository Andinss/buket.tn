import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';
import '../utils/helpers.dart';
import '../pages/address_list_page.dart';

class OrderConfirmationDialog extends StatefulWidget {
  final List<CartItem> items;
  final int total;
  final AuthProvider auth;
  final Function(String phone, String address, String city, String postalCode, String paymentMethod) onConfirm;

  const OrderConfirmationDialog({
    super.key,
    required this.items,
    required this.total,
    required this.auth,
    required this.onConfirm,
  });

  @override
  State<OrderConfirmationDialog> createState() => _OrderConfirmationDialogState();
}

class _OrderConfirmationDialogState extends State<OrderConfirmationDialog> {
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'Transfer Bank';
  final List<String> _paymentMethods = [
    'Transfer Bank',
    'E-Wallet',
    'Bayar di Tempat (COD)'
  ];

  Address? _selectedAddress;

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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final addressProvider = Provider.of<AddressProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shopping_cart_checkout, color: Color(0xFFFF6B9D), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    _buildSectionHeader('Alamat Pengiriman'),
                    const SizedBox(height: 12),
                    
                    _selectedAddress != null
                        ? _buildSelectedAddress(_selectedAddress!)
                        : _buildNoAddress(),
                    
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    
                    _buildSectionHeader('Catatan Pesanan (Opsional)'),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan untuk penjual...',
                        prefixIcon: const Icon(Icons.note, color: Color(0xFFFF6B9D)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    
                    _buildSectionHeader('Metode Pembayaran'),
                    const SizedBox(height: 16),
                    
                    ..._buildPaymentMethods(),
                    
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    
                    _buildSectionHeader('Ringkasan Pesanan'),
                    const SizedBox(height: 16),
                    
                    _buildOrderSummary(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
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
                      onPressed: _selectedAddress == null
                          ? null
                          : () {
                              widget.onConfirm(
                                _selectedAddress!.phoneNumber,
                                _selectedAddress!.fullAddress,
                                _selectedAddress!.city,
                                _selectedAddress!.postalCode,
                                _selectedPaymentMethod,
                              );
                            },
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
                      child: Text(
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
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAddress(Address address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B9D), width: 1),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address.phoneNumber,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            address.formattedAddress,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
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
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Belum ada alamat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan alamat pengiriman',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressListPage(),
                ),
              );
              _loadDefaultAddress();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Alamat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
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
      } else if (method == 'Bayar di Tempat (COD)') {
        description = 'Bayar saat barang diterima';
      }
      
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
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
        color: Colors.grey.shade50,
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
          _buildDivider(),
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
}