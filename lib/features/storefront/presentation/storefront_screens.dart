import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../auth/application/auth_provider.dart';
import '../../image_generation/data/generated_image_repository.dart';
import '../../image_generation/data/generated_image_storage.dart';
import '../../image_generation/data/nvidia_nim_image_repository.dart';
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
    final generatedImageRepository =
        context.read<GeneratedImageRepository>();

    return Scaffold(
      appBar: const AppNavBar(),
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
          final heroProduct = filteredProducts.isNotEmpty
              ? filteredProducts.first
              : (products.isNotEmpty ? products.first : null);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppPageWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CatalogHero(product: heroProduct),
                      const SizedBox(height: 28),
                      _GenerateImageSection(
                        generatedImageRepository: generatedImageRepository,
                      ),
                      const SizedBox(height: 28),
                      AppSectionHeader(
                        eyebrow: 'Curated collection',
                        title: 'Explore signature pieces',
                        subtitle:
                            'Browse refined silhouettes by category and move from discovery to AR preview without losing the calm, showroom feel.',
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return ChoiceChip(
                              label: Text(categories[index]),
                              selected: selectedCategory == categories[index],
                              onSelected: (_) {
                                setState(
                                  () => selectedCategory = categories[index],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (filteredProducts.isEmpty)
                        const AppMessagePanel(
                          title: 'No pieces in this collection yet',
                          message:
                              'Try another category to explore the current assortment.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1040
                                ? 3
                                : width >= 680
                                ? 2
                                : 1;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 24,
                                    crossAxisSpacing: 24,
                                    childAspectRatio: crossAxisCount == 1
                                        ? 1.02
                                        : 0.76,
                                  ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: filteredProducts[index],
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.mutedClay.withValues(alpha: 0.2),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrlResolved),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categorySummary(product),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.burntSienna,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.deepUmber,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(product.price),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_outward_rounded, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateImageSection extends StatefulWidget {
  const _GenerateImageSection({
    required this.generatedImageRepository,
  });

  final GeneratedImageRepository generatedImageRepository;

  @override
  State<_GenerateImageSection> createState() => _GenerateImageSectionState();
}

class _GenerateImageSectionState extends State<_GenerateImageSection> {
  final _promptController = TextEditingController();
  final _repository = NvidiaNimImageRepository();

  static const _apiKey =
      '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';
  static const _proxyUrl = 'http://localhost:8080/generate_image';

  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? _imageBytes;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _imageBytes = null;
    });
    final result = await _repository.generateImage(
      apiKey: _apiKey,
      prompt: _promptController.text,
      proxyUrl: _proxyUrl,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _imageBytes = result.imageBytes != null
          ? Uint8List.fromList(result.imageBytes!)
          : null;
      _error = result.error;
    });
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null || _imageBytes == null || _imageBytes!.isEmpty) return;

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final imagePath = await saveGeneratedImageToStorage(
        userId,
        _imageBytes!,
      );
      await widget.generatedImageRepository.insert(
            userId: userId,
            prompt: prompt,
            imagePath: imagePath,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to your history')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            eyebrow: 'AI',
            title: 'Generate image from prompt',
            subtitle: 'Describe the image you want. Sign in to generate and save.',
          ),
          if (!auth.isAuthenticated) ...[
            const SizedBox(height: 20),
            AppMessagePanel(
              title: 'Sign in to generate images',
              message: 'Generate and save images are available when you sign in.',
              icon: Icons.login,
              action: TextButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Sign in'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'e.g. A cozy living room',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(_isLoading ? 'Generating…' : 'Generate image'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AppMessagePanel(
                title: 'Generation failed',
                message: _error!,
                icon: Icons.error_outline_rounded,
              ),
            ],
            if (_imageBytes != null && _imageBytes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_isSaving ? 'Saving…' : 'Save to my history'),
              ),
            ],
          ],
        ],
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
      appBar: AppNavBar(
        title: 'Product details',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
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
              child: LayoutBuilder(
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
                          _formatCurrency(product.price),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
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
                              .map((category) => Chip(label: Text(category)))
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                                    context.go('/ar/${product.id}'),
                                icon: const Icon(Icons.view_in_ar_outlined),
                                label: const Text('View in AR'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await context.read<CartProvider>().addItem(
                                    product,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} added to your bag.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.shopping_bag_outlined),
                                label: const Text('Add to bag'),
                              ),
                            ),
                          ],
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
            ),
          );
        },
      ),
    );
  }
}

