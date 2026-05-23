import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../auth/data/storage_service.dart';
import '../../domain/local_cart_session.dart';
import '../../domain/models/cart_checkout.dart';
import 'order_summary_screen.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  late List<CartLineItem> _items;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _items = LocalCartSession.initialItems();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final fullName = (await StorageService.getFullName())?.trim() ?? '';
    if (!mounted) return;
    setState(() => _fullName = fullName);
  }

  void _updateQuantity(int index, int delta) {
    final current = _items[index];
    final nextQuantity = current.quantity + delta;

    setState(() {
      if (nextQuantity <= 0) {
        _items.removeAt(index);
        return;
      }
      _items[index] = current.copyWith(quantity: nextQuantity);
    });
  }

  OrderBreakdown get _breakdown => LocalCartSession.breakdownFor(_items);

  String _formatCurrency(double value) {
    final text = value.toStringAsFixed(0);
    final chars = text.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(chars[i]);
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  void _openCheckout() {
    if (_items.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          items: List<CartLineItem>.from(_items),
          address: LocalCartSession.defaultAddress(),
          deliveryMethod: LocalCartSession.defaultDeliveryMethod(),
          paymentMethod: LocalCartSession.defaultPaymentMethod(),
          breakdown: _breakdown,
        ),
      ),
    );
  }

  String get _displayName {
    final trimmed = _fullName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'BigPlant';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Text(
              t.t('cart_title'),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t
                  .t('cart_selected_items')
                  .replaceFirst('{count}', '${_items.length}')
                  .replaceFirst('{name}', _displayName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_items.isEmpty)
              _EmptyCartCard(
                title: t.t('cart_empty_title'),
                body: t.t('cart_empty_body'),
              )
            else ...[
              for (var i = 0; i < _items.length; i++) ...[
                _CartItemCard(
                  item: _items[i],
                  priceFormatter: _formatCurrency,
                  onIncrease: () => _updateQuantity(i, 1),
                  onDecrease: () => _updateQuantity(i, -1),
                ),
                if (i != _items.length - 1) const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: t.t('order_subtotal_label'),
                      value: _formatCurrency(_breakdown.subtotal),
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: t.t('order_shipping_fee_label'),
                      value: _formatCurrency(_breakdown.shippingFee),
                    ),
                    if (_breakdown.discount > 0) ...[
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: t.t('order_discount_label'),
                        value: '-${_formatCurrency(_breakdown.discount)}',
                        highlight: true,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(
                      height: 1,
                      color: AppColors.surfaceContainerHigh,
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      label: t.t('order_total_label'),
                      value: _formatCurrency(_breakdown.total),
                      total: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.t('checkout_now')),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCartCard extends StatelessWidget {
  const _EmptyCartCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.priceFormatter,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartLineItem item;
  final String Function(double value) priceFormatter;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantLabel = item.variant.potStyle.isEmpty
        ? item.variant.sizeLabel
        : '${item.variant.sizeLabel}, ${item.variant.potStyle}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              imageUrl: item.product.primaryImage.imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  variantLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (item.variant.compareAtPrice != null)
                  Text(
                    priceFormatter(item.variant.compareAtPrice!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  priceFormatter(item.variant.price),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: onDecrease,
                          ),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          _QuantityButton(icon: Icons.add, onTap: onIncrease),
                        ],
                      ),
                    ),
                    Text(
                      priceFormatter(item.lineSubtotal),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.blackLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.total = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final labelStyle = total
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.blackLight,
            fontSize: 20,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight
                ? AppColors.secondary
                : AppColors.onSurfaceVariant,
          );
    final valueStyle = total
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 24,
          )
        : Theme.of(context).textTheme.labelLarge?.copyWith(
            color: highlight ? AppColors.secondary : AppColors.onSurface,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: labelStyle), Text(value, style: valueStyle)],
    );
  }
}
