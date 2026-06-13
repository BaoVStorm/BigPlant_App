import 'shop_product.dart';

class CartLineItem {
  const CartLineItem({
    this.cartItemId,
    required this.product,
    required this.variant,
    required this.quantity,
  });

  /// Server-side cart_item _id. Null for locally-created items not yet synced.
  final String? cartItemId;
  final ShopProduct product;
  final ProductVariant variant;
  final int quantity;

  double get lineSubtotal => variant.price * quantity;
  double get lineCompareSubtotal => (variant.compareAtPrice ?? variant.price) * quantity;

  CartLineItem copyWith({
    String? cartItemId,
    ShopProduct? product,
    ProductVariant? variant,
    int? quantity,
  }) {
    return CartLineItem(
      cartItemId: cartItemId ?? this.cartItemId,
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CheckoutAddress {
  const CheckoutAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
  });

  final String fullName;
  final String phoneNumber;
  final String addressLine;
}

class DeliveryMethod {
  const DeliveryMethod({
    required this.title,
    required this.subtitle,
    required this.fee,
  });

  final String title;
  final String subtitle;
  final double fee;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class OrderBreakdown {
  const OrderBreakdown({
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
  });

  final double subtotal;
  final double shippingFee;
  final double discount;

  double get total {
    final effectiveDiscount = discount > subtotal ? subtotal : discount;
    return subtotal + shippingFee - effectiveDiscount;
  }
}
