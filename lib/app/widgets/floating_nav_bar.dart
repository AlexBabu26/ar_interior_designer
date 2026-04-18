import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../../features/auth/application/auth_provider.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.profile?.displayName ?? 'Guest';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      height: 64,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavBarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isSelected: currentPath == '/',
                    onTap: () => context.go('/'),
                  ),
                  _NavBarItem(
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag,
                    label: 'Shopping',
                    isSelected: currentPath.startsWith('/catalog'),
                    onTap: () => context.go('/catalog'),
                  ),
                  _NavBarItem(
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome,
                    label: 'AI Room',
                    isSelected: currentPath == '/ai-room',
                    onTap: () => context.go('/ai-room'),
                  ),
                  _NavBarItem(
                    label: 'Profile',
                    isSelected: currentPath.startsWith('/account'),
                    onTap: () => context.go('/account'),
                    customIcon: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: currentPath.startsWith('/account')
                            ? AppTheme.burntSienna.withValues(alpha: 0.15)
                            : AppTheme.richCharcoal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentPath.startsWith('/account')
                              ? AppTheme.burntSienna.withValues(alpha: 0.3)
                              : AppTheme.richCharcoal.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentPath.startsWith('/account')
                                ? AppTheme.burntSienna
                                : AppTheme.richCharcoal.withAlpha(180),
                          ),
                        ),
                      ),
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

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    this.icon,
    this.activeIcon,
    this.customIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : assert(customIcon != null || (icon != null && activeIcon != null));

  final IconData? icon;
  final IconData? activeIcon;
  final Widget? customIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTheme.burntSienna
        : AppTheme.richCharcoal.withAlpha(180);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customIcon != null)
              SizedBox(width: 24, height: 24, child: Center(child: customIcon))
            else
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.burntSienna,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
