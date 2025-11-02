import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String postalCode;
  final String? notes;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.postalCode,
    this.notes,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'fullAddress': fullAddress,
      'city': city,
      'postalCode': postalCode,
      'notes': notes,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  factory Address.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Address(
      id: doc.id,
      label: data['label'] ?? 'Alamat',
      recipientName: data['recipientName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      city: data['city'] ?? '',
      postalCode: data['postalCode'] ?? '',
      notes: data['notes'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      label: map['label'] ?? 'Alamat',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      notes: map['notes'],
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedAddress {
    String result = fullAddress;
    if (city.isNotEmpty) result += ', $city';
    if (postalCode.isNotEmpty) result += ' $postalCode';
    return result;
  }

  Address copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? fullAddress,
    String? city,
    String? postalCode,
    String? notes,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}