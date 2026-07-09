import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cart_storage.dart';
import '../domain/models/catalog_models.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._storage) : super([]) {
    _restore();
  }

  final CartStorage _storage;

  Future<void> _restore() async {
    final snapshots = await _storage.read();
    if (snapshots.isEmpty) return;
    state = snapshots
        .map((item) => CartItem(product: item.product, quantity: item.quantity))
        .toList();
  }

  Future<void> _persist() async {
    await _storage.save(
      state
          .map(
            (item) => CartItemSnapshot(
              product: item.product,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );
  }

  /// Returns an error message when the product cannot be added.
  String? addProduct(Product product, {int amount = 1}) {
    if (!product.inStock || product.stock <= 0) {
      return '${product.name} está agotado';
    }

    final idx = state.indexWhere((item) => item.product.id == product.id);
    final currentQty = idx == -1 ? 0 : state[idx].quantity;
    final nextQty = currentQty + amount;

    if (nextQty > product.stock) {
      return 'Solo hay ${product.stock} disponibles de ${product.name}';
    }

    if (idx != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx)
            CartItem(product: state[i].product, quantity: nextQty)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: amount)];
    }

    _persist();
    return null;
  }

  void removeProduct(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
    _persist();
  }

  String? decreaseQuantity(Product product) {
    final idx = state.indexWhere((item) => item.product.id == product.id);
    if (idx == -1) return null;

    if (state[idx].quantity > 1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx)
            CartItem(
              product: state[i].product,
              quantity: state[i].quantity - 1,
            )
          else
            state[i],
      ];
      _persist();
      return null;
    }

    removeProduct(product);
    return null;
  }

  Future<void> clear() async {
    state = [];
    await _storage.clear();
  }

  /// Updates cart items with branch-specific stock after switching sucursal.
  void syncStockFromCatalog(List<Product> products) {
    if (state.isEmpty) return;

    final productMap = {for (final product in products) product.id: product};
    final updated = <CartItem>[];

    for (final item in state) {
      final product = productMap[item.product.id];
      if (product == null) {
        updated.add(item);
        continue;
      }

      if (!product.inStock || product.stock <= 0) continue;

      final quantity = item.quantity > product.stock ? product.stock : item.quantity;
      updated.add(CartItem(product: product, quantity: quantity));
    }

    if (updated.length != state.length ||
        updated.any(
          (item) {
            final previous = state.firstWhere(
              (current) => current.product.id == item.product.id,
              orElse: () => item,
            );
            return previous.quantity != item.quantity ||
                previous.product.stock != item.product.stock;
          },
        )) {
      state = updated;
      _persist();
    }
  }

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice {
    double total = 0;
    for (final item in state) {
      total += item.product.finalPrice * item.quantity;
    }
    return total;
  }

  double get deliveryFee => totalPrice > 20 ? 0 : 2;

  double get grandTotal => totalPrice + deliveryFee;
}

final cartStorageProvider = Provider<CartStorage>((ref) => CartStorage());

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref.watch(cartStorageProvider));
});