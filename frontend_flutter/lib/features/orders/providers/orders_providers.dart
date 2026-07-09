import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../admin/providers/admin_providers.dart';
import '../data/orders_repository.dart';
import '../domain/order_models.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final auth = ref.watch(adminAuthProvider);
  if (!auth.isAuthenticated || auth.session?.user.role != 'CUSTOMER') {
    return [];
  }
  return ref.watch(ordersRepositoryProvider).fetchMyOrders();
});
