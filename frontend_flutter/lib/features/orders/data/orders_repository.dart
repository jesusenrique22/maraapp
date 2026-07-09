import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';
import '../../branches/domain/branch_models.dart';

class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<Order> checkout({
    required List<CheckoutItem> items,
    required FulfillmentType fulfillmentType,
    required String branchId,
    String? deliveryAddress,
    String? notes,
  }) async {
    final response = await _api.postMap('/orders', {
      'items': items
          .map((item) => {
                'productId': item.productId,
                'quantity': item.quantity,
              })
          .toList(),
      'branchId': branchId,
      'fulfillmentType': fulfillmentType.apiValue,
      if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
        'deliveryAddress': deliveryAddress.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    return Order.fromJson(response);
  }

  Future<List<Order>> fetchMyOrders() async {
    final data = await _api.getList('/orders/my');
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class CheckoutItem {
  const CheckoutItem({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;
}
