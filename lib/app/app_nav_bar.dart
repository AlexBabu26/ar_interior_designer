import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/cart/presentation/cart_provider.dart';

/// A consistent app bar for the main app: logo/title, optional back, cart + auth.
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.onBack,
  });

  final String? title;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitle = title ?? 'AR Home';

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? AppTheme.parchment,
      foregroundColor: theme.appBarTheme.foregroundColor ?? AppTheme.richCharcoal,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            )
          : null,
      leadingWidth: showBackButton ? 56 : null,
      title: GestureDetector(
        onTap: showBackButton ? null : () => context.go('/'),
        child: Text(
          effectiveTitle,
          style: theme.appBarTheme.titleTextStyle ??
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.richCharcoal,
              ),
        ),
      ),
      actions: [
        const AuthMenuButton(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => context.go('/cart'),
              tooltip: 'Cart',
            ),
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                final count = cart?.itemCount ?? 0;
                if (count == 0) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
