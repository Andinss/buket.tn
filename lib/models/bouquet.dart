import 'package:cloud_firestore/cloud_firestore.dart';

class Bouquet {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<String> images;
  final String category;
  final String details;
  final String sellerId;
  final int estimationDays; 

  Bouquet({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.details,
    required this.sellerId,
    this.estimationDays = 1,
  });

  factory Bouquet.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bouquet(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      price: d['price'] ?? 0,
      images: List<String>.from(d['images'] ?? []),
      category: d['category'] ?? '',
      details: d['details'] ?? '',
      sellerId: d['sellerId'] ?? '',
      estimationDays: d['estimationDays'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'images': images,
    'category': category,
    'details': details,
    'sellerId': sellerId,
    'estimationDays': estimationDays,
  };
  
  String get estimationText {
    if (estimationDays == 0) {
      return 'Ready Stock';
    } else if (estimationDays == 1) {
      return 'Pre-order 1 Hari';
    } else {
      return 'Pre-order $estimationDays Hari';
    }
  }
}