import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../modifications/data/modification_repository.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';
import '../domain/order_item.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<OrderRepository>();

    return Scaffold(
      appBar: AppNavBar(
        title: 'Purchase History',
        showBackButton: true,
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
            padding: const EdgeInsets.only(bottom: 40),
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
                            // ── Order header ──────────────────────────
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
                            // ── Order items ───────────────────────────
                            for (final item in order.items) ...[
                              _OrderItemRow(
                                orderId: order.id,
                                orderNumber: order.orderNumber,
                                item: item,
                              ),
                              if (item != order.items.last)
                                const Divider(height: 28),
                            ],
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: ${formatCurrency(order.total)}',
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

class _OrderItemRow extends StatefulWidget {
  const _OrderItemRow({
    required this.orderId,
    required this.orderNumber,
    required this.item,
  });

  final String orderId;
  final String orderNumber;
  final OrderItem item;

  @override
  State<_OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<_OrderItemRow> {
  bool _loading = false;

  Future<void> _openModificationChat() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = context.read<ModificationRepository>();
      var modificationId = await repo.getModificationIdByOrderItemId(
        widget.item.id,
      );
      if (modificationId == null) {
        final created = await repo.createModification(
          orderId: widget.orderId,
          orderItemId: widget.item.id,
        );
        modificationId = created.id;
      }
      if (!context.mounted) return;
      context.push('/account/modifications/$modificationId');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productRepo = context.read<ProductRepository>();

    return FutureBuilder<Product?>(
      future: item.productId != null
          ? productRepo.getProductById(item.productId!)
          : Future.value(null),
      builder: (context, snap) {
        final product = snap.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + info row ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image on the left
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product?.imageUrlResolved != null
                      ? Image.network(
                          product!.imageUrlResolved,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                        )
                      : _ImagePlaceholder(),
                ),
                const SizedBox(width: 16),
                // Product name + qty + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.deepUmber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(item.lineTotal),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Glassy chat button ────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: InkWell(
                  onTap: _loading ? null : _openModificationChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.burntSienna.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.burntSienna.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: AppTheme.burntSienna,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          'Request modification / Open chat',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.burntSienna,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppTheme.mutedClay,
        size: 28,
      ),
    );
  }
}
