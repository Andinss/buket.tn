import 'package:flutter/material.dart';
import 'dart:async';

import '../models/bouquet.dart';
import '../models/cart_item.dart';
import '../services/firebase_service.dart';

class CartProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  List<CartItem> items = [];
  String? _currentUserId;
  StreamSubscription<List<CartItem>>? _cartSubscription;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _cartSubscription?.cancel();
    
    if (userId != null) {
      _loadCartFromFirebase(userId);
    } else {
      items.clear();
      notifyListeners();
    }
  }

  void _loadCartFromFirebase(String userId) {
    _isLoading = true;
    notifyListeners();

    _cartSubscription = _service.getCartItems(userId).listen(
      (cartItems) {
        items = cartItems;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading cart: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addItem(Bouquet bouquet, int quantity) async {
    if (_currentUserId == null) {
      debugPrint('Cannot add to cart: User not logged in');
      return;
    }

    try {
      final existingIndex = items.indexWhere((item) => item.bouquet.id == bouquet.id);
      
      if (existingIndex >= 0) {
        final newQuantity = items[existingIndex].quantity + quantity;
        await _service.updateCartItemQuantity(_currentUserId!, bouquet.id, newQuantity);
      } else {
        final cartItem = CartItem(bouquet: bouquet, quantity: quantity);
        await _service.addToCart(_currentUserId!, cartItem);
      }
    } catch (e) {
      debugPrint('Error adding item to cart: $e');
      rethrow;
    }
  }

  Future<void> removeItem(String bouquetId) async {
    if (_currentUserId == null) return;

    try {
      await _service.removeFromCart(_currentUserId!, bouquetId);
    } catch (e) {
      debugPrint('Error removing item from cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String bouquetId, int newQuantity) async {
    if (_currentUserId == null) return;

    try {
      if (newQuantity < 1) {
        await removeItem(bouquetId);
      } else {
        await _service.updateCartItemQuantity(_currentUserId!, bouquetId, newQuantity);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> clear() async {
    if (_currentUserId == null) return;

    try {
      await _service.clearCart(_currentUserId!);
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  int getTotalItems() => items.fold(0, (sum, item) => sum + item.quantity);
  int getTotalPrice() => items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}