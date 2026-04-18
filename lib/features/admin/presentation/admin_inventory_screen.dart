import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  Future<List<Product>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = context.read<ProductRepository>().getAdminProducts();
    });
  }

  Future<void> _updateStock(Product product, int newQuantity) async {
    if (newQuantity < 0) return;

    try {
      await context.read<ProductRepository>().updateStockQuantity(
        product.id,
        newQuantity,
      );
      _refreshProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update stock: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        title: 'Stock Management',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              AppPageWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      eyebrow: 'Inventory',
                      title: 'Live Stock Levels',
                      subtitle:
                          'Monitor and adjust inventory quantities in real-time. Changes are saved instantly.',
                    ),
                    const SizedBox(height: 24),
                    AppPanel(
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: products.map((product) {
                            final isLow = product.stockQuantity <= 5;
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          product.imageUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _StockButton(
                                        label: '-10',
                                        onPressed: () => _updateStock(
                                          product,
                                          product.stockQuantity - 10,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _StockButton(
                                        label: '-',
                                        onPressed: () => _updateStock(
                                          product,
                                          product.stockQuantity - 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.parchment,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.burntSienna
                                                .withAlpha(50),
                                          ),
                                        ),
                                        child: Text(
                                          '${product.stockQuantity}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _StockButton(
                                        label: '+',
                                        onPressed: () => _updateStock(
                                          product,
                                          product.stockQuantity + 1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _StockButton(
                                        label: '+10',
                                        onPressed: () => _updateStock(
                                          product,
                                          product.stockQuantity + 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLow
                                          ? Colors.red.withAlpha(30)
                                          : Colors.green.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isLow ? 'LOW' : 'GOOD',
                                      style: TextStyle(
                                        color: isLow
                                            ? Colors.red
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
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

class _StockButton extends StatelessWidget {
  const _StockButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.burntSienna.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppTheme.burntSienna,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
