import 'dart:io';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../catalog/data/product_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../../catalog/domain/product.dart';

enum ReportPeriod { weekly, monthly, yearly, overall }

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.overall;

  List<Order> _filterOrders(List<Order> orders) {
    if (_selectedPeriod == ReportPeriod.overall) return orders;

    final now = DateTime.now();
    return orders.where((order) {
      final diff = now.difference(order.createdAt);
      switch (_selectedPeriod) {
        case ReportPeriod.weekly:
          return diff.inDays <= 7;
        case ReportPeriod.monthly:
          return diff.inDays <= 30;
        case ReportPeriod.yearly:
          return diff.inDays <= 365;
        default:
          return true;
      }
    }).toList();
  }

  String formatCurrencyPdf(double amount) {
    return formatCurrency(amount).replaceFirst('₹', 'Rs.');
  }

  Future<void> _generatePdfReport(
    List<Order> orders,
    double revenue,
    int products,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy HH:mm').format(now);
    final invoiceRef =
        'RPT-${now.millisecondsSinceEpoch.toString().substring(7)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AURAHOME',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF8B4513),
                    ),
                  ),
                  pw.Text(
                    'Premium Furniture Store',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'OFFICIAL BUSINESS REPORT',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text('Ref: $invoiceRef'),
                  pw.Text('Date: $dateStr'),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1, height: 40, color: PdfColors.grey400),

          pw.Text(
            'Performance Summary: ${_selectedPeriod.name.toUpperCase()}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Operational Metrics',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Total Sales Volume: ${orders.length} Units'),
                    pw.Text('Active Product SKU Count: $products'),
                    pw.Text(
                      'Average Order Value: ${formatCurrencyPdf(orders.isEmpty ? 0 : revenue / orders.length)}',
                    ),
                  ],
                ),
              ),
              pw.Container(
                width: 150,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.brown50,
                  border: pw.Border.all(color: PdfColors.brown100),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'GROSS REVENUE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.brown700,
                      ),
                    ),
                    pw.Text(
                      formatCurrencyPdf(revenue),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.brown900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),
          pw.TableHelper.fromTextArray(
            headers: [
              'Order No.',
              'Date/Time',
              'Payment',
              'Platform',
              'Status',
              'Net Total',
            ],
            data: orders
                .map(
                  (o) => [
                    o.orderNumber,
                    DateFormat('MMM d').format(o.createdAt),
                    o.paymentMethod,
                    o.platform,
                    o.status.toUpperCase(),
                    formatCurrencyPdf(o.total),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown600),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: .5),
              ),
            ),
          ),

          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 150, child: pw.Divider(thickness: 1)),
                  pw.Text(
                    'Authorized Admin Signature',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Text(
                'Generated by AuraHome Business Analytics System v1.0',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'AuraHome_BusinessReport_${_selectedPeriod.name}_$invoiceRef.pdf',
    );
  }

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.parchment,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.burntSienna.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.burntSienna.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: AppTheme.burntSienna,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat(
                      'MMMM d, yyyy • HH:mm',
                    ).format(order.createdAt),
                  ),
                  _DetailRow(
                    label: 'Platform',
                    value: order.platform,
                    icon: Icons.devices_other,
                  ),
                  _DetailRow(
                    label: 'Payment',
                    value: order.paymentMethod,
                    icon: Icons.payments_outlined,
                  ),
                  const Divider(height: 32),
                  Text('Items', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          if (item.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Qty: ${item.quantity} • ${formatCurrency(item.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatCurrency(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    label: 'Subtotal',
                    value: formatCurrency(order.subtotal),
                  ),
                  _DetailRow(
                    label: 'Total',
                    value: formatCurrency(order.total),
                    isBold: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderRepository = context.read<OrderRepository>();
    final productRepository = context.read<ProductRepository>();

    return Scaffold(
      appBar: AppNavBar(
        title: 'Business Analytics',
        showBackButton: true,
        showCart: false,
      ),
      body:
          FutureBuilder<
            ({
              List<Order> orders,
              List<Product> products,
              List<Order> allOrders,
            })
          >(
            future:
                Future.wait([
                  orderRepository.getOrders(),
                  productRepository.getAdminProducts(),
                ]).then(
                  (results) => (
                    orders: _filterOrders(results[0] as List<Order>),
                    allOrders: results[0] as List<Order>,
                    products: results[1] as List<Product>,
                  ),
                ),
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
              final products = snapshot.data!.products;
              final productCount = products.length;
              final totalRevenue = orders.fold<double>(
                0,
                (sum, o) => sum + o.total,
              );
              final recentOrders = orders.take(15).toList();
              final lowStockProducts = products
                  .where((p) => p.stockQuantity < 5)
                  .toList();

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  AppPageWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppSectionHeader(
                                eyebrow: 'Admin',
                                title: 'Performance',
                                subtitle:
                                    'Official business tracking and auditing.',
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _generatePdfReport(
                                orders,
                                totalRevenue,
                                productCount,
                              ),
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: const Text('Export Business Report'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.burntSienna,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ReportPeriod.values.map((period) {
                              final isSelected = _selectedPeriod == period;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(period.name.toUpperCase()),
                                  onSelected: (_) =>
                                      setState(() => _selectedPeriod = period),
                                  selectedColor: AppTheme.burntSienna.withAlpha(
                                    40,
                                  ),
                                  checkmarkColor: AppTheme.burntSienna,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppTheme.burntSienna
                                        : AppTheme.deepUmber,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildMetricsGrid(
                          orders.length,
                          totalRevenue,
                          productCount,
                        ),
                        const SizedBox(height: 32),

                        // Inventory Warning (NEW)
                        if (lowStockProducts.isNotEmpty) ...[
                          Text(
                            'Inventory Warnings',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          for (final p in lowStockProducts)
                            _buildLowStockItem(p),
                          const SizedBox(height: 32),
                        ],

                        // Charts Section
                        if (orders.isNotEmpty) ...[
                          Text(
                            'Revenue Trend',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          AppPanel(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              height: 200,
                              child: LineChart(
                                _generateRevenueLineChart(orders),
                                duration: const Duration(milliseconds: 600),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),
                        Text(
                          'Recent activity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        if (recentOrders.isEmpty)
                          AppPanel(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No activity in this period.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          )
                        else
                          for (final order in recentOrders) ...[
                            InkWell(
                              onTap: () => _showOrderDetail(order),
                              borderRadius: BorderRadius.circular(24),
                              child: AppPanel(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    if (order.items.isNotEmpty &&
                                        order.items.first.imageUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 14,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            order.items.first.imageUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, _, __) =>
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    size: 24,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.items.isNotEmpty
                                                ? '${order.items.first.productName}${order.items.length > 1 ? ' + ${order.items.length - 1} more' : ''}'
                                                : order.orderNumber,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${order.orderNumber} • ${DateFormat('MMM d, yyyy').format(order.createdAt)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.deepUmber,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                      formatCurrency(order.total),
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

  Widget _buildLowStockItem(Product p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: p.isOutOfStock ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    p.isOutOfStock
                        ? 'OUT OF STOCK'
                        : '${p.stockQuantity} items remaining',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => context.push('/admin/inventory'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Restock'),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _generateRevenueLineChart(List<Order> orders) {
    // Sort orders by date
    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Group by Date (Day)
    final dailyRevenue = <String, double>{};
    for (var o in sortedOrders) {
      final date = DateFormat('MM/dd').format(o.createdAt);
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + o.total;
    }

    final spots = <FlSpot>[];
    double index = 0;
    for (var value in dailyRevenue.values) {
      spots.add(FlSpot(index, value));
      index++;
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              if (val % (spots.length / 4).ceil() != 0)
                return const SizedBox.shrink();
              final int i = val.toInt();
              if (i < 0 || i >= dailyRevenue.length)
                return const SizedBox.shrink();
              return Text(
                dailyRevenue.keys.elementAt(i),
                style: const TextStyle(fontSize: 10, color: AppTheme.deepUmber),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.burntSienna,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.burntSienna.withAlpha(30),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(int orderCount, double revenue, int productCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        final cards = [
          _StatCard(
            icon: Icons.receipt_long_outlined,
            label: 'Total orders',
            value: '$orderCount',
          ),
          _StatCard(
            icon: Icons.attach_money,
            label: 'Total revenue',
            value: formatCurrency(revenue),
          ),
          _StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            value: '$productCount',
          ),
        ];

        if (isNarrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cards
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: SizedBox(width: 130, child: c),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppTheme.deepUmber),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(color: AppTheme.deepUmber, fontSize: 13),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppTheme.burntSienna),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.deepUmber,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
