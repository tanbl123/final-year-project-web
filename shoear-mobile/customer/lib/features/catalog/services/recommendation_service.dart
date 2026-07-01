import 'package:customer/core/api/api_client.dart';
import 'package:customer/features/catalog/models/product.dart';

/// Recommendation calls. These hit the PHP proxy, which in turn runs the Python
/// weighted-hybrid ML service (SVD + TF-IDF) and returns product cards — so the
/// results parse into the same [ProductSummary] used across the catalog.
class RecommendationService {
  final ApiClient api;
  RecommendationService(this.api);

  List<ProductSummary> _parse(dynamic data) {
    final raw = (data is Map<String, dynamic>) ? (data['items'] as List?) ?? const [] : const [];
    return raw.map((e) => ProductSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /catalog/products/{id}/similar — "You may also like" (content-based).
  Future<List<ProductSummary>> similar(String productId) async =>
      _parse(await api.get('/catalog/products/$productId/similar'));

  /// GET /recommendations/for-you — personalized weighted hybrid (needs login).
  Future<List<ProductSummary>> forYou() async =>
      _parse(await api.get('/recommendations/for-you'));

  /// GET /recommendations/trending — best-sellers (public).
  Future<List<ProductSummary>> trending() async =>
      _parse(await api.get('/recommendations/trending'));
}
