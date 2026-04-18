import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../../orders/domain/order_item.dart';
import '../../modifications/data/modification_repository.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final repo = context.read<OrderRepository>();
      final o = await repo.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = o;
          _isLoading = false;
        });

        // Promote any pending modification chats for these products
        _promoteDrafts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _promoteDrafts() async {
    try {
      final repo = context.read<ModificationRepository>();
      await repo.promoteModifications(widget.orderId);
    } catch (_) {
      // Background task, we don't want to block the success UI
      // but we could log it if needed.
    }
  }

  String _formatPdfCurrency(double amount) {
    return 'Rs. ${formatCurrency(amount).replaceFirst('₹', '')}';
  }

  Future<void> _generateAndDownloadReceipt() async {
    if (_order == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header Section ──────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AURAHOME',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF9F623B), // Burnt Sienna
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'THE ART OF INTERIOR DESIGN',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFF9F623B)),
              pw.SizedBox(height: 20),

              // ── Info Row ────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CUSTOMER ORDER:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '#${_order!.orderNumber}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Payment: ${_order!.paymentMethod}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE ISSUED:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        DateFormat('MMMM dd, yyyy').format(_order!.createdAt),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Status: ${_order!.status.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // ── Table Header ────────────────────────────────────
              pw.Container(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Text(
                        'DESCRIPTION',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'QTY',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'PRICE',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'AMOUNT',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Table Rows ──────────────────────────────────────
              for (final it in _order!.items)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 6,
                        child: pw.Text(
                          it.productName,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${it.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          _formatPdfCurrency(it.unitPrice),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          _formatPdfCurrency(it.lineTotal),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Summary Section ─────────────────────────────────
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Subtotal',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              _formatPdfCurrency(_order!.subtotal),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: PdfColors.white),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              _formatPdfCurrency(_order!.total),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF9F623B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ── Footer ──────────────────────────────────────────
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'THANK YOU FOR YOUR PATRONAGE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF9F623B),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'www.aurahome.com',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
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

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Receipt-${_order!.orderNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _order == null) {
      return Scaffold(
        body: Center(
          child: AppMessagePanel(
            title: 'Something went wrong',
            message: _error ?? 'Unable to find your order details.',
            icon: Icons.error_outline_rounded,
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.parchment,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppPageWidth(
            maxWidth: 600,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Placed!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'THANK YOU FOR SHOPPING WITH US',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 2.4,
                    color: AppTheme.burntSienna,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                AppPanel(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Number',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _order!.orderNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                formatCurrency(_order!.total),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _generateAndDownloadReceipt,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download Receipt (PDF)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.richCharcoal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ModificationInquirySection(order: _order!),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Back to shopping'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModificationInquirySection extends StatefulWidget {
  const _ModificationInquirySection({required this.order});
  final Order order;

  @override
  State<_ModificationInquirySection> createState() =>
      _ModificationInquirySectionState();
}

class _ModificationInquirySectionState
    extends State<_ModificationInquirySection> {
  final Set<String> _busyItemIds = {}; // Track which items are creating chat
  final Map<String, String?> _existingModIds = {}; // item.id -> modId

  @override
  void initState() {
    super.initState();
    _checkExistingMods();
  }

  Future<void> _checkExistingMods() async {
    try {
      final repo = context.read<ModificationRepository>();
      final mods = await repo.listModifications();
      if (!mounted) return;

      setState(() {
        for (final item in widget.order.items) {
          final existing = mods.where((m) => m.orderItemId == item.id).toList();
          if (existing.isNotEmpty) {
            _existingModIds[item.id] = existing.first.id;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _startChat(OrderItem item) async {
    setState(() => _busyItemIds.add(item.id));
    try {
      final repo = context.read<ModificationRepository>();
      final mod = await repo.createModification(
        orderId: widget.order.id,
        orderItemId: item.id,
        productId: item.productId,
      );
      if (mounted) {
        context.push('/account/modifications/${mod.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.burntSienna, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personalize your furniture',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final item in widget.order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppPanel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Request custom sizing or finishes.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_existingModIds[item.id] != null)
                    TextButton.icon(
                      onPressed: () => context.push(
                          '/account/modifications/${_existingModIds[item.id]}'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: const Text('Open Chat'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.burntSienna,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    _busyItemIds.contains(item.id)
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => _startChat(item),
                            icon: const Icon(Icons.add_comment_outlined,
                                size: 16),
                            label: const Text('Request Modification'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.burntSienna,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
