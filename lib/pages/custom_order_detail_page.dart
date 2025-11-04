import 'package:flutter/material.dart';

import '../models/custom_order.dart';
import '../utils/helpers.dart';
import '../pages/order_chat_page.dart';
import '../models/order.dart';

class CustomOrderDetailPage extends StatelessWidget {
  final CustomOrder order;

  const CustomOrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusTextColor;
    String statusLabel;

    switch (order.status) {
      case 'pending':
        statusColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFC78500);
        statusLabel = 'Menunggu Konfirmasi';
        break;
      case 'accepted':
        statusColor = const Color(0xFFDCFCE7);
        statusTextColor = const Color(0xFF16A34A);
        statusLabel = 'Diterima';
        break;
      case 'rejected':
        statusColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        statusLabel = 'Ditolak';
        break;
      case 'completed':
        statusColor = const Color(0xFFDDD6FE);
        statusTextColor = const Color(0xFF5B21B6);
        statusLabel = 'Selesai';
        break;
      default:
        statusColor = const Color(0xFFFFE8F0);
        statusTextColor = const Color(0xFFFF6B9D);
        statusLabel = 'Pending';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Pesanan Custom',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Order #${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Detail Pesanan
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFFF6B9D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Detail Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Budget', formatRupiah(order.budget)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Jenis Bunga', order.flowerType),
                  const SizedBox(height: 12),
                  _buildInfoRow('Warna', order.colorPreference),
                  const SizedBox(height: 12),
                  _buildInfoRow('Keperluan', order.occasion),
                  if (order.finalPrice != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Harga Final',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            formatRupiah(order.finalPrice!),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Catatan Tambahan
            if (order.additionalNotes.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, color: Color(0xFFFF6B9D), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Catatan Tambahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.additionalNotes,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (order.additionalNotes.isNotEmpty) const SizedBox(height: 12),

            // Alamat Pengiriman
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFFFF6B9D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nama Penerima', order.buyerName),
                  const SizedBox(height: 12),
                  _buildInfoRow('Telepon', order.buyerPhone),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Alamat',
                    '${order.deliveryAddress}, ${order.deliveryCity} ${order.deliveryPostalCode}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Rejection Reason
            if (order.status == 'rejected' && order.rejectionReason != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDC2626), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFDC2626),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Tombol Chat dengan Penjual
            if (order.customOrderId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Buat dummy order untuk chat
                      final dummyOrder = Order(
                        id: order.customOrderId!,
                        buyerId: order.buyerId,
                        items: [],
                        total: order.budget.toDouble(),
                        status: 'placed',
                        createdAt: order.createdAt,
                        isCustomOrder: true,
                        customOrderId: order.id,
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderChatPage(order: dummyOrder),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text(
                      'Chat dengan Penjual',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B9D),
                      side: const BorderSide(color: Color(0xFFFF6B9D), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
        ),
      ],
    );
  }
}