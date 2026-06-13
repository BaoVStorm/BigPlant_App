import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/models/shop_product.dart';
import '../../domain/shop_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.product, super.key});

  final ShopProduct product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ShopService _shopService = ShopService();

  int _selectedImageIndex = 0;
  String _selectedSizeLabel = '';
  String _selectedPotStyle = '';
  var _selectedSection = _ProductDetailSection.description;
  bool _loadingDetails = false;
  String? _detailError;
  ShopProduct? _resolvedProduct;
  bool _addingToCart = false;

  ShopProduct get _product => _resolvedProduct ?? widget.product;

  @override
  void initState() {
    super.initState();
    _syncSelections(_product);
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _loadingDetails = true;
      _detailError = null;
    });

    try {
      final product = await _shopService.fetchProductDetail(_product.slug);
      if (!mounted) return;
      setState(() {
        _resolvedProduct = product;
        _loadingDetails = false;
      });
      _syncSelections(product);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _detailError = e.toString();
      });
    }
  }

  void _syncSelections(ShopProduct product) {
    final sizeOptions = product.sizeVariants;
    final potStyles = product.potStyles;
    final currentSize = _selectedSizeLabel;
    final currentPotStyle = _selectedPotStyle;

    _selectedSizeLabel =
        sizeOptions.any((item) => item.sizeLabel == currentSize)
        ? currentSize
        : sizeOptions.first.sizeLabel;
    _selectedPotStyle = potStyles.contains(currentPotStyle)
        ? currentPotStyle
        : (potStyles.isNotEmpty
              ? potStyles.first
              : product.defaultVariant.potStyle);
    if (_selectedImageIndex >= product.sortedImages.length) {
      _selectedImageIndex = 0;
    }
  }

  ProductVariant get _selectedVariant => _product.resolveVariant(
    sizeLabel: _selectedSizeLabel,
    potStyle: _selectedPotStyle,
  );

  ProductImage get _selectedImage {
    final images = _product.sortedImages;
    if (_selectedImageIndex >= images.length) return images.first;
    return images[_selectedImageIndex];
  }

  void _showActionMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleAddToCart() async {
    if (_addingToCart) return;
    final t = AppLocalizations.of(context);
    setState(() => _addingToCart = true);
    try {
      await _shopService.addToCart(
        variantId: _selectedVariant.id.toString(),
      );
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        t.t('product_added_to_cart').replaceFirst('{name}', _product.name),
      );
    } catch (e) {
      if (!mounted) return;
      _showActionMessage('Failed to add to cart: $e');
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  String _storyHeadline(AppLocalizations t) {
    final commonName = _product.linkedPlant?.commonName.trim() ?? '';
    if (commonName.isNotEmpty) return commonName;
    return _product.name;
  }

  String _localizedCategoryLabel(AppLocalizations t) {
    final category = _product.category;
    if (category == null) return '';
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    switch (category.slug) {
      case 'plants':
        return isVietnamese ? 'Cay' : 'Plants';
      case 'pots':
        return isVietnamese ? 'Chau' : 'Pots';
      default:
        return category.name;
    }
  }

  Color _potStyleColor(String style) {
    switch (style.toLowerCase()) {
      case 'white ceramic':
        return const Color(0xFFF4F4F4);
      case 'terracotta':
        return const Color(0xFFCD9A5B);
      case 'charcoal':
        return const Color(0xFF2C3E50);
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plant = _product.linkedPlant;
    final variant = _selectedVariant;
    final specChips = <Widget>[
      if (variant.waterNeed.trim().isNotEmpty)
        _SpecChip(icon: Icons.water_drop, label: variant.waterNeed),
      if (variant.lightNeed.trim().isNotEmpty)
        _SpecChip(icon: Icons.light_mode, label: variant.lightNeed),
      if (_product.careLevel.trim().isNotEmpty)
        _SpecChip(
          icon: Icons.psychology,
          label: _product.careLevel,
          outlined: true,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          t.t('home_brand_title'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                _showActionMessage(t.t('product_account_coming_soon')),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          if (_loadingDetails)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_detailError != null) ...[
            _DetailInfoBanner(message: _detailError!, icon: Icons.info_outline),
            const SizedBox(height: 16),
          ],
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                t.t('home_tab'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.outline,
              ),
              Text(
                _localizedCategoryLabel(t),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.outline,
              ),
              Text(
                _product.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                  imageUrl: _selectedImage.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _product.sortedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final image = _product.sortedImages[index];
                final selected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppNetworkImage(
                        imageUrl: image.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizedCategoryLabel(t),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'SKU: ${_product.sku}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _product.name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ..._buildRatingStars(_product.ratingAvg),
              const SizedBox(width: 8),
              Text(
                '${_product.ratingAvg.toStringAsFixed(1)} (${_product.ratingCount} ${t.t('product_reviews_label')})',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${variant.price.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: 12),
              if (variant.compareAtPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '\$${variant.compareAtPrice!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _product.shortDescription.trim().isEmpty
                ? _product.description
                : _product.shortDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (specChips.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: specChips),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceContainerHighest),
          const SizedBox(height: 20),
          Text(
            t.t('product_select_size'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.blackLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _product.sizeVariants.map((option) {
              final selected = option.sizeLabel == _selectedSizeLabel;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedSizeLabel = option.sizeLabel),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            option.sizeLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                          ),
                          if (option.sizeSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              option.sizeSubtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_product.potStyles.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              t.t('product_pot_style'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.blackLight,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _product.potStyles.map((style) {
                final selected = style == _selectedPotStyle;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPotStyle = style),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _potStyleColor(style),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addingToCart ? null : _handleAddToCart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _addingToCart
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.shopping_bag),
                  label: Text(t.t('product_add_to_cart')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showActionMessage(t.t('product_buy_now_coming_soon')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(t.t('product_buy_now')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('product_shipping_title'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.blackLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.t('product_shipping_eta'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SectionTabs(
            selected: _selectedSection,
            onSelected: (section) => setState(() => _selectedSection = section),
          ),
          const SizedBox(height: 24),
          if (_selectedSection == _ProductDetailSection.description)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _storyHeadline(t),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.blackLight,
                    fontSize: 28,
                  ),
                ),
                if ((plant?.description.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  Text(
                    plant!.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.7,
                    ),
                  ),
                ],
                if (_product.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.7,
                    ),
                  ),
                ],
              ],
            )
          else if (_selectedSection == _ProductDetailSection.care)
            Column(
              children: [
                if (variant.waterNeed.trim().isNotEmpty) ...[
                  _CareDetailCard(
                    icon: Icons.water_drop,
                    title: t.t('product_care_water'),
                    value: variant.waterNeed,
                  ),
                  const SizedBox(height: 12),
                ],
                if (variant.lightNeed.trim().isNotEmpty) ...[
                  _CareDetailCard(
                    icon: Icons.light_mode,
                    title: t.t('product_care_light'),
                    value: variant.lightNeed,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_product.careLevel.trim().isNotEmpty)
                  _CareDetailCard(
                    icon: Icons.psychology,
                    title: t.t('product_care_level'),
                    value: _product.careLevel,
                  ),
                if (variant.waterNeed.trim().isEmpty &&
                    variant.lightNeed.trim().isEmpty &&
                    _product.careLevel.trim().isEmpty)
                  const _DetailInfoBanner(
                    message:
                        'Care instructions are not available for this product yet.',
                    icon: Icons.spa_outlined,
                  ),
              ],
            )
          else if (plant != null)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FactCard(
                        icon: Icons.science,
                        label: t.t('field_scientific_name'),
                        value: plant.scientificName,
                        italic: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FactCard(
                        icon: Icons.account_tree,
                        label: t.t('field_family'),
                        value: plant.family,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FactBanner(
                  label: t.t('product_toxicity_label'),
                  value: plant.toxicityWarning,
                ),
              ],
            )
          else
            const _DetailInfoBanner(
              message:
                  'Botanical details are not available for this product yet.',
              icon: Icons.eco_outlined,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRatingStars(double rating) {
    return List<Widget>.generate(5, (index) {
      final position = index + 1;
      IconData icon;
      Color color;

      if (rating >= position) {
        icon = Icons.star;
        color = const Color(0xFFF59E0B);
      } else if (rating >= position - 0.5) {
        icon = Icons.star_half;
        color = const Color(0xFFF59E0B);
      } else {
        icon = Icons.star_border;
        color = AppColors.outlineVariant;
      }

      return Icon(icon, color: color, size: 18);
    });
  }
}

enum _ProductDetailSection { description, care, botanical }

class _DetailInfoBanner extends StatelessWidget {
  const _DetailInfoBanner({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.icon,
    required this.label,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: outlined
            ? AppColors.surfaceContainerHighest
            : AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: AppColors.outlineVariant) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: outlined
                ? AppColors.onSurfaceVariant
                : AppColors.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: outlined
                  ? AppColors.onSurfaceVariant
                  : AppColors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.selected, required this.onSelected});

  final _ProductDetailSection selected;
  final ValueChanged<_ProductDetailSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tabs = <MapEntry<_ProductDetailSection, String>>[
      MapEntry(
        _ProductDetailSection.description,
        t.t('product_tab_description'),
      ),
      MapEntry(_ProductDetailSection.care, t.t('product_tab_care')),
      MapEntry(_ProductDetailSection.botanical, t.t('product_tab_botanical')),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = selected == tab.key;
          return GestureDetector(
            onTap: () => onSelected(tab.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab.value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CareDetailCard extends StatelessWidget {
  const _CareDetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.blackLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
    this.italic = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
          Icon(icon, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.blackLight,
              fontSize: 22,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactBanner extends StatelessWidget {
  const _FactBanner({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.blackLight,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.warning, color: AppColors.error, size: 28),
        ],
      ),
    );
  }
}