class ARViewScreen extends StatelessWidget {
  const ARViewScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return FutureBuilder<Product?>(
      future: repository.getProductById(productId),
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

    return Stack(
      children: [
        ModelViewer(
          backgroundColor: AppTheme.parchmentHighlight,
          src: currentProduct.modelUrlResolved,
          alt: 'A 3D model of ${currentProduct.name}',
          ar: true,
          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
        ),
        Positioned(
          top: 24,
          left: 20,
          right: 20,
          child: AppPageWidth(
            padding: EdgeInsets.zero,
            child: AppPanel(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.wb_incandescent_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move around the room, then use your device AR support to place the piece at full scale.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
                          _formatCurrency(currentProduct.price),
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
        title: 'Your Shopping Bag',
        showBackButton: true,
        onBack: () => context.pop(),
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
              children: [
                AppPageWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        eyebrow: 'Ready to purchase',
                        title: 'A considered shortlist',
                        subtitle:
                            'Review quantities, refine the mix, and continue to checkout when the room feels complete.',
                      ),
                      const SizedBox(height: 24),
                      for (final item in cart.items) ...[
                        _CartItemPanel(item: item),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : AppBottomActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} selected',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(cart.totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/cart/checkout'),
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderRepository = context.read<OrderRepository>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppNavBar(
          title: 'Checkout',
          showBackButton: true,
          onBack: () => context.pop(),
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
        onBack: () => context.pop(),
      ),
      body: ListView(
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  eyebrow: 'Order summary',
                  title: 'One final review before delivery',
                  subtitle:
                      'Confirm the pieces, quantities, and total before placing the order. Your completed purchases will appear in your history.',
                ),
                const SizedBox(height: 24),
                AppPanel(
                  child: Column(
                    children: [
                      for (final item in cart.items) ...[
                        _CheckoutLineItem(item: item),
                        if (item != cart.items.last) const Divider(height: 32),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppPanel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated total',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Taxes and shipping are not modelled yet in this prototype.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(cart.totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomActionBar(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: cart.isBusy
                ? null
                : () async {
                    try {
                      await orderRepository.checkoutActiveCart();
                      await cart.refresh();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Checkout complete. Your order is now in purchase history.',
                          ),
                        ),
                      );
                      context.go('/account/purchases');
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unable to complete checkout: $error'),
                        ),
                      );
                    }
                  },
            child: Text(cart.isBusy ? 'Placing order...' : 'Place order'),
          ),
        ),
      ),
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.product});

  final Product? product;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EDITORIAL LIVING',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.burntSienna,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Furniture for the way you live.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 14),
              Text(
                'Curated pieces for calm rooms, tactile materials, and timeless silhouettes.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.deepUmber),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: product == null
                        ? null
                        : () => context.go('/product/${product!.id}'),
                    child: const Text('Shop the collection'),
                  ),
                  OutlinedButton.icon(
                    onPressed: product == null
                        ? null
                        : () => context.go('/ar/${product!.id}'),
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: const Text('Preview in AR'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: const [
                  _HeroMetric(label: 'Warm materials', value: 'Light-first'),
                  _HeroMetric(label: 'Responsive layout', value: 'Whole app'),
                  _HeroMetric(label: 'Purchase flow', value: 'Streamlined'),
                ],
              ),
            ],
          );

          final visual = product == null
              ? const SizedBox.shrink()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: isWide ? 0.92 : 1.3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(product!.imageUrlResolved, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  context.go('/product/${product!.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            product!.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(product!.price),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Open featured product',
                                      onPressed: () =>
                                          context.go('/product/${product!.id}'),
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (product != null) ...[const SizedBox(height: 20), visual],
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 11, child: content),
              if (product != null) ...[
                const SizedBox(width: 24),
                Expanded(flex: 10, child: visual),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

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
                  _formatCurrency(item.product.price),
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
                onPressed: () => cart.addItem(item.product),
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
          _formatCurrency(lineTotal),
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

String _categorySummary(Product product) {
  if (product.categories.isEmpty) {
    return 'Curated piece';
  }

  return product.categories.take(2).join(' · ');
}

String _formatCurrency(double amount) {
  if (amount == amount.roundToDouble()) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  return '\$${amount.toStringAsFixed(2)}';
}
