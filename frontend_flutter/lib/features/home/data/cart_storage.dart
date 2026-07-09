import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/catalog_models.dart';

class CartStorage {
  static const _cartKey = 'maraplus_cart_v1';

  Future<void> save(List<CartItemSnapshot> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((item) => item.toJson()).toList();
    await prefs.setString(_cartKey, jsonEncode(encoded));
  }

  Future<List<CartItemSnapshot>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CartItemSnapshot.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}

class CartItemSnapshot {
  const CartItemSnapshot({
    required this.product,
    required this.quantity,
  });

  factory CartItemSnapshot.fromJson(Map<String, dynamic> json) {
    return CartItemSnapshot(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  final Product product;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };
}
