import 'package:flutter/material.dart';
import 'dart:async';

import '../models/address.dart';
import '../services/firebase_service.dart';

class AddressProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<Address> addresses = [];
  String? _currentUserId;
  StreamSubscription<List<Address>>? _addressSubscription;
  bool _isLoading = false;
  Address? _selectedAddress;

  bool get isLoading => _isLoading;
  Address? get selectedAddress => _selectedAddress;
  Address? get defaultAddress => addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.isNotEmpty ? addresses.first : Address(
          id: '',
          label: '',
          recipientName: '',
          phoneNumber: '',
          fullAddress: '',
          city: '',
          postalCode: '',
          createdAt: DateTime.now(),
        ),
      );

  void setUser(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _addressSubscription?.cancel();

    if (userId != null) {
      _loadAddresses(userId);
    } else {
      addresses.clear();
      _selectedAddress = null;
      notifyListeners();
    }
  }

  void _loadAddresses(String userId) {
    _isLoading = true;
    notifyListeners();

    _addressSubscription = _service.getAddresses(userId).listen(
      (addressList) {
        addresses = addressList;
        _isLoading = false;
        
        if (_selectedAddress == null && addresses.isNotEmpty) {
          _selectedAddress = defaultAddress;
        }
        
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading addresses: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String> addAddress(Address address) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      final addressId = await _service.addAddress(_currentUserId!, address);
      return addressId;
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(String addressId, Address address) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _service.updateAddress(_currentUserId!, addressId, address);
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _service.deleteAddress(_currentUserId!, addressId);
      
      if (_selectedAddress?.id == addressId) {
        _selectedAddress = null;
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _service.setDefaultAddress(_currentUserId!, addressId);
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void clearSelection() {
    _selectedAddress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    super.dispose();
  }
}