class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
}

class AdminSession {
  const AdminSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AdminUser user;
}

class AdminStats {
  const AdminStats({
    required this.products,
    required this.categories,
    required this.banners,
    required this.doctors,
    required this.patients,
    required this.apiOnline,
  });

  final int products;
  final int categories;
  final int banners;
  final int doctors;
  final int patients;
  final bool apiOnline;
}

class AdminSalesDashboard {
  const AdminSalesDashboard({
    required this.periodDays,
    required this.from,
    required this.catalog,
    required this.kpis,
    required this.salesByDay,
    required this.byStatus,
    required this.byFulfillment,
    required this.byBranch,
    required this.topProducts,
    required this.lowStock,
    required this.funnel,
    required this.insights,
  });

  factory AdminSalesDashboard.fromJson(Map<String, dynamic> json) {
    return AdminSalesDashboard(
      periodDays: (json['periodDays'] as num?)?.toInt() ?? 30,
      from: json['from'] as String? ?? '',
      catalog: AdminSalesCatalog.fromJson(
        json['catalog'] as Map<String, dynamic>? ?? const {},
      ),
      kpis: AdminSalesKpis.fromJson(
        json['kpis'] as Map<String, dynamic>? ?? const {},
      ),
      salesByDay: ((json['salesByDay'] as List<dynamic>?) ?? [])
          .map((e) => AdminSalesDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      byStatus: ((json['byStatus'] as List<dynamic>?) ?? [])
          .map((e) => AdminStatusCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      byFulfillment: ((json['byFulfillment'] as List<dynamic>?) ?? [])
          .map((e) => AdminFulfillmentCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      byBranch: ((json['byBranch'] as List<dynamic>?) ?? [])
          .map((e) => AdminBranchSales.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: ((json['topProducts'] as List<dynamic>?) ?? [])
          .map((e) => AdminTopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowStock: ((json['lowStock'] as List<dynamic>?) ?? [])
          .map((e) => AdminLowStockProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      funnel: AdminSalesFunnel.fromJson(
        json['funnel'] as Map<String, dynamic>? ?? const {},
      ),
      insights: ((json['insights'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final int periodDays;
  final String from;
  final AdminSalesCatalog catalog;
  final AdminSalesKpis kpis;
  final List<AdminSalesDay> salesByDay;
  final List<AdminStatusCount> byStatus;
  final List<AdminFulfillmentCount> byFulfillment;
  final List<AdminBranchSales> byBranch;
  final List<AdminTopProduct> topProducts;
  final List<AdminLowStockProduct> lowStock;
  final AdminSalesFunnel funnel;
  final List<String> insights;
}

class AdminSalesCatalog {
  const AdminSalesCatalog({
    required this.products,
    required this.banners,
    required this.doctors,
    required this.patients,
    required this.branches,
  });

  factory AdminSalesCatalog.fromJson(Map<String, dynamic> json) {
    return AdminSalesCatalog(
      products: (json['products'] as num?)?.toInt() ?? 0,
      banners: (json['banners'] as num?)?.toInt() ?? 0,
      doctors: (json['doctors'] as num?)?.toInt() ?? 0,
      patients: (json['patients'] as num?)?.toInt() ?? 0,
      branches: (json['branches'] as num?)?.toInt() ?? 0,
    );
  }

  final int products;
  final int banners;
  final int doctors;
  final int patients;
  final int branches;
}

class AdminSalesKpis {
  const AdminSalesKpis({
    required this.revenue,
    required this.orders,
    required this.averageTicket,
    required this.cancelRate,
    required this.revenueDeltaPct,
  });

  factory AdminSalesKpis.fromJson(Map<String, dynamic> json) {
    return AdminSalesKpis(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      averageTicket: (json['averageTicket'] as num?)?.toDouble() ?? 0,
      cancelRate: (json['cancelRate'] as num?)?.toDouble() ?? 0,
      revenueDeltaPct: (json['revenueDeltaPct'] as num?)?.toDouble() ?? 0,
    );
  }

  final double revenue;
  final int orders;
  final double averageTicket;
  final double cancelRate;
  final double revenueDeltaPct;
}

class AdminSalesDay {
  const AdminSalesDay({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory AdminSalesDay.fromJson(Map<String, dynamic> json) {
    return AdminSalesDay(
      date: json['date'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  final String date;
  final double revenue;
  final int orders;
}

class AdminStatusCount {
  const AdminStatusCount({required this.status, required this.count});

  factory AdminStatusCount.fromJson(Map<String, dynamic> json) {
    return AdminStatusCount(
      status: json['status'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String status;
  final int count;
}

class AdminFulfillmentCount {
  const AdminFulfillmentCount({required this.type, required this.count});

  factory AdminFulfillmentCount.fromJson(Map<String, dynamic> json) {
    return AdminFulfillmentCount(
      type: json['type'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String type;
  final int count;
}

class AdminBranchSales {
  const AdminBranchSales({
    required this.name,
    required this.revenue,
    required this.orders,
  });

  factory AdminBranchSales.fromJson(Map<String, dynamic> json) {
    return AdminBranchSales(
      name: json['name'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  final String name;
  final double revenue;
  final int orders;
}

class AdminTopProduct {
  const AdminTopProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.unitsSold,
    required this.revenue,
  });

  factory AdminTopProduct.fromJson(Map<String, dynamic> json) {
    return AdminTopProduct(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  final String productId;
  final String name;
  final String sku;
  final int unitsSold;
  final double revenue;
}

class AdminLowStockProduct {
  const AdminLowStockProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.stock,
  });

  factory AdminLowStockProduct.fromJson(Map<String, dynamic> json) {
    return AdminLowStockProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String sku;
  final int stock;
}

class AdminSalesFunnel {
  const AdminSalesFunnel({
    required this.catalogProducts,
    required this.customers,
    required this.ordersCreated,
    required this.ordersSold,
    required this.delivered,
    required this.cancelled,
  });

  factory AdminSalesFunnel.fromJson(Map<String, dynamic> json) {
    return AdminSalesFunnel(
      catalogProducts: (json['catalogProducts'] as num?)?.toInt() ?? 0,
      customers: (json['customers'] as num?)?.toInt() ?? 0,
      ordersCreated: (json['ordersCreated'] as num?)?.toInt() ?? 0,
      ordersSold: (json['ordersSold'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
    );
  }

  final int catalogProducts;
  final int customers;
  final int ordersCreated;
  final int ordersSold;
  final int delivered;
  final int cancelled;
}

class CreateProductInput {
  const CreateProductInput({
    required this.sku,
    required this.name,
    required this.price,
    required this.categoryId,
    this.description,
    this.imageUrl,
    this.initialStock,
    this.discountPercent,
    this.isFeatured = false,
  });

  final String sku;
  final String name;
  final String? description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final int? initialStock;
  final int? discountPercent;
  final bool isFeatured;

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'price': price,
      'categoryId': categoryId,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (initialStock != null) 'initialStock': initialStock,
      if (discountPercent != null) 'discountPercent': discountPercent,
      'isFeatured': isFeatured,
    };
  }
}

class UpdateProductInput {
  const UpdateProductInput({
    this.name,
    this.description,
    this.price,
    this.categoryId,
    this.imageUrl,
    this.discountPercent,
    this.isFeatured,
    this.isActive,
  });

  final String? name;
  final String? description;
  final double? price;
  final String? categoryId;
  final String? imageUrl;
  final int? discountPercent;
  final bool? isFeatured;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (categoryId != null) 'categoryId': categoryId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isActive != null) 'isActive': isActive,
    };
  }
}

class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.backgroundColor = '#1B3A8A',
    this.textColor = '#FFFFFF',
    this.badgeText,
    this.buttonText,
    this.linkUrl,
    this.placement = 'HOME_HERO',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory AdminBanner.fromJson(Map<String, dynamic> json) {
    return AdminBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String,
      backgroundColor: json['backgroundColor'] as String? ?? '#1B3A8A',
      textColor: json['textColor'] as String? ?? '#FFFFFF',
      badgeText: json['badgeText'] as String?,
      buttonText: json['buttonText'] as String?,
      linkUrl: json['linkUrl'] as String?,
      placement: json['placement'] as String? ?? 'HOME_HERO',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String backgroundColor;
  final String textColor;
  final String? badgeText;
  final String? buttonText;
  final String? linkUrl;
  final String placement;
  final int sortOrder;
  final bool isActive;
}

class CreateBannerInput {
  const CreateBannerInput({
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.backgroundColor,
    this.textColor,
    this.badgeText,
    this.buttonText,
    this.linkUrl,
    this.placement,
    this.sortOrder,
  });

  final String title;
  final String imageUrl;
  final String? subtitle;
  final String? backgroundColor;
  final String? textColor;
  final String? badgeText;
  final String? buttonText;
  final String? linkUrl;
  final String? placement;
  final int? sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      if (subtitle != null && subtitle!.isNotEmpty) 'subtitle': subtitle,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
      if (badgeText != null && badgeText!.isNotEmpty) 'badgeText': badgeText,
      if (buttonText != null && buttonText!.isNotEmpty) 'buttonText': buttonText,
      if (linkUrl != null && linkUrl!.isNotEmpty) 'linkUrl': linkUrl,
      if (placement != null) 'placement': placement,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}

class UpdateBannerInput {
  const UpdateBannerInput({
    this.title,
    this.subtitle,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
    this.badgeText,
    this.buttonText,
    this.linkUrl,
    this.placement,
    this.sortOrder,
    this.isActive,
  });

  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? backgroundColor;
  final String? textColor;
  final String? badgeText;
  final String? buttonText;
  final String? linkUrl;
  final String? placement;
  final int? sortOrder;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle!.isEmpty ? null : subtitle,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
      if (badgeText != null) 'badgeText': badgeText!.isEmpty ? null : badgeText,
      if (buttonText != null) 'buttonText': buttonText!.isEmpty ? null : buttonText,
      if (linkUrl != null) 'linkUrl': linkUrl!.isEmpty ? null : linkUrl,
      if (placement != null) 'placement': placement,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (isActive != null) 'isActive': isActive,
    };
  }
}
