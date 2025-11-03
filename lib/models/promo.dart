import 'package:cloud_firestore/cloud_firestore.dart';

class Promo {
  final String id;
  final String title;
  final String subtitle;
  final String color1;
  final String color2;
  final bool isActive;
  final int order;
  final DateTime createdAt;

  Promo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'color1': color1,
      'color2': color2,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt,
    };
  }

  factory Promo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Promo(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      color1: data['color1'] ?? 'FF6B9D',
      color2: data['color2'] ?? 'FF8FAB',
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}