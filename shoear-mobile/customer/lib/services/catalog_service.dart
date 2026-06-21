import '../api/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Public catalog browsing (no token required).
class CatalogService {
  final ApiClient api;
  CatalogService(this.api);

  /// GET /catalog/products — approved products with optional search/filters.
  /// [sort] is one of: price_asc, price_desc, newest.
  Future<CatalogPage> listProducts({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (categoryId != null && categoryId.isNotEmpty) query['categoryId'] = categoryId;
    if (minPrice != null) query['minPrice'] = minPrice.toString();
    if (maxPrice != null) query['maxPrice'] = maxPrice.toString();
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    final data = await api.get('/catalog/products', query: query);
    return CatalogPage.fromJson(data as Map<String, dynamic>);
  }

  /// GET /catalog/products/{id} — full detail of one approved product.
  Future<ProductDetail> getProduct(String id) async {
    final data = await api.get('/catalog/products/$id');
    return ProductDetail.fromJson(data as Map<String, dynamic>);
  }

  /// GET /categories — public category list (for the filter dropdown).
  Future<List<Category>> listCategories() async {
    final data = await api.get('/categories');
    return ((data as List?) ?? []).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}
