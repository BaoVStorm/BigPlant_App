import 'local_shop_catalog.dart';
import 'models/cart_checkout.dart';

class LocalCartSession {
  static List<CartLineItem> initialItems() {
    final monstera = LocalShopCatalog.bySlug('monstera-deliciosa');
    final fiddle = LocalShopCatalog.bySlug('fiddle-leaf-fig');

    return [
      CartLineItem(
        product: monstera,
        variant: monstera.resolveVariant(
          sizeLabel: 'Small',
          potStyle: 'Terracotta',
        ),
        quantity: 1,
      ),
      CartLineItem(
        product: fiddle,
        variant: fiddle.defaultVariant,
        quantity: 1,
      ),
    ];
  }

  static CheckoutAddress defaultAddress() {
    return const CheckoutAddress(
      fullName: 'Nguyễn Văn A',
      phoneNumber: '090 123 4567',
      addressLine:
          '123 Đường Cây Xanh, Phường Quang Hợp, Quận Sinh Thái, TP. Hồ Chí Minh',
    );
  }

  static DeliveryMethod defaultDeliveryMethod() {
    return const DeliveryMethod(
      title: 'Giao hàng tiêu chuẩn',
      subtitle: 'Dự kiến giao: 2-3 ngày',
      fee: 1,
    );
  }

  static PaymentMethodOption defaultPaymentMethod() {
    return const PaymentMethodOption(
      title: 'Thanh toán khi nhận hàng (COD)',
      subtitle: 'Thanh toán tiền mặt cho shipper',
    );
  }

  static OrderBreakdown breakdownFor(List<CartLineItem> items) {
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.lineSubtotal);
    final compareTotal = items.fold<double>(0.0, (sum, item) => sum + item.lineCompareSubtotal);
    final originalDiscount = compareTotal > subtotal ? compareTotal - subtotal : 0.0;
    
    final shipping = 1.0;
    final discount = 0.0; // Do not mock discount locally
    final total = subtotal + shipping - discount;

    return OrderBreakdown(
      subtotal: subtotal,
      shippingFee: shipping,
      originalDiscount: originalDiscount,
      discount: discount,
      total: total > 0 ? total : 0.0,
    );
  }
}
