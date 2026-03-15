import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/order_repository.dart';
import '../domain/order.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<OrderRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: FutureBuilder<List<Order>>(
        future: repository.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load orders: ${snapshot.error}'),
              ),
            );
          }

          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No purchases yet. Orders you place from checkout will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderNumber,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(order.status.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed on ${order.createdAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      for (final item in order.items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text('Qty: ${item.quantity}'),
                          trailing: Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                          ),
                        ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: \$${order.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: orders.length,
          );
        },
      ),
    );
  }
}
