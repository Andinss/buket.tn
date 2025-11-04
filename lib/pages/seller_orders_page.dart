import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../services/firebase_service.dart';
import '../models/order.dart';
import '../models/custom_order.dart';
import '../utils/helpers.dart';
import 'order_detail_full_page.dart';
import 'custom_order_detail_page.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Kembali ke 5 tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pesanan Masuk', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFFFF6B9D),
            labelColor: const Color(0xFFFF6B9D),
            unselectedLabelColor: Colors.grey,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.only(left: 20, right: 20),
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Diproses'),
              Tab(text: 'Dikemas'),
              Tab(text: 'Dikirim'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.db.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, orderSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: service.db.collection('custom_orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, customSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting ||
                  customSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)));
              }

              if (orderSnapshot.hasError || customSnapshot.hasError) {
                debugPrint('Error: ${orderSnapshot.error ?? customSnapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Color(0xFFFF6B9D)),
                      const SizedBox(height: 16),
                      const Text('Terjadi Kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Error: ${orderSnapshot.error ?? customSnapshot.error}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              }

              try {
                final allOrders = orderSnapshot.data!.docs.map((doc) {
                  try {
                    return Order.fromDoc(doc);
                  } catch (e) {
                    debugPrint('Error parsing order ${doc.id}: $e');
                    return Order(
                      id: doc.id,
                      buyerId: 'Unknown',
                      items: [],
                      total: 0,
                      status: 'placed',
                      createdAt: DateTime.now(),
                    );
                  }
                }).toList();

                final customOrders = customSnapshot.data!.docs.map((doc) {
                  try {
                    return CustomOrder.fromDoc(doc);
                  } catch (e) {
                    debugPrint('Error parsing custom order ${doc.id}: $e');
                    return null;
                  }
                }).whereType<CustomOrder>().toList();

                final placedOrders = allOrders.where((o) => o.status == 'placed').toList();
                final processingOrders = allOrders.where((o) => o.status == 'processing').toList();
                final shippedOrders = allOrders.where((o) => o.status == 'shipped').toList();
                final completedOrders = allOrders.where((o) => o.status == 'completed').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMixedOrdersList(allOrders, customOrders, 'Belum Ada Pesanan'),
                    _buildSellerOrdersList(placedOrders, 'Tidak ada pesanan yang diproses'),
                    _buildSellerOrdersList(processingOrders, 'Tidak ada pesanan yang dikemas'),
                    _buildSellerOrdersList(shippedOrders, 'Tidak ada pesanan yang dikirim'),
                    _buildSellerOrdersList(completedOrders, 'Tidak ada pesanan yang selesai'),
                  ],
                );
              } catch (e) {
                debugPrint('Error building orders list: $e');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Color(0xFFFF6B9D)),
                      const SizedBox(height: 16),
                      const Text('Error Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$e', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // TAMBAHAN: Widget untuk menampilkan campuran order regular dan custom
  Widget _buildMixedOrdersList(List<Order> orders, List<CustomOrder> customOrders, String emptyMessage) {
    if (orders.isEmpty && customOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(color: Color(0xFFFFE8F0), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 80, color: Color(0xFFFF6B9D)),
            ),
            const SizedBox(height: 30),
            Text(emptyMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 12),
            Text('Belum ada pesanan dengan status ini', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFFFF6B9D),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...customOrders.map((order) => _buildCustomOrderItem(order)),
          ...orders.map((order) => _buildSellerOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildSellerOrdersList(List<Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(color: Color(0xFFFFE8F0), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 80, color: Color(0xFFFF6B9D)),
            ),
            const SizedBox(height: 30),
            Text(emptyMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 12),
            Text('Belum ada pesanan dengan status ini', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFFFF6B9D),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildSellerOrderItem(order);
        },
      ),
    );
  }

  // TAMBAHAN: Widget untuk custom order item dengan label yang sama seperti di buyer
  Widget _buildCustomOrderItem(CustomOrder order) {
    Color statusColor;
    Color statusTextColor;
    String statusLabel;

    switch (order.status) {
      case 'pending':
        statusColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFC78500);
        statusLabel = 'Menunggu';
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomOrderDetailPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF6B9D), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'CUSTOM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Buyer Info
            Text(
              order.buyerName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(formatRupiah(order.budget), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${order.flowerType} • ${order.colorPreference} • ${order.occasion}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerOrderItem(Order order) {
    final statusColor = getStatusColor(order.status);
    final statusTextColor = getStatusTextColor(order.status);
    final statusLabel = getStatusLabel(order.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailFullPage(order: order, isSeller: true),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: order.isCustomOrder ? Border.all(color: const Color(0xFFFF6B9D), width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Order #${order.id.substring(0, 8).toUpperCase()}', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          if (order.isCustomOrder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'CUSTOM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Payment Status
            Row(
              children: [
                Icon(
                  order.isPaid ? Icons.check_circle : Icons.pending,
                  size: 16,
                  color: order.isPaid ? const Color(0xFF16A34A) : const Color(0xFFC78500),
                ),
                const SizedBox(width: 6),
                Text(
                  order.isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order.isPaid ? const Color(0xFF16A34A) : const Color(0xFFC78500),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• ${order.paymentMethod}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item(s)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  formatRupiah(order.total.toInt()),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}