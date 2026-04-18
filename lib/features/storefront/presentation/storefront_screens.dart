import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_web_stub.dart' if (dart.library.js) 'razorpay_web_impl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../auth/application/auth_provider.dart';
import '../../image_generation/data/generated_image_repository.dart';
import '../../image_generation/data/generated_image_storage.dart';
import '../data/ar_background_image_picker_stub.dart'
    if (dart.library.html) '../data/ar_background_image_picker_web.dart'
    as ar_bg_picker;
import '../../image_generation/domain/generated_image.dart';
import '../../modifications/data/modification_repository.dart';
import '../../modifications/domain/furniture_modification.dart';
import '../../orders/data/order_repository.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return Scaffold(
      appBar: const AppNavBar(title: 'Shop'),
      body: FutureBuilder<List<Product>>(
        future: repository.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load the collection',
                  message: '${snapshot.error}',
                  icon: Icons.wifi_off_rounded,
                ),
              ),
            );
          }

          final products = snapshot.data ?? <Product>[];
          final categories = <String>{
            'All',
            ...products.expand((product) => product.categories),
          }.toList();
          if (!categories.contains(selectedCategory)) {
            selectedCategory = 'All';
          }
          final filteredProducts = selectedCategory == 'All'
              ? products
              : products
                    .where(
                      (product) =>
                          product.categories.contains(selectedCategory),
                    )
                    .toList();

          return CustomScrollView(
            slivers: [
              // ── Category filter bar ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final selected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.burntSienna
                                  : AppTheme.parchment,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.richCharcoal,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Product grid ─────────────────────────────────────────
              if (filteredProducts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: AppMessagePanel(
                      title: 'No pieces in this collection yet',
                      message:
                          'Try another category to explore the current assortment.',
                      icon: Icons.search_off_rounded,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ProductCard(product: filteredProducts[index]),
                      childCount: filteredProducts.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.64,
                        ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/catalog/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image — fills all available space ──────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.imageUrlResolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.mutedClay.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.deepUmber,
                        ),
                      ),
                    ),
                    if (product.isOutOfStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Product info — fixed height, never overflows ────────
            SizedBox(
              height: 108,
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category + name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _categorySummary(product).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.burntSienna,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Price + Add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatCurrency(product.price),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: product.isOutOfStock
                                  ? AppTheme.mutedClay.withValues(alpha: 0.4)
                                  : AppTheme.burntSienna,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.isOutOfStock ? 'Sold' : 'Add',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return Scaffold(
      appBar: AppNavBar(title: 'Product details', showBackButton: true),
      body: FutureBuilder<Product?>(
        future: repository.getProductById(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load product: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Product not found',
                  message:
                      'The piece you selected may have been removed from the current collection.',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            );
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            child: AppPageWidth(
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;

                      final imagePanel = AppPanel(
                        padding: EdgeInsets.zero,
                        child: AspectRatio(
                          aspectRatio: isWide ? 0.9 : 1.1,
                          child: Hero(
                            tag: 'product-${product.id}',
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(product.imageUrlResolved),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      final detailPanel = AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _categorySummary(product).toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.burntSienna,
                                    letterSpacing: 1.8,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatCurrency(product.price),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontSize: 24,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.deepUmber),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: product.categories
                                  .map(
                                    (category) => Chip(label: Text(category)),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 28),
                            AppPanel(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  const Icon(Icons.texture_rounded),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Explore finishes up close, then move directly into AR placement when you are ready.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        context.push('/ar/${product.id}'),
                                    icon: const Icon(Icons.view_in_ar_outlined),
                                    label: const Text(
                                      'View in AR',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: product.isOutOfStock
                                        ? null
                                        : () async {
                                            await context
                                                .read<CartProvider>()
                                                .addItem(product);
                                            if (!context.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${product.name} added to your bag.',
                                                ),
                                                action: SnackBarAction(
                                                  label: 'View Bag',
                                                  onPressed: () =>
                                                      context.push('/cart'),
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.shopping_bag_outlined,
                                    ),
                                    label: Text(
                                      product.isOutOfStock
                                          ? 'Sold out'
                                          : 'Add to bag',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (product.modelUrlResolved.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => context.push(
                                    '/ar-scene?product=${product.id}',
                                  ),
                                  icon: const Icon(
                                    Icons.space_dashboard_outlined,
                                  ),
                                  label: const Text(
                                    'Add to AR Scene',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.burntSienna,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final cart = context.read<CartProvider>();
                                  await cart.addItem(product);
                                  if (context.mounted) {
                                    context.push('/cart');
                                  }
                                },
                                icon: const Icon(Icons.flash_on_rounded),
                                label: const Text(
                                  'Buy Now',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            imagePanel,
                            const SizedBox(height: 24),
                            detailPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: imagePanel),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: detailPanel),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Preset background options for the AR view (last is custom image).
const List<({String label, Color color})> _arBackgroundOptions = [
  (label: 'Warm', color: AppTheme.parchmentHighlight),
  (label: 'White', color: Colors.white),
  (label: 'Light gray', color: Color(0xFFE8E8E8)),
  (label: 'Soft cream', color: Color(0xFFF5F0E8)),
  (label: 'Cool gray', color: Color(0xFFE0E4E8)),
  (label: 'Dark', color: AppTheme.richCharcoal),
  (label: 'Image', color: Color(0xFF9E9E9E)),
];

const int _arImageBackgroundIndex = 6;

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  int _selectedBackgroundIndex = 0;
  bool _isMenuCollapsed = false;

  /// When using Image background, URL for skybox (upload or from generated images).
  String? _arBackgroundImageUrl;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return FutureBuilder<Product?>(
      future: repository.getProductById(widget.productId),
      builder: (context, snapshot) {
        final product = snapshot.data;

        return Scaffold(
          appBar: AppNavBar(
            title: product?.name ?? 'AR Preview',
            showBackButton: true,
            onBack: () => context.pop(),
          ),
          body: _buildArBody(context, snapshot, product),
        );
      },
    );
  }

  Future<void> _pickAndUploadArBackground() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to upload an image as background'),
        ),
      );
      return;
    }
    final picked = await ar_bg_picker.pickArBackgroundImage();
    if (picked == null || !mounted) return;
    try {
      final url = await uploadArBackgroundImage(
        auth.currentUser!.id,
        picked.bytes,
      );
      if (!mounted) return;
      setState(() {
        _arBackgroundImageUrl = url;
        _isMenuCollapsed = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _showGeneratedImagesSheet() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to choose from your generated images'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ArGeneratedImagesSheet(
        userId: auth.currentUser!.id,
        onSelect: (url) {
          setState(() {
            _arBackgroundImageUrl = url;
            _isMenuCollapsed = true;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Widget _buildArBody(
    BuildContext context,
    AsyncSnapshot<Product?> snapshot,
    Product? product,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Unable to load product: ${snapshot.error}'));
    }

    if (!snapshot.hasData) {
      return const Center(
        child: AppPageWidth(
          child: AppMessagePanel(
            title: 'AR preview unavailable',
            message:
                'This model is not ready right now. Please return to the collection and try another piece.',
            icon: Icons.view_in_ar_outlined,
          ),
        ),
      );
    }

    final currentProduct = product!;
    final modelSrc = currentProduct.modelUrlResolved;

    if (modelSrc.isEmpty) {
      return Center(
        child: AppPageWidth(
          child: AppMessagePanel(
            title: 'No 3D model',
            message:
                'This product does not have a 3D model yet. Add one in Admin → Products to view it in AR.',
            icon: Icons.view_in_ar_outlined,
          ),
        ),
      );
    }

    final selectedBg = _arBackgroundOptions[_selectedBackgroundIndex];
    final useImageBackground =
        _selectedBackgroundIndex == _arImageBackgroundIndex &&
        _arBackgroundImageUrl != null &&
        _arBackgroundImageUrl!.isNotEmpty;

    return Stack(
      children: [
        if (useImageBackground)
          Positioned.fill(
            child: Image.network(_arBackgroundImageUrl!, fit: BoxFit.cover),
          ),
        ModelViewer(
          backgroundColor: useImageBackground
              ? Colors.transparent
              : selectedBg.color,
          src: modelSrc,
          alt: 'A 3D model of ${currentProduct.name}',
          ar: true,
          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
        ),
        if (_isMenuCollapsed)
          Positioned(
            top: 24,
            right: 20,
            child: IconButton.filledTonal(
              onPressed: () => setState(() => _isMenuCollapsed = false),
              icon: const Icon(Icons.tune),
              tooltip: 'Background Settings',
            ),
          )
        else
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: AppPageWidth(
              padding: EdgeInsets.zero,
              child: AppPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!useImageBackground)
                          const Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.wb_incandescent_outlined),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Move around the room, then use your device AR support to place the piece at full scale.',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _isMenuCollapsed = true),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Icon(Icons.close, size: 20),
                          ),
                        ),
                      ],
                    ),
                    if (!useImageBackground) const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Background: ',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: List.generate(
                              _arBackgroundOptions.length,
                              (index) {
                                final option = _arBackgroundOptions[index];
                                final isSelected =
                                    index == _selectedBackgroundIndex;
                                final isImageOption =
                                    index == _arImageBackgroundIndex;
                                return Tooltip(
                                  message: option.label,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedBackgroundIndex = index,
                                    ),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: option.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : option.color ==
                                                    AppTheme.richCharcoal
                                              ? Colors.white24
                                              : Colors.black12,
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: isImageOption
                                          ? Icon(
                                              Icons.image_outlined,
                                              size: 16,
                                              color:
                                                  index ==
                                                      _arImageBackgroundIndex
                                                  ? Colors.white
                                                  : Colors.black87,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedBackgroundIndex ==
                        _arImageBackgroundIndex) ...[
                      const SizedBox(height: 12),
                      _ArImageBackgroundOptions(
                        currentImageUrl: _arBackgroundImageUrl,
                        isLoggedIn: context
                            .read<AuthProvider>()
                            .isAuthenticated,
                        onUploadNew: _pickAndUploadArBackground,
                        onChooseFromSaved: _showGeneratedImagesSheet,
                        onClear: () =>
                            setState(() => _arBackgroundImageUrl = null),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: AppPageWidth(
            padding: EdgeInsets.zero,
            child: AppPanel(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      currentProduct.imageUrlResolved,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentProduct.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(currentProduct.price),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await context.read<CartProvider>().addItem(
                        currentProduct,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      context.pop();
                      context.push('/cart');
                    },
                    child: const Text('Add to bag'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppNavBar(
        title: 'Product Summary',
        showBackButton: true,
        showCart: false,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Your bag is ready when you are',
                  message:
                      'Save pieces you love here, then return when you are ready to bring them home.',
                  icon: Icons.shopping_bag_outlined,
                  action: FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Browse collection'),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AppPageWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Delivery Address ──────────────────────────────
                      _SectionLabel(label: 'Delivery Address'),
                      const SizedBox(height: 12),
                      AppPanel(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.burntSienna.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: AppTheme.burntSienna,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home Delivery',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add your delivery address at checkout.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.deepUmber),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.deepUmber.withAlpha(120),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Cart Items + per-item Modification Chat ────────
                      _SectionLabel(
                        label:
                            '${cart.itemCount} Item${cart.itemCount == 1 ? '' : 's'} in your bag',
                      ),
                      const SizedBox(height: 12),
                      _CartItemsWithModifications(items: cart.items),

                      // ── Order Summary ─────────────────────────────────
                      _SectionLabel(label: 'Order Summary'),
                      const SizedBox(height: 12),
                      AppPanel(
                        child: Column(
                          children: [
                            for (final item in cart.items) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'x${item.quantity}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.deepUmber),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatCurrency(
                                      item.product.price * item.quantity,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (item != cart.items.last) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                              ],
                            ],
                            const Divider(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Products',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Text(
                                  formatCurrency(cart.totalAmount),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Shipping',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.deepUmber),
                                ),
                                const Spacer(),
                                Text(
                                  'Calculated at checkout',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.deepUmber),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Total incl. GST',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Text(
                                  formatCurrency(cart.totalAmount),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: () => context.push('/cart/checkout'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.burntSienna,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Proceed to Checkout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Modification Chat Banner ──────────────────────────────────────────────────
class _CartItemsWithModifications extends StatelessWidget {
  const _CartItemsWithModifications({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _CartItemPanel(item: item),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── Order Summary ─────────────────────────────────────────────────────────────

// ── Order Summary ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.richCharcoal,
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedPayment; // 'upi' | 'card' | 'cod'
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _placeOrder();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: AppTheme.burntSienna,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final orderRepository = context.read<OrderRepository>();

    try {
      final orderId = await orderRepository.checkoutActiveCart();
      await cart.refresh();
      if (!mounted) return;
      context.go('/cart/success/$orderId');
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      String userMessage = 'Unable to place order. Please try again.';

      if (message.contains('stock') || message.contains('left')) {
        userMessage =
            'Some items in your bag are no longer available in the requested quantity.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: AppTheme.burntSienna,
        ),
      );
    }
  }

  void _startRazorpayPayment() {
    final cart = context.read<CartProvider>();
    // Razorpay expects amount in subunits (paise for INR)
    final amountInPaise = (cart.totalAmount * 100).toInt();

    final options = {
      'key':
          'rzp_test_SbQicCgSXNsW5K', // USER: Replace with your actual Test Key from Razorpay Dashboard
      'amount': amountInPaise,
      'name': 'AR Interior Designer',
      'description': 'Modern Furniture Collection',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': '9876543210', 'email': 'customer@example.com'},
      'external': {
        'wallets': ['paytm'],
      },
    };

    if (kIsWeb) {
      openRazorpayWeb(
        options,
        (paymentId) {
          _handlePaymentSuccess(
            PaymentSuccessResponse(paymentId, null, null, null),
          );
        },
        (error) {
          debugPrint('Razorpay Web Error: $error');
          _handlePaymentError(PaymentFailureResponse(0, error, null));
        },
      );
    } else {
      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppNavBar(
          title: 'Checkout',
          showBackButton: true,
          onBack: () => context.go('/cart'),
          showCart: false,
        ),
        body: Center(
          child: AppPageWidth(
            child: AppMessagePanel(
              title: 'Your checkout is empty',
              message:
                  'Add a few pieces to your bag first, then return here to complete the order.',
              icon: Icons.shopping_cart_checkout_rounded,
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Browse collection'),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppNavBar(
        title: 'Checkout',
        showBackButton: true,
        onBack: () => context.go('/cart'),
        showCart: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Order Summary ─────────────────────────────────────
                _SectionLabel(label: 'Order Summary'),
                const SizedBox(height: 12),
                AppPanel(
                  child: Column(
                    children: [
                      for (final item in cart.items) ...[
                        _CheckoutLineItem(item: item),
                        if (item != cart.items.last) const Divider(height: 28),
                      ],
                      const Divider(height: 28),
                      Row(
                        children: [
                          Text(
                            'Subtotal',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            formatCurrency(cart.totalAmount),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Shipping',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.deepUmber),
                          ),
                          const Spacer(),
                          Text(
                            'Calculated at delivery',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.deepUmber),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Text(
                            'Total incl. GST',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            formatCurrency(cart.totalAmount),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Payment Method ────────────────────────────────────
                _SectionLabel(label: 'Payment Method'),
                const SizedBox(height: 12),
                AppPanel(
                  child: Column(
                    children: [
                      _PaymentOption(
                        value: 'upi',
                        groupValue: _selectedPayment,
                        icon: Icons.currency_rupee_rounded,
                        title: 'UPI',
                        subtitle: 'Pay via Google Pay, PhonePe, Paytm, etc.',
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                      const Divider(height: 24),
                      _PaymentOption(
                        value: 'card',
                        groupValue: _selectedPayment,
                        icon: Icons.credit_card_rounded,
                        title: 'Credit / Debit Card',
                        subtitle: 'Visa, Mastercard, Rupay, and more.',
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                      const Divider(height: 24),
                      _PaymentOption(
                        value: 'cod',
                        groupValue: _selectedPayment,
                        icon: Icons.local_shipping_outlined,
                        title: 'Cash on Delivery',
                        subtitle: 'Pay in cash when your order arrives.',
                        onChanged: (v) => setState(() => _selectedPayment = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Place Order Button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: (_selectedPayment == null || cart.isBusy)
                        ? null
                        : () {
                            if (_selectedPayment == 'cod') {
                              _placeOrder();
                            } else {
                              _startRazorpayPayment();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedPayment != null
                          ? AppTheme.burntSienna
                          : AppTheme.mutedClay,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      cart.isBusy
                          ? 'Placing order...'
                          : _selectedPayment == null
                          ? 'Select a payment method'
                          : (_selectedPayment == 'cod'
                                ? 'Place Order'
                                : 'Pay with Razorpay'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final String value;
  final String? groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.burntSienna.withAlpha(25)
                  : AppTheme.parchmentHighlight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.burntSienna : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.burntSienna : AppTheme.deepUmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.richCharcoal
                        : AppTheme.deepUmber,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.deepUmber),
                ),
              ],
            ),
          ),
          Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: AppTheme.burntSienna,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// _CatalogHero removed — shop now shows pure product grid.

class _CartItemPanel extends StatelessWidget {
  const _CartItemPanel({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return AppPanel(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item.product.imageUrlResolved,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categorySummary(item.product).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.burntSienna,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(item.product.price),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _QuantityButton(
                icon: Icons.add,
                onPressed: () {
                  if (item.quantity + 1 > item.product.stockQuantity) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Only ${item.product.stockQuantity} left in stock',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  cart.addItem(item.product);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _QuantityButton(
                icon: Icons.remove,
                onPressed: () => cart.removeSingleItem(item.product.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutLineItem extends StatelessWidget {
  const _CheckoutLineItem({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.product.price * item.quantity;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${item.quantity}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Text(
          formatCurrency(lineTotal),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _ArImageBackgroundOptions extends StatelessWidget {
  const _ArImageBackgroundOptions({
    required this.currentImageUrl,
    required this.isLoggedIn,
    required this.onUploadNew,
    required this.onChooseFromSaved,
    required this.onClear,
  });

  final String? currentImageUrl;
  final bool isLoggedIn;
  final VoidCallback onUploadNew;
  final VoidCallback onChooseFromSaved;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Sign in to upload an image or choose from your generated images.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    final hasImage = currentImageUrl != null && currentImageUrl!.isNotEmpty;

    if (hasImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear image'),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: onUploadNew,
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Upload new image'),
        ),
        FilledButton.tonalIcon(
          onPressed: onChooseFromSaved,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('From my images'),
        ),
      ],
    );
  }
}

class _ArGeneratedImagesSheet extends StatelessWidget {
  const _ArGeneratedImagesSheet({required this.userId, required this.onSelect});

  final String userId;
  final void Function(String url) onSelect;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GeneratedImageRepository>();
    return FutureBuilder<List<GeneratedImage>>(
      future: repo.getByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No generated images yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate images from the home page, then they will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Choose from your generated images',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final img = list[index];
                    final url = getGeneratedImageUrl(img.imagePath);
                    return GestureDetector(
                      onTap: () => onSelect(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// ---------------------------------------------------------------------------

String _categorySummary(Product product) {
  if (product.categories.isEmpty) {
    return 'Curated piece';
  }

  return product.categories.take(2).join(' · ');
}
