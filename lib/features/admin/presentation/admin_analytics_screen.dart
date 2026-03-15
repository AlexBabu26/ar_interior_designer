import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../catalog/data/product_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderRepository = context.read<OrderRepository>();
    final productRepository = context.read<ProductRepository>();

    return Scaffold(
      appBar: AppNavBar(
        title: 'Analytics',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: FutureBuilder<({List<Order> orders, int productCount})>(
        future: Future.wait([
          orderRepository.getOrders(),
          productRepository.getAdminProducts(),
        ]).then((results) => (
          orders: results[0] as List<Order>,
          productCount: (results[1] as List).length,
        )),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load analytics',
                  message: '${snapshot.error}',
                  icon: Icons.bar_chart_rounded,
                ),
              ),
            );
          }

          final orders = snapshot.data!.orders;
          final productCount = snapshot.data!.productCount;
          final totalRevenue =
              orders.fold<double>(0, (sum, o) => sum + o.total);
          final recentOrders = orders.take(10).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              AppPageWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(
                      eyebrow: 'Admin',
                      title: 'Analytics dashboard',
                      subtitle:
                          'Order and product metrics to track storefront performance.',
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 500;
                        return isNarrow
                            ? Column(
                                children: [
                                  _StatCard(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Total orders',
                                    value: '${orders.length}',
                                  ),
                                  const SizedBox(height: 14),
                                  _StatCard(
                                    icon: Icons.attach_money,
                                    label: 'Total revenue',
                                    value: '\$${totalRevenue.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 14),
                                  _StatCard(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Products',
                                    value: '$productCount',
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.receipt_long_outlined,
                                      label: 'Total orders',
                                      value: '${orders.length}',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.attach_money,
                                      label: 'Total revenue',
                                      value:
                                          '\$${totalRevenue.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.inventory_2_outlined,
                                      label: 'Products',
                                      value: '$productCount',
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Recent orders',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    if (recentOrders.isEmpty)
                      AppPanel(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No orders yet.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final order in recentOrders) ...[
                        AppPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.orderNumber,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(order.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.deepUmber,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.parchment,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppTheme.deepUmber,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${order.total.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.burntSienna,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppTheme.burntSienna),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepUmber,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
