import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../branches/providers/branches_provider.dart';
import '../domain/models/catalog_models.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> fetchCategories() async {
    final data = await _api.getList('/categories');
    return data
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromoBanner>> fetchBanners({String? placement}) async {
    final data = await _api.getList(
      '/banners',
      query: placement == null ? null : {'placement': placement},
    );
    return data
        .map((item) => PromoBanner.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts({
    String? categorySlug,
    String? search,
    String? branchId,
  }) async {
    final query = <String, String>{};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    if (branchId != null && branchId.isNotEmpty) {
      query['branchId'] = branchId;
    }

    final data = await _api.getList('/products', query: query.isEmpty ? null : query);
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchHomeProducts({String? branchId}) async {
    final data = await _api.getList(
      '/products/home/list',
      query: branchId == null ? null : {'branchId': branchId},
    );
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchFeatured({String? branchId}) async {
    final data = await _api.getList(
      '/products/featured/list',
      query: branchId == null ? null : {'branchId': branchId},
    );
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

String? _resolveBranchId(Ref ref) {
  final selected = ref.watch(selectedBranchProvider)?.id;
  if (selected != null) return selected;

  final branches = ref.watch(branchesProvider).valueOrNull;
  if (branches == null || branches.isEmpty) return null;

  final main = branches.where((branch) => branch.isMain);
  if (main.isNotEmpty) return main.first.id;
  return branches.first.id;
}

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchCategories();
});

final heroBannersProvider = FutureProvider<List<PromoBanner>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchBanners(placement: 'HOME_HERO');
});

final stripBannersProvider = FutureProvider<List<PromoBanner>>((ref) {
  return ref.watch(catalogRepositoryProvider).fetchBanners(placement: 'HOME_STRIP');
});

final homeProductsProvider = FutureProvider<List<Product>>((ref) {
  final branchId = _resolveBranchId(ref);
  return ref.watch(catalogRepositoryProvider).fetchHomeProducts(branchId: branchId);
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  final branchId = _resolveBranchId(ref);
  return ref.watch(catalogRepositoryProvider).fetchFeatured(branchId: branchId);
});

final productsProvider =
    FutureProvider.family<List<Product>, ProductQuery>((ref, query) {
  final branchId = _resolveBranchId(ref);
  return ref.watch(catalogRepositoryProvider).fetchProducts(
        categorySlug: query.categorySlug,
        search: query.search,
        branchId: branchId,
      );
});

class ProductQuery {
  const ProductQuery({this.categorySlug, this.search});

  final String? categorySlug;
  final String? search;

  bool get isFiltered =>
      (categorySlug != null && categorySlug!.isNotEmpty) ||
      (search != null && search!.isNotEmpty);

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        other.categorySlug == categorySlug &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(categorySlug, search);
}
