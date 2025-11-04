import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/order.dart';
import '../models/custom_order.dart';
import '../utils/helpers.dart';
import 'main_navigation.dart';
import 'order_detail_full_page.dart';
import 'custom_order_detail_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final service = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Aktivitas Pesanan', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        bottom: auth.user == null
            ? null
            : PreferredSize(
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
                    Tab(text: 'Custom'),
                  ],
                ),
              ),
      ),
      body: auth.user == null
          ? const Center(child: Text('Silakan login untuk melihat pesanan'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllOrdersTab(auth.user!.uid, service),
                _buildOrdersByStatus(auth.user!.uid, service, 'placed'),
                _buildOrdersByStatus(auth.user!.uid, service, 'processing'),
                _buildOrdersByStatus(auth.user!.uid, service, 'shipped'),
                _buildOrdersByStatus(auth.user!.uid, service, 'completed'),
                _buildCustomOrdersTab(auth.user!.uid, service),
              ],
            ),
    );
  }

  Widget _buildAllOrdersTab(String userId, FirebaseService service) {
    return StreamBuilder<List<Order>>(
      stream: service.getUserOrders(userId),
      builder: (context, orderSnapshot) {
        return StreamBuilder<List<CustomOrder>>(
          stream: service.getBuyerCustomOrders(userId),
          builder: (context, customSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting ||
                customSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF6B9D)),
                    SizedBox(height: 16),
                    Text('Memuat pesanan...'),
                  ],
                ),
              );
            }

            final orders = orderSnapshot.data ?? [];
            final customOrders = customSnapshot.data ?? [];

            if (orders.isEmpty && customOrders.isEmpty) {
              return _buildEmptyOrders();
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (customOrders.isNotEmpty) ...[
                  ...customOrders.map((order) => _buildCustomOrderItem(order)),
                ],
                ...orders.map((order) => _buildOrderItem(order)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersByStatus(String userId, FirebaseService service, String status) {
    return StreamBuilder<List<Order>>(
      stream: service.getUserOrders(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          );
        }

        final allOrders = snapshot.data ?? [];
        final filteredOrders = allOrders.where((o) => o.status == status).toList();

        if (filteredOrders.isEmpty) {
          return _buildEmptyState('Tidak ada pesanan dengan status ini');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            return _buildOrderItem(filteredOrders[index]);
          },
        );
      },
    );
  }

  Widget _buildCustomOrdersTab(String userId, FirebaseService service) {
    return StreamBuilder<List<CustomOrder>>(
      stream: service.getBuyerCustomOrders(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          );
        }

        final customOrders = snapshot.data ?? [];

        if (customOrders.isEmpty) {
          return _buildEmptyState('Belum ada pesanan custom');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: customOrders.length,
          itemBuilder: (context, index) {
            return _buildCustomOrderItem(customOrders[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyOrders() {
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
          const Text('Belum Ada Pesanan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 12),
          Text('Belum ada riwayat pesanan', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _navigateToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text('Mulai Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
          Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ],
      ),
    );
  }

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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomOrderDetailPage(order: order),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6366F1), width: 2),
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
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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

  Widget _buildOrderItem(Order order) {
    final statusColor = getStatusColor(order.status);
    final statusTextColor = getStatusTextColor(order.status);
    final statusLabel = getStatusLabel(order.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailFullPage(order: order, isSeller: false),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: order.isCustomOrder ? Border.all(color: const Color(0xFF6366F1), width: 2) : null,
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
                          Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          if (order.isCustomOrder) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusTextColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(order.isPaid ? Icons.check_circle : Icons.pending, size: 14, color: order.isPaid ? const Color(0xFF16A34A) : const Color(0xFFC78500)),
                const SizedBox(width: 6),
                Text(
                  order.isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: order.isPaid ? const Color(0xFF16A34A) : const Color(0xFFC78500)),
                ),
                const SizedBox(width: 4),
                Text('• ${order.paymentMethod}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Pesanan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${item['name']} × ${item['qty']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Text(formatRupiah(item['price'] * item['qty']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                Text(formatRupiah(order.total.toInt()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF6B9D))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}