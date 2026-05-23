import 'shop_product.dart';

class CartLineItem {
  const CartLineItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final ShopProduct product;
  final ProductVariant variant;
  final int quantity;

  double get lineSubtotal => variant.price * quantity;
  double get lineCompareSubtotal => (variant.compareAtPrice ?? variant.price) * quantity;

  CartLineItem copyWith({
    ShopProduct? product,
    ProductVariant? variant,
    int? quantity,
  }) {
    return CartLineItem(
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

  double get total => subtotal + shippingFee - discount;
}
