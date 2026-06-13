import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/data/storage_service.dart';
import '../../../scan/presentation/screens/camera_realtime_scan_screen.dart';
import '../../domain/models/shop_product.dart';
import '../../domain/shop_service.dart';
import 'edit_user_screen.dart';
import 'product_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _pageSize = 8;
  static const _searchDebounce = Duration(milliseconds: 350);

  final ShopService _shopService = ShopService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategorySlug = 'all';
  String _searchQuery = '';
  int _currentPage = 0;
  String _fullName = '';
  String? _photoUrl;
  bool _loadingProducts = true;
  bool _loadingCategories = true;
  String? _loadError;
  List<ProductCategory> _categories = const [];
  List<ShopProduct> _pageItems = const [];
  int _totalPages = 1;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final fullName = (await StorageService.getFullName())?.trim() ?? '';
    final photoUrl = (await StorageService.getPhotoUrl())?.trim() ?? '';
    if (!mounted) return;
    setState(() {
      _fullName = fullName;
      _photoUrl = photoUrl.isNotEmpty ? photoUrl : null;
    });
  }

  Future<void> _openEditProfile() async {
    final userName = (await StorageService.getUserName())?.trim() ?? '';
    final fullName = (await StorageService.getFullName())?.trim() ?? '';
    final email = (await StorageService.getEmail())?.trim() ?? '';
    final phoneNumber = (await StorageService.getPhoneNumber())?.trim() ?? '';
    final dateOfBirth = (await StorageService.getDateOfBirth())?.trim() ?? '';
    final gender = (await StorageService.getGender())?.trim() ?? '';
    final photoUrl = (await StorageService.getPhotoUrl())?.trim() ?? '';
    
    if (!mounted) return;
    
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditUserScreen(
          userName: userName,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          dateOfBirth: dateOfBirth,
          gender: gender,
          photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
        ),
      ),
    );
    
    if (updated == true) {
      _loadProfile();
    }
  }

  void _showMessage(String message) {
    AppToast.showError(context, message);
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCategories = true;
      _loadError = null;
    });

    try {
      final categories = await _shopService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _loadingProducts = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadProducts({
    String? categorySlug,
    String? query,
    int? page,
  }) async {
    final nextCategory = categorySlug ?? _selectedCategorySlug;
    final nextQuery = query ?? _searchQuery;
    final nextPage = page ?? _currentPage;

    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });

    try {
      final result = await _shopService.fetchProducts(
        categorySlug: nextCategory == 'all' ? null : nextCategory,
        query: nextQuery,
        page: nextPage + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _selectedCategorySlug = nextCategory;
        _searchQuery = nextQuery;
        _currentPage = result.page - 1;
        _pageItems = result.items;
        _totalPages = result.totalPages;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _loadError = e.toString();
      });
    }
  }

  void _selectCategory(String slug) {
    _loadProducts(categorySlug: slug, page: 0);
  }

  void _handleSearchChanged(String value) {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      _loadProducts(query: value.trim(), page: 0);
    });
  }

  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _loadProducts(query: '', page: 0);
  }

  void _changePage(int page) {
    if (page < 0 || page >= _totalPages || _loadingProducts) return;
    _loadProducts(page: page);
  }

  String get _headlineName {
    return AppLocalizations.of(context).t('home_greeting_friend');
  }

  String get _avatarInitial {
    if (_fullName.trim().isNotEmpty) {
      return _fullName.trim().substring(0, 1).toUpperCase();
    }
    return _headlineName.substring(0, 1).toUpperCase();
  }

  String _categoryLabel(AppLocalizations t, ProductCategory category) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final categoryOptions = [
      _HomeCategoryOption(slug: 'all', label: t.t('category_all')),
      for (final category in _categories)
        _HomeCategoryOption(
          slug: category.slug,
          label: _categoryLabel(t, category),
        ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _showMessage(t.t('home_menu_coming_soon')),
                  icon: const Icon(Icons.menu, color: AppColors.primary),
                ),
                Expanded(
                  child: Text(
                    t.t('home_brand_title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                      fontSize: 24,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _openEditProfile,
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('home_greeting_prefix'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _headlineName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.blackLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.secondaryContainer,
                        AppColors.primaryFixed,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: ClipOval(
                    child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? AppNetworkImage(
                          imageUrl: _photoUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          _avatarInitial,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 24,
                          ),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: _handleSearchChanged,
                      onSubmitted: (value) {
                        _searchDebounceTimer?.cancel();
                        _loadProducts(query: value.trim(), page: 0);
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: t.t('home_search_hint'),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon:
                            _searchQuery.isNotEmpty ||
                                _searchController.text.trim().isNotEmpty
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CameraRealtimeScanScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.center_focus_strong,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: _loadingCategories
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryOptions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = categoryOptions[index];
                        final selected = option.slug == _selectedCategorySlug;
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.secondaryContainer,
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: selected
                                ? AppColors.onSecondaryContainer
                                : AppColors.onSurfaceVariant,
                          ),
                          onSelected: (_) => _selectCategory(option.slug),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _searchQuery.isEmpty
                        ? t.t('popular_plants')
                        : 'Results for "$_searchQuery"',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.blackLight,
                      fontSize: 24,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _totalPages > 1
                      ? () => _changePage((_currentPage + 1) % _totalPages)
                      : null,
                  label: Text(t.t('home_view_all')),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadError != null) ...[
              _HomeMessageCard(message: _loadError!, icon: Icons.error_outline),
              const SizedBox(height: 24),
            ] else if (_loadingProducts && _pageItems.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
            ] else if (_pageItems.isEmpty) ...[
              _HomeMessageCard(
                message: _searchQuery.isEmpty
                    ? 'No products available for this category yet.'
                    : 'No products found for "$_searchQuery".',
                icon: _searchQuery.isEmpty
                    ? Icons.inventory_2_outlined
                    : Icons.search_off_outlined,
              ),
              const SizedBox(height: 24),
            ] else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pageItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.55,
                ),
                itemBuilder: (context, index) {
                  final product = _pageItems[index];
                  final category = product.category;
                  return _ProductCard(
                    product: product,
                    categoryLabel: category == null
                        ? ''
                        : _categoryLabel(t, category),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    ),
                    onAdd: () async {
                      try {
                        await _shopService.addToCart(
                          variantId: product.defaultVariant.id.toString(),
                        );
                        if (!mounted) return;
                        AppToast.showSuccess(
                          context,
                          t
                              .t('product_added_to_cart')
                              .replaceFirst('{name}', product.name),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        _showMessage('Failed to add to cart: $e');
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_totalPages > 1)
                _PaginationRow(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageSelected: _changePage,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeCategoryOption {
  const _HomeCategoryOption({required this.slug, required this.label});

  final String slug;
  final String label;
}

class _HomeMessageCard extends StatelessWidget {
  const _HomeMessageCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryLabel,
    required this.onTap,
    required this.onAdd,
  });

  final ShopProduct product;
  final String categoryLabel;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variant = product.defaultVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
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
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AppNetworkImage(
                    imageUrl: product.primaryImage.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.ratingAvg.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categoryLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.blackLight,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${variant.price.toStringAsFixed(2)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  List<_PaginationEntry> _buildEntries() {
    if (totalPages <= 5) {
      return List<_PaginationEntry>.generate(
        totalPages,
        (index) => _PaginationEntry.page(index),
      );
    }

    final entries = <_PaginationEntry>[];

    void addPage(int page) {
      if (entries.any((entry) => entry.page == page)) return;
      entries.add(_PaginationEntry.page(page));
    }

    void addGap() {
      if (entries.isEmpty || entries.last.isEllipsis) return;
      entries.add(const _PaginationEntry.ellipsis());
    }

    if (currentPage == 0) {
      addPage(0);
      addPage(1);
      addPage(2);
      addGap();
      addPage(totalPages - 1);
      return entries;
    }

    if (currentPage == 1) {
      addPage(0);
      addPage(1);
      addPage(2);
      addGap();
      addPage(totalPages - 1);
      return entries;
    }

    if (currentPage == 2) {
      addPage(0);
      addPage(1);
      addPage(2);
      addPage(3);
      addGap();
      addPage(totalPages - 1);
      return entries;
    }

    if (currentPage == totalPages - 3) {
      addPage(0);
      addGap();
      addPage(totalPages - 4);
      addPage(totalPages - 3);
      addPage(totalPages - 2);
      addPage(totalPages - 1);
      return entries;
    }

    if (currentPage == totalPages - 2) {
      addPage(0);
      addGap();
      addPage(totalPages - 3);
      addPage(totalPages - 2);
      addPage(totalPages - 1);
      return entries;
    }

    if (currentPage == totalPages - 1) {
      addPage(0);
      addGap();
      addPage(totalPages - 2);
      addPage(totalPages - 1);
      return entries;
    }

    addPage(0);
    addGap();
    addPage(currentPage - 1);
    addPage(currentPage);
    addPage(currentPage + 1);
    addGap();
    addPage(totalPages - 1);
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageArrow(
          icon: Icons.chevron_left,
          enabled: currentPage > 0,
          onTap: () => onPageSelected(currentPage - 1),
        ),
        const SizedBox(width: 8),
        for (final entry in entries) ...[
          if (entry.isEllipsis)
            Text(
              '...',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            _PageChip(
              label: '${entry.page! + 1}',
              selected: entry.page == currentPage,
              onTap: () => onPageSelected(entry.page!),
            ),
          const SizedBox(width: 8),
        ],
        _PageArrow(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages - 1,
          onTap: () => onPageSelected(currentPage + 1),
        ),
      ],
    );
  }
}

class _PaginationEntry {
  const _PaginationEntry.page(this.page) : isEllipsis = false;
  const _PaginationEntry.ellipsis() : page = null, isEllipsis = true;

  final int? page;
  final bool isEllipsis;
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Icon(
        icon,
        color: enabled ? AppColors.primary : AppColors.outlineVariant,
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
