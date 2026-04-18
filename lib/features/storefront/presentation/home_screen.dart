import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../auth/application/auth_provider.dart';
import 'storefront_screens.dart'; // For ProductCard

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();
    final auth = context.watch<AuthProvider>();
    final displayName = auth.profile?.displayName ?? 'Guest';

    return Scaffold(
      appBar: const AppNavBar(title: 'AuraHome'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 200),
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                GlassyWelcome(displayName: displayName),
                const SizedBox(height: 24),
                _HomeHero(),
                const SizedBox(height: 48),
                AppSectionHeader(
                  eyebrow: 'Featured collection',
                  title: 'Editor’s seasonal selects',
                  subtitle: 'Our top choices for the modern, calming interior.',
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Product>>(
                  future: repository.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = (snapshot.data ?? []).take(3).toList();
                    if (products.isEmpty) {
                      return const AppMessagePanel(
                        title: 'No pieces found',
                        message: 'Check back soon for the latest collection.',
                        icon: Icons.inventory_2_outlined,
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const crossAxisCount = 2;
                        const spacing = 24.0;
                        const contentHeight = 155.0;
                        final cardWidth =
                            (constraints.maxWidth -
                                spacing * (crossAxisCount - 1)) /
                            crossAxisCount;
                        final imageHeight = cardWidth / 1.1;
                        final cardHeight = imageHeight + contentHeight;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                mainAxisExtent: cardHeight,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) =>
                              ProductCard(product: products[index]),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 48),
                AppPanel(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: AppTheme.burntSienna,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Room Designer',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Describe your dream room and see it instantly materialized with our AI.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/ai-room'),
                        child: const Text('Start Designing'),
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

class _HomeHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/welcome_hero.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(210), Colors.black.withAlpha(30)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REDEFINE\nYOUR SPACE',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Immersive furniture shopping with AR and AI.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withAlpha(210),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/catalog'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.burntSienna,
                foregroundColor: Colors.white,
              ),
              child: const Text('Shop the collection'),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassyWelcome extends StatelessWidget {
  const GlassyWelcome({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.burntSienna.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.burntSienna.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.burntSienna.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: AppTheme.burntSienna,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.richCharcoal,
                              fontWeight: FontWeight.w700,
                            ),
                        children: [
                          const TextSpan(text: 'Welcome, '),
                          TextSpan(
                            text: displayName,
                            style: const TextStyle(
                              color: AppTheme.burntSienna,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
