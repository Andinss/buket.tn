import 'package:cloud_firestore/cloud_firestore.dart';
import 'bouquet.dart';

class CartItem {
  final Bouquet bouquet;
  int quantity;

  CartItem({
    required this.bouquet,
    this.quantity = 1,
  });

  int get price => bouquet.price;

  Map<String, dynamic> toMap() {
    return {
      'bouquetId': bouquet.id,
      'bouquetData': bouquet.toMap(),
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, String bouquetId) {
    final bouquetData = map['bouquetData'] as Map<String, dynamic>;
    
    return CartItem(
      bouquet: Bouquet(
        id: bouquetId,
        name: bouquetData['name'] ?? '',
        description: bouquetData['description'] ?? '',
        price: bouquetData['price'] ?? 0,
        images: List<String>.from(bouquetData['images'] ?? []),
        category: bouquetData['category'] ?? '',
        details: bouquetData['details'] ?? '',
        sellerId: bouquetData['sellerId'] ?? '',
      ),
      quantity: map['quantity'] ?? 1,
    );
  }
}