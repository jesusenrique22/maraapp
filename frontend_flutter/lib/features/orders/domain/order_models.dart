class OrderBranch {
  const OrderBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
  });

  factory OrderBranch.fromJson(Map<String, dynamic> json) {
    return OrderBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      phone: json['phone'] as String?,
    );
  }

  final String id;
  final String name;
  final String address;
  final String city;
  final String? phone;
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
    this.categorySlug,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      categorySlug: json['categorySlug'] as String?,
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? imageUrl;
  final String? categorySlug;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.items,
    this.fulfillmentType = 'DELIVERY',
    this.deliveryAddress,
    this.notes,
    this.branch,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      fulfillmentType: json['fulfillmentType'] as String? ?? 'DELIVERY',
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String?,
      notes: json['notes'] as String?,
      branch: json['branch'] == null
          ? null
          : OrderBranch.fromJson(json['branch'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final String fulfillmentType;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? deliveryAddress;
  final String? notes;
  final OrderBranch? branch;
  final DateTime createdAt;
  final List<OrderItem> items;

  bool get isPickup => fulfillmentType == 'PICKUP';

  String get fulfillmentLabel =>
      isPickup ? 'Retiro en sucursal' : 'Delivery';

  String get statusLabel => switch (status) {
        'PENDING' => 'Pendiente',
        'CONFIRMED' => 'Confirmado',
        'PROCESSING' => 'En preparación',
        'DELIVERED' => 'Entregado',
        'CANCELLED' => 'Cancelado',
        _ => status,
      };
}
