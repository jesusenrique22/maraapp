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
