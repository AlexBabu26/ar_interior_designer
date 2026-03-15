import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<OrderRepository>();

    return Scaffold(
      appBar: AppNavBar(
        title: 'Purchase History',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: FutureBuilder<List<Order>>(
        future: repository.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load purchase history',
                  message: '${snapshot.error}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'No purchases yet',
                  message:
                      'Orders you place from checkout will appear here in a calm timeline of completed pieces.',
                  icon: Icons.chair_outlined,
                ),
              ),
            );
          }

          return ListView(
            children: [
              AppPageWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(
                      eyebrow: 'Purchase history',
                      title: 'Purchase history',
                      subtitle: 'Every order, gathered in one calm timeline.',
                    ),
                    const SizedBox(height: 24),
                    for (final order in orders) ...[
                      AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderNumber,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Placed on ${_formatDate(order.createdAt)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.parchment,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            for (final item in order.items) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(item.lineTotal),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              if (item != order.items.last)
                                const Divider(height: 28),
                            ],
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: ${_formatCurrency(order.total)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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

String _formatCurrency(double amount) {
  if (amount == amount.roundToDouble()) {
    return '\$${amount.toStringAsFixed(0)}';
  }

  return '\$${amount.toStringAsFixed(2)}';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][local.month - 1];
  return '$month ${local.day}, ${local.year}';
}
