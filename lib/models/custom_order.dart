import 'package:cloud_firestore/cloud_firestore.dart';

class CustomOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final int budget;
  final String flowerType;
  final String colorPreference;
  final String occasion;
  final String additionalNotes;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryPostalCode;
  final String status; 
  final DateTime createdAt;
  final String? rejectionReason;
  final int? finalPrice;

  CustomOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.budget,
    required this.flowerType,
    required this.colorPreference,
    required this.occasion,
    required this.additionalNotes,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryPostalCode,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.finalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'budget': budget,
      'flowerType': flowerType,
      'colorPreference': colorPreference,
      'occasion': occasion,
      'additionalNotes': additionalNotes,
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryPostalCode': deliveryPostalCode,
      'status': status,
      'createdAt': createdAt,
      'rejectionReason': rejectionReason,
      'finalPrice': finalPrice,
    };
  }

  factory CustomOrder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomOrder(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      budget: data['budget'] ?? 0,
      flowerType: data['flowerType'] ?? '',
      colorPreference: data['colorPreference'] ?? '',
      occasion: data['occasion'] ?? '',
      additionalNotes: data['additionalNotes'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryCity: data['deliveryCity'] ?? '',
      deliveryPostalCode: data['deliveryPostalCode'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: data['rejectionReason'],
      finalPrice: data['finalPrice'],
    );
  }
}