import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/cart_checkout.dart';
import 'payment_success_screen.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({
    required this.items,
    required this.address,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.breakdown,
    super.key,
  });

  final List<CartLineItem> items;
  final CheckoutAddress address;
  final DeliveryMethod deliveryMethod;
  final PaymentMethodOption paymentMethod;
  final OrderBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: Text(
          t.t('home_brand_title'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            t.t('order_summary_title'),
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            t.t('order_summary_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _SummaryCard(
            icon: Icons.location_on,
            title: t.t('order_shipping_address_title'),
            child: Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.fullName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.blackLight,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phoneNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.addressLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.shopping_bag,
            title: t.t('order_products_title'),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _OrderItemRow(item: items[i]),
                  if (i != items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: AppColors.surfaceContainerHighest),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.local_shipping,
            title: t.t('order_delivery_title'),
            child: _InfoTile(
              title: deliveryMethod.title,
              subtitle: deliveryMethod.subtitle,
              trailing: _formatCurrency(deliveryMethod.fee),
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.payments,
            title: t.t('order_payment_title'),
            child: _InfoTile(
              leadingIcon: Icons.account_balance_wallet,
              title: paymentMethod.title,
              subtitle: paymentMethod.subtitle,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                _MoneyRow(label: t.t('order_subtotal_label'), value: _formatCurrency(breakdown.subtotal)),
                const SizedBox(height: 10),
                _MoneyRow(label: t.t('order_shipping_fee_label'), value: _formatCurrency(breakdown.shippingFee)),
                const SizedBox(height: 10),
                _MoneyRow(
                  label: t.t('order_discount_label'),
                  value: '-${_formatCurrency(breakdown.discount)}',
                  highlight: true,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.surfaceContainerHighest),
                const SizedBox(height: 16),
                _MoneyRow(
                  label: t.t('order_total_label'),
                  value: _formatCurrency(breakdown.total),
                  total: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentSuccessScreen(orderCode: '#BP-88294'),
                ),
              );
            },
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
                Text(t.t('order_confirm_payment')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CartLineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            item.product.primaryImage.imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: theme.textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.variant.sizeLabel}${item.variant.potStyle.isNotEmpty ? ', ${item.variant.potStyle}' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(item.variant.price),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'x${item.quantity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: AppColors.secondary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
            ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
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
    final color = total
        ? AppColors.primary
        : highlight
            ? AppColors.secondary
            : AppColors.onSurface;
    final labelStyle = total
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.blackLight,
            fontSize: 20,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight ? AppColors.secondary : AppColors.onSurfaceVariant,
          );
    final valueStyle = total
        ? Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 24,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: labelStyle), Text(value, style: valueStyle)],
    );
  }
}
