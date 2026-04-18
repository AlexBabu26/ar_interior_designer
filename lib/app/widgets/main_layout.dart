import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'floating_nav_bar.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child, required this.state});

  final Widget child;
  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    // Use state.uri.path (passed from the ShellRoute builder) — NOT
    // GoRouterState.of(context).matchedLocation, which inside a ShellRoute
    // always resolves to the shell's own segment ('/'), causing the nav bar
    // to show on every child page regardless of the actual route.
    final path = state.uri.path;

    // Only show the floating nav bar on the 4 main tab destinations.
    // All sub-pages (cart, checkout, product detail, purchase history, etc.)
    // must NOT show the nav bar.
    const mainTabs = <String>['/', '/catalog', '/ai-room', '/account'];
    final showNavBar = mainTabs.contains(path);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: showNavBar
          ? SafeArea(child: FloatingNavBar(currentPath: path))
          : null,
    );
  }
}
