import 'dart:async';

import '../../../core/network/api_client.dart';
import '../data/shop_api.dart';
import 'models/cart_checkout.dart';
import 'models/shop_product.dart';

class ShopService {
  ShopService({ShopApi? api}) : _api = api ?? ShopApi(ApiClient());

  final ShopApi _api;
  static final StreamController<void> cartUpdates = StreamController<void>.broadcast();

  // ── Product / Category ─────────────────────────────────────────────────

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await _api.fetchCategories();
    final data = _toMap(response['data']);
    final rawItems = data['categories'];
    if (rawItems is! List) return const <ProductCategory>[];
    return rawItems
        .whereType<Map>()
        .map((item) => ProductCategory.fromApi(_toMap(item)))
        .toList(growable: false);
  }

  Future<ShopCatalogPage> fetchProducts({
    String? categorySlug,
    String? query,
    required int page,
    required int limit,
  }) async {
    final response = await _api.fetchProducts(
      categorySlug: categorySlug,
      query: query,
      page: page,
      limit: limit,
    );
    return ShopCatalogPage.fromApi(response);
  }

  Future<ShopProduct> fetchProductDetail(String slug) async {
    final response = await _api.fetchProductDetail(slug);
    final data = _toMap(response['data']);
    return ShopProduct.fromApi(_toMap(data['product']));
  }

  // ── Cart ────────────────────────────────────────────────────────────────

  /// Fetches the active cart with all items hydrated with full product data.
  Future<CartData> fetchCart() async {
    final response = await _api.getCart();
    final data = _toMap(response['data']);
    final cartJson = _toMap(data['cart']);
    final itemsJson = data['items'];

    final items = <CartLineItem>[];

    if (itemsJson is List) {
      for (final raw in itemsJson) {
        final itemMap = _toMap(raw);
        final productMap = _toMap(itemMap['product']);
        if (productMap.isEmpty) continue;

        final product = ShopProduct.fromApi(productMap);
        final variantId = _asString(itemMap['variant_id']);

        // Find the matching variant from the hydrated product
        ProductVariant? variant;
        for (final v in product.variants) {
          if (v.id.toString() == variantId) {
            variant = v;
            break;
          }
        }
        variant ??= product.defaultVariant;

        items.add(CartLineItem(
          cartItemId: _asString(itemMap['id']),
          product: product,
          variant: variant,
          quantity: _asInt(itemMap['quantity'], fallback: 1),
        ));
      }
    }

    return CartData(
      cartId: _asString(cartJson['id']),
      status: _asString(cartJson['status']),
      subtotalAmount: _asDouble(cartJson['subtotal_amount']),
      discountAmount: _asDouble(cartJson['discount_amount']),
      shippingAmount: _asDouble(cartJson['shipping_amount']),
      totalAmount: _asDouble(cartJson['total_amount']),
      items: items,
    );
  }

  Future<void> addToCart({
    required String variantId,
    int quantity = 1,
  }) async {
    await _api.addCartItem(variantId: variantId, quantity: quantity);
    cartUpdates.add(null);
  }

  Future<void> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    await _api.updateCartItem(itemId: itemId, quantity: quantity);
    cartUpdates.add(null);
  }

  Future<void> removeCartItem(String itemId) async {
    await _api.removeCartItem(itemId);
    cartUpdates.add(null);
  }

  Future<void> clearCart() async {
    await _api.clearCart();
    cartUpdates.add(null);
  }
}

/// Holds the parsed cart response from the server.
class CartData {
  const CartData({
    required this.cartId,
    required this.status,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.shippingAmount,
    required this.totalAmount,
    required this.items,
  });

  final String cartId;
  final String status;
  final double subtotalAmount;
  final double discountAmount;
  final double shippingAmount;
  final double totalAmount;
  final List<CartLineItem> items;

  OrderBreakdown get breakdown => OrderBreakdown(
        subtotal: subtotalAmount,
        shippingFee: shippingAmount,
        discount: discountAmount,
      );
}

// ── helpers ──────────────────────────────────────────────────────────────

Map<String, dynamic> _toMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _asString(dynamic raw) {
  if (raw == null) return '';
  return raw.toString().trim();
}

int _asInt(dynamic raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(_asString(raw)) ?? fallback;
}

double _asDouble(dynamic raw, {double fallback = 0}) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  return double.tryParse(_asString(raw)) ?? fallback;
}
