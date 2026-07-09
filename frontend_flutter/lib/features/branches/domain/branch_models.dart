class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.slug,
    required this.address,
    required this.city,
    this.state,
    this.phone,
    this.whatsapp,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.isMain = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      openingHours: json['openingHours'] as String?,
      isMain: json['isMain'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String slug;
  final String address;
  final String city;
  final String? state;
  final String? phone;
  final String? whatsapp;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final bool isMain;
  final bool isActive;
  final int sortOrder;

  String get fullAddress {
    final parts = [address, city, if (state != null) state].whereType<String>();
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'address': address,
        'city': city,
        'state': state,
        'phone': phone,
        'whatsapp': whatsapp,
        'latitude': latitude,
        'longitude': longitude,
        'openingHours': openingHours,
        'isMain': isMain,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}

enum FulfillmentType { delivery, pickup }

extension FulfillmentTypeApi on FulfillmentType {
  String get apiValue => switch (this) {
        FulfillmentType.delivery => 'DELIVERY',
        FulfillmentType.pickup => 'PICKUP',
      };
}
