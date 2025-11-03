import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String buyerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String paymentMethod;
  final bool isPaid;
  final String? paymentProofUrl;

  Order({
    required this.id,
    required this.buyerId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod = 'Transfer Bank',
    this.isPaid = false,
    this.paymentProofUrl,
  });

  factory Order.fromDoc(DocumentSnapshot doc) {
    try {
      final d = doc.data() as Map<String, dynamic>? ?? {};
      
      List<Map<String, dynamic>> itemsList = [];
      try {
        final itemsData = d['items'];
        if (itemsData is List) {
          itemsList = itemsData.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              return <String, dynamic>{};
            }
          }).toList();
        }
      } catch (e) {
        itemsList = [];
      }

      double totalValue = 0;
      try {
        final totalData = d['total'];
        if (totalData is int) {
          totalValue = totalData.toDouble();
        } else if (totalData is double) {
          totalValue = totalData;
        } else if (totalData is String) {
          totalValue = double.tryParse(totalData) ?? 0;
        }
      } catch (e) {
        totalValue = 0;
      }

      DateTime createdAtValue = DateTime.now();
      try {
        final createdAtData = d['createdAt'];
        if (createdAtData is Timestamp) {
          createdAtValue = createdAtData.toDate();
        } else if (createdAtData is String) {
          createdAtValue = DateTime.tryParse(createdAtData) ?? DateTime.now();
        }
      } catch (e) {
        createdAtValue = DateTime.now();
      }

      return Order(
        id: doc.id,
        buyerId: d['buyerId']?.toString() ?? 'Unknown',
        items: itemsList,
        total: totalValue,
        status: d['status']?.toString() ?? 'placed',
        createdAt: createdAtValue,
        paymentMethod: d['paymentMethod']?.toString() ?? 'Transfer Bank',
        isPaid: d['isPaid'] ?? false,
        paymentProofUrl: d['paymentProofUrl']?.toString(),
      );
    } catch (e) {
      return Order(
        id: doc.id,
        buyerId: 'Unknown',
        items: [],
        total: 0,
        status: 'placed',
        createdAt: DateTime.now(),
        paymentMethod: 'Transfer Bank',
        isPaid: false,
      );
    }
  }
}