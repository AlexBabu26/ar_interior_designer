import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'features/catalog/domain/product.dart';
import 'features/catalog/data/product_repository.dart';
import 'features/cart/presentation/cart_provider.dart';

// --- Theme State ---

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// --- Navigation ---

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CatalogScreen(),
      routes: [
        GoRoute(
          path: 'product/:id',
          builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'ar/:id',
          builder: (context, state) => ARViewScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
      ],
    ),
  ],
);

// --- App Entry ---

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        Provider(create: (_) => ProductRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textTheme = GoogleFonts.lexendTextTheme(Theme.of(context).textTheme);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D3142),
        primary: const Color(0xFF2D3142),
        secondary: const Color(0xFFEF8354),
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFBFC0C0),
        primary: const Color(0xFFBFC0C0),
        secondary: const Color(0xFFEF8354),
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
    );

    return MaterialApp.router(
      title: 'AR Home',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Screens ---

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Chairs', 'Tables', 'Sofas'];

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ProductRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('AR Home', style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.go('/cart'),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) => cart.itemCount > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: repository.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data ?? [];
          final filteredProducts = selectedCategory == 'All' ? products : products.where((p) => p.categories.contains(selectedCategory)).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Modern Living", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ChoiceChip(
                            label: Text(categories[index]),
                            selected: selectedCategory == categories[index],
                            onSelected: (_) => setState(() => selectedCategory = categories[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'product-${product.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('\$${product.price}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ProductRepository>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: FutureBuilder<Product?>(
        future: repository.getProductById(productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final product = snapshot.data!;

          return Column(
            children: [
              Expanded(
                flex: 4,
                child: Hero(
                  tag: 'product-${product.id}',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('\$${product.price}', style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Text(product.description, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/ar/${product.id}'),
                              icon: const Icon(Icons.view_in_ar),
                              label: const Text('View in AR'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                            child: IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                              onPressed: () => context.read<CartProvider>().addItem(product),
                              padding: const EdgeInsets.all(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ARViewScreen extends StatelessWidget {
  final String productId;
  const ARViewScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ProductRepository>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AR View')),
      body: FutureBuilder<Product?>(
        future: repository.getProductById(productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final product = snapshot.data!;

          return Stack(
            children: [
              ModelViewer(
                backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
                src: product.modelUrl,
                alt: 'A 3D model of ${product.name}',
                ar: true,
                arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                autoRotate: true,
                cameraControls: true,
                disableZoom: false,
              ),
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(product.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$${product.price}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CartProvider>().addItem(product);
                          context.pop();
                          context.push('/cart');
                        },
                        child: const Text('Add to Bag'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Shopping Bag')),
      body: cart.items.isEmpty
          ? const Center(child: Text("Bag is empty"))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: NetworkImage(item.product.imageUrl), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$${item.product.price}', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: () => cart.removeSingleItem(item.product.id), icon: const Icon(Icons.remove)),
                          Text('${item.quantity}'),
                          IconButton(onPressed: () => cart.addItem(item.product), icon: const Icon(Icons.add)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.items.isEmpty ? null : Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total"),
                Text("\$${cart.totalAmount}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(24)),
                child: const Text("Checkout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
