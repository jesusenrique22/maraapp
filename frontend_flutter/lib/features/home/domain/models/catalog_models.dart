class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? description;
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
    required this.textColor,
    required this.placement,
    this.subtitle,
    this.badgeText,
    this.buttonText,
    this.linkUrl,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String,
      backgroundColor: json['backgroundColor'] as String? ?? '#1B3A8A',
      textColor: json['textColor'] as String? ?? '#FFFFFF',
      badgeText: json['badgeText'] as String?,
      buttonText: json['buttonText'] as String?,
      linkUrl: json['linkUrl'] as String?,
      placement: json['placement'] as String,
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

  bool get isHero => placement == 'HOME_HERO';
  bool get isStrip => placement == 'HOME_STRIP';
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.finalPrice,
    required this.stock,
    required this.inStock,
    required this.category,
    this.description,
    this.imageUrl,
    this.discountPercent,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      discountPercent: json['discountPercent'] as int?,
      stock: (json['stock'] as num).toInt(),
      inStock: json['inStock'] as bool,
      imageUrl: json['imageUrl'] as String?,
      category: ProductCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'description': description,
        'price': price,
        'finalPrice': finalPrice,
        'discountPercent': discountPercent,
        'stock': stock,
        'inStock': inStock,
        'imageUrl': imageUrl,
        'category': category.toJson(),
      };

  final String id;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final double finalPrice;
  final int? discountPercent;
  final int stock;
  final bool inStock;
  final String? imageUrl;
  final ProductCategory category;

  bool get hasDiscount =>
      discountPercent != null && discountPercent! > 0 && finalPrice < price;
}

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };

  final String id;
  final String name;
  final String slug;
}
