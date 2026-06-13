import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/storage_service.dart';

class ShopApi {
  ShopApi(this._client);

  final ApiClient _client;

  // ── Product / Category (public) ────────────────────────────────────────

  Future<Map<String, dynamic>> fetchCategories() {
    return _client.get(_buildUrl('api/shop/categories'));
  }

  Future<Map<String, dynamic>> fetchProducts({
    String? categorySlug,
    String? query,
    required int page,
    required int limit,
  }) {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (categorySlug != null && categorySlug.trim().isNotEmpty)
        'category': categorySlug.trim(),
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    };
    return _client.get(_buildUrl('api/shop/products', queryParameters: params));
  }

  Future<Map<String, dynamic>> fetchProductDetail(String slug) {
    return _client.get(_buildUrl('api/shop/products/${slug.trim()}'));
  }

  // ── Cart (authenticated) ───────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getCart() async {
    final headers = await _authHeaders();
    return _client.get(
      _buildUrl('api/shop/cart'),
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> addCartItem({
    required String variantId,
    int quantity = 1,
  }) async {
    final headers = await _authHeaders();
    return _client.post(
      _buildUrl('api/shop/cart/items'),
      headers: headers,
      body: {
        'variant_id': variantId,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final headers = await _authHeaders();
    return _client.put(
      _buildUrl('api/shop/cart/items/$itemId'),
      headers: headers,
      body: {'quantity': quantity},
    );
  }

  Future<Map<String, dynamic>> removeCartItem(String itemId) async {
    final headers = await _authHeaders();
    return _client.delete(
      _buildUrl('api/shop/cart/items/$itemId'),
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> clearCart() async {
    final headers = await _authHeaders();
    return _client.delete(
      _buildUrl('api/shop/cart'),
      headers: headers,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────

  String _buildUrl(String path, {Map<String, String>? queryParameters}) {
    final base = ApiConstants.baseUrl;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final uri = Uri.parse('$normalizedBase$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri.toString();
    }
    return uri.replace(queryParameters: queryParameters).toString();
  }
}
