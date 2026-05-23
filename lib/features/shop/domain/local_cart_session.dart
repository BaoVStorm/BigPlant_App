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
      fee: 50000,
    );
  }

  static PaymentMethodOption defaultPaymentMethod() {
    return const PaymentMethodOption(
      title: 'Thanh toán khi nhận hàng (COD)',
      subtitle: 'Thanh toán tiền mặt cho shipper',
    );
  }

  static OrderBreakdown breakdownFor(List<CartLineItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineSubtotal);
    final shipping = 50000.0;
    final discount = items.length >= 2 ? 100000.0 : 0.0;
    return OrderBreakdown(
      subtotal: subtotal,
      shippingFee: shipping,
      discount: discount,
    );
  }
}
