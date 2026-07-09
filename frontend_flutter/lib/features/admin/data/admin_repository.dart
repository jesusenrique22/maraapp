import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../home/domain/models/catalog_models.dart';
import '../domain/admin_models.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<AdminSession> login(String email, String password) async {
    final response = await _api.postMap('/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    return _parseSession(response);
  }

  Future<AdminSession> register(String email, String password, String name) async {
    final response = await _api.postMap('/auth/register', {
      'email': email.trim().toLowerCase(),
      'password': password,
      'name': name.trim(),
    });

    return _parseSession(response);
  }

  AdminSession _parseSession(Map<String, dynamic> response) {
    final token = response['accessToken'];
    final userJson = response['user'];

    if (token is! String || token.isEmpty) {
      throw ApiException('Respuesta de autenticación inválida');
    }
    if (userJson is! Map<String, dynamic>) {
      throw ApiException('Respuesta de autenticación inválida');
    }

    return AdminSession(
      token: token,
      user: AdminUser.fromJson(userJson),
    );
  }

  Future<AdminUser> me() async {
    final response = await _api.getMap('/auth/me');
    return AdminUser.fromJson(response);
  }

  Future<AdminStats> fetchStats() async {
    try {
      await _api.getMap('/health');
      final products = await _api.getList('/admin/products');
      final categories = await _api.getList('/admin/categories');
      final banners = await _api.getList('/admin/banners');
      final doctors = await _api.getList('/consultations/admin/doctors');
      final patients = await _api.getList('/consultations/admin/patients');

      return AdminStats(
        products: products.length,
        categories: categories.length,
        banners: banners.length,
        doctors: doctors.length,
        patients: patients.length,
        apiOnline: true,
      );
    } catch (_) {
      return const AdminStats(
        products: 0,
        categories: 0,
        banners: 0,
        doctors: 0,
        patients: 0,
        apiOnline: false,
      );
    }
  }

  Future<List<Product>> fetchProducts() async {
    final data = await _api.getList('/admin/products');
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final data = await _api.getList('/admin/categories');
    return data
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(CreateProductInput input) async {
    final response = await _api.postMap('/admin/products', input.toJson());
    return Product.fromJson(response);
  }

  Future<Product> updateProduct(String id, UpdateProductInput input) async {
    final response = await _api.patchMap('/admin/products/$id', input.toJson());
    return Product.fromJson(response);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/admin/products/$id');
  }

  Future<String> uploadProductImage({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final response = await _api.uploadImage(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType,
    );
    return response['imageUrl'] as String;
  }

  Future<List<AdminBanner>> fetchBanners() async {
    final data = await _api.getList('/admin/banners');
    return data
        .map((item) => AdminBanner.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBanner> createBanner(CreateBannerInput input) async {
    final response = await _api.postMap('/admin/banners', input.toJson());
    return AdminBanner.fromJson(response);
  }

  Future<AdminBanner> updateBanner(String id, UpdateBannerInput input) async {
    final response = await _api.patchMap('/admin/banners/$id', input.toJson());
    return AdminBanner.fromJson(response);
  }

  Future<void> deleteBanner(String id) async {
    await _api.delete('/admin/banners/$id');
  }

  Future<List<Map<String, dynamic>>> fetchAdminDoctors() async {
    final list = await _api.getList('/consultations/admin/doctors');
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAdminDoctor({
    required String email,
    required String name,
    required String specialty,
    required double fee,
    String? bio,
  }) async {
    return await _api.postMap('/consultations/admin/doctors', {
      'email': email.trim(),
      'name': name.trim(),
      'specialty': specialty.trim(),
      'fee': fee,
      if (bio != null) 'bio': bio.trim(),
    });
  }

  Future<Map<String, dynamic>> updateAdminDoctor(
    String id, {
    String? name,
    String? specialty,
    String? bio,
    double? fee,
    bool? isActive,
  }) async {
    return await _api.patchMap('/consultations/admin/doctors/$id', {
      if (name != null) 'name': name.trim(),
      if (specialty != null) 'specialty': specialty.trim(),
      if (bio != null) 'bio': bio.trim(),
      if (fee != null) 'fee': fee,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<void> deleteAdminDoctor(String id) async {
    await _api.delete('/consultations/admin/doctors/$id');
  }

  Future<List<Map<String, dynamic>>> fetchAdminPatients() async {
    final list = await _api.getList('/consultations/admin/patients');
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> deleteAdminPatient(String id) async {
    await _api.delete('/consultations/admin/patients/$id');
  }
}
