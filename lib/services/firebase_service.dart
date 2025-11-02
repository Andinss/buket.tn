import 'package:buket_tn/models/custom_order.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

import '../models/bouquet.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/address.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Email sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      final userCred = await auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCred.user?.updateDisplayName(name);
      final uid = userCred.user!.uid;
      
      String role = 'buyer';
      if (email.toLowerCase() == 'andinn1404@gmail.com') {
        role = 'seller';
      }
      
      await db.collection('users').doc(uid).set({
        'displayName': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return userCred;
    } catch (e) {
      debugPrint('Email registration error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await auth.signInWithCredential(credential);
      final uid = userCred.user!.uid;
      final doc = db.collection('users').doc(uid);
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        String role = 'buyer';
        final email = userCred.user!.email ?? '';
        if (email.toLowerCase() == 'andinn1404@gmail.com') {
          role = 'seller';
        }
        
        await doc.set({
          'displayName': userCred.user!.displayName ?? '',
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return userCred;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await auth.signOut();
  }

  Future<void> setUserRole(String uid, String role) async {
    await db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));
  }

  Future<String?> getUserRole(String uid) async {
    final snap = await db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return (snap.data()!['role'] ?? '') as String;
  }

  Future<void> seedBouquetsIfNeeded() async {
    final col = db.collection('bouquets');
    final snap = await col.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final sample = [
      {
        'name': 'Tulip Garden',
        'description': 'Buket tulip warna-warni',
        'price': 0,
        'images': [
          'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=500&h=500&fit=crop',
        ],
        'category': 'Elegant',
        'details': 'Tulip premium dengan berbagai warna elegan. Simbol cinta sempurna dan keindahan abadi.',
        'sellerId': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Tulip Garden',
        'description': 'Buket tulip warna-warni',
        'price': 0,
        'images': [
          'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=500&h=500&fit=crop',
        ],
        'category': 'Elegant',
        'details': 'Tulip premium dengan berbagai warna elegan. Simbol cinta sempurna dan keindahan abadi.',
        'sellerId': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Tulip Garden',
        'description': 'Buket tulip warna-warni',
        'price': 0,
        'images': [
          'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=500&h=500&fit=crop',
        ],
        'category': 'Elegant',
        'details': 'Tulip premium dengan berbagai warna elegan. Simbol cinta sempurna dan keindahan abadi.',
        'sellerId': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Tulip Garden',
        'description': 'Buket tulip warna-warni',
        'price': 0,
        'images': [
          'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=500&h=500&fit=crop',
        ],
        'category': 'Elegant',
        'details': 'Tulip premium dengan berbagai warna elegan. Simbol cinta sempurna dan keindahan abadi.',
        'sellerId': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = db.batch();
    for (final p in sample) {
      final doc = col.doc();
      batch.set(doc, p);
    }
    await batch.commit();
  }

  Future<void> placeOrder(String uid, List<CartItem> items, double total) async {
    try {
      final doc = db.collection('orders').doc();
      await doc.set({
        'buyerId': uid,
        'items': items.map((c) => {
          'bouquetId': c.bouquet.id,
          'name': c.bouquet.name,
          'price': c.price,
          'qty': c.quantity,
        }).toList(),
        'total': total,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'placed',
      });
      debugPrint('Order placed successfully with ID: ${doc.id}');
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  Stream<List<Order>> getUserOrders(String uid) {
    return db.collection('orders')
        .where('buyerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Order.fromDoc(doc)).toList())
        .handleError((error) {
          debugPrint('Error in getUserOrders: $error');
          return <Order>[];
        });
  }

  Future<void> toggleFavorite(String uid, String bouquetId) async {
    final favRef = db.collection('users').doc(uid).collection('favorites').doc(bouquetId);
    final snap = await favRef.get();
    if (snap.exists) {
      await favRef.delete();
    } else {
      await favRef.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<List<String>> getFavorites(String uid) {
    return db.collection('users').doc(uid).collection('favorites').snapshots().map(
      (snap) => snap.docs.map((doc) => doc.id).toList(),
    );
  }

  Future<void> addBouquet(Bouquet bouquet) async {
    final col = db.collection('bouquets');
    final data = bouquet.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await col.add(data);
  }

  Future<void> updateBouquet(String id, Bouquet bouquet) async {
    final docRef = db.collection('bouquets').doc(id);
    final data = bouquet.toMap();
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> deleteBouquet(String id) async {
    await db.collection('bouquets').doc(id).delete();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await db.collection('orders').doc(orderId).set({'status': status}, SetOptions(merge: true));
  }

  Future<void> addToCart(String uid, CartItem cartItem) async {
    try {
      final cartRef = db.collection('users').doc(uid).collection('cart').doc(cartItem.bouquet.id);
      await cartRef.set(cartItem.toMap());
      debugPrint('Item added to cart: ${cartItem.bouquet.name}');
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(String uid, String bouquetId, int quantity) async {
    try {
      final cartRef = db.collection('users').doc(uid).collection('cart').doc(bouquetId);
      
      if (quantity <= 0) {
        await cartRef.delete();
        debugPrint('Item removed from cart: $bouquetId');
      } else {
        await cartRef.update({'quantity': quantity});
        debugPrint('Cart item quantity updated: $bouquetId = $quantity');
      }
    } catch (e) {
      debugPrint('Error updating cart item: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String uid, String bouquetId) async {
    try {
      await db.collection('users').doc(uid).collection('cart').doc(bouquetId).delete();
      debugPrint('Item removed from cart: $bouquetId');
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Stream<List<CartItem>> getCartItems(String uid) {
    return db.collection('users').doc(uid).collection('cart')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return CartItem.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint('Error parsing cart item ${doc.id}: $e');
              return null;
            }
          }).whereType<CartItem>().toList();
        })
        .handleError((error) {
          debugPrint('Error getting cart items: $error');
          return <CartItem>[];
        });
  }

  Future<void> clearCart(String uid) async {
    try {
      final cartSnapshot = await db.collection('users').doc(uid).collection('cart').get();
      final batch = db.batch();
      
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('Cart cleared for user: $uid');
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  Future<int> getCartItemCount(String uid) async {
    try {
      final snapshot = await db.collection('users').doc(uid).collection('cart').get();
      int totalCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalCount += (data['quantity'] as int? ?? 1);
      }
      
      return totalCount;
    } catch (e) {
      debugPrint('Error getting cart count: $e');
      return 0;
    }
  }

  Future<String> addAddress(String uid, Address address) async {
    try {
      final addressRef = db.collection('users').doc(uid).collection('addresses');
      
      if (address.isDefault) {
        await _unsetAllDefaultAddresses(uid);
      }
      
      final docRef = await addressRef.add(address.toMap());
      debugPrint('Address added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(String uid, String addressId, Address address) async {
    try {
      final addressRef = db.collection('users').doc(uid).collection('addresses').doc(addressId);
      
      if (address.isDefault) {
        await _unsetAllDefaultAddresses(uid, excludeId: addressId);
      }
      
      await addressRef.update(address.toMap());
      debugPrint('Address updated: $addressId');
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    try {
      await db.collection('users').doc(uid).collection('addresses').doc(addressId).delete();
      debugPrint('Address deleted: $addressId');
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String uid, String addressId) async {
    try {
      await _unsetAllDefaultAddresses(uid);
      
      await db.collection('users').doc(uid).collection('addresses').doc(addressId).update({
        'isDefault': true,
      });
      
      debugPrint('Default address set: $addressId');
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  Future<void> _unsetAllDefaultAddresses(String uid, {String? excludeId}) async {
    try {
      final snapshot = await db.collection('users').doc(uid).collection('addresses')
          .where('isDefault', isEqualTo: true)
          .get();
      
      final batch = db.batch();
      
      for (var doc in snapshot.docs) {
        if (excludeId != null && doc.id == excludeId) continue;
        batch.update(doc.reference, {'isDefault': false});
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error unsetting default addresses: $e');
    }
  }

  Stream<List<Address>> getAddresses(String uid) {
    return db.collection('users').doc(uid).collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Address.fromDoc(doc);
            } catch (e) {
              debugPrint('Error parsing address ${doc.id}: $e');
              return null;
            }
          }).whereType<Address>().toList();
        })
        .handleError((error) {
          debugPrint('Error getting addresses: $error');
          return <Address>[];
        });
  }

  Future<Address?> getDefaultAddress(String uid) async {
    try {
      final snapshot = await db.collection('users').doc(uid).collection('addresses')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {

        final allSnapshot = await db.collection('users').doc(uid).collection('addresses')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        if (allSnapshot.docs.isEmpty) return null;
        return Address.fromDoc(allSnapshot.docs.first);
      }
      
      return Address.fromDoc(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting default address: $e');
      return null;
    }
  }

  Future<Address?> getAddress(String uid, String addressId) async {
    try {
      final doc = await db.collection('users').doc(uid).collection('addresses').doc(addressId).get();
      
      if (!doc.exists) return null;
      
      return Address.fromDoc(doc);
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  Future<int> getAddressCount(String uid) async {
    try {
      final snapshot = await db.collection('users').doc(uid).collection('addresses').get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting addresses: $e');
      return 0;
    }
  }

  Future<String> createCustomOrder(CustomOrder order) async {
    try {
      final docRef = await db.collection('custom_orders').add(order.toMap());
      debugPrint('Custom order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating custom order: $e');
      rethrow;
    }
  }

  Stream<List<CustomOrder>> getBuyerCustomOrders(String uid) {
    return db.collection('custom_orders')
        .where('buyerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CustomOrder.fromDoc(doc)).toList())
        .handleError((error) {
          debugPrint('Error in getBuyerCustomOrders: $error');
          return <CustomOrder>[];
        });
  }

  Stream<List<CustomOrder>> getAllCustomOrders() {
    return db.collection('custom_orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CustomOrder.fromDoc(doc)).toList())
        .handleError((error) {
          debugPrint('Error in getAllCustomOrders: $error');
          return <CustomOrder>[];
        });
  }

  Future<void> updateCustomOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    int? finalPrice,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'status': status};
      
      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }
      
      if (finalPrice != null) {
        updateData['finalPrice'] = finalPrice;
      }
      
      await db.collection('custom_orders').doc(orderId).update(updateData);
      debugPrint('Custom order status updated: $orderId -> $status');
    } catch (e) {
      debugPrint('Error updating custom order status: $e');
      rethrow;
    }
  }
}