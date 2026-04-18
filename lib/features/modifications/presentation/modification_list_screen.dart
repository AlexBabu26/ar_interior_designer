import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../auth/application/auth_provider.dart';
import '../data/modification_repository.dart';
import '../domain/furniture_modification.dart';

class ModificationListScreen extends StatefulWidget {
  const ModificationListScreen({super.key, this.productId, this.history = false});

  final String? productId;
  final bool history;

  @override
  State<ModificationListScreen> createState() => _ModificationListScreenState();
}

class _ModificationListScreenState extends State<ModificationListScreen> {
  List<FurnitureModification>? _list;
  bool _loading = true;
  String? _error;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ModificationRepository>();
      final list = await repo.listModifications();
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _acceptRequest(String modificationId) async {
    if (_busyIds.contains(modificationId)) return;
    setState(() => _busyIds.add(modificationId));
    try {
      final repo = context.read<ModificationRepository>();
      await repo.assignCarpenter(modificationId);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(modificationId));
    }
  }

  Future<void> _declineRequest(String modificationId) async {
    if (_busyIds.contains(modificationId)) return;
    setState(() => _busyIds.add(modificationId));
    try {
      final repo = context.read<ModificationRepository>();
      await repo.updateStatus(modificationId, 'cancelled');
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(modificationId));
    }
  }

  Future<void> _completeRequest(String modificationId) async {
    if (_busyIds.contains(modificationId)) return;
    setState(() => _busyIds.add(modificationId));
    try {
      final repo = context.read<ModificationRepository>();
      await repo.updateStatus(modificationId, 'completed');
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete: $e')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(modificationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCarpenter = auth.isCarpenter;
    final isAdmin = auth.isAdmin;

    String title;
    String subtitle;
    if (isCarpenter) {
      title = widget.history ? 'Past modifications' : 'Active requests';
      subtitle = widget.history
          ? 'Completed and cancelled modification threads.'
          : 'Open and assigned requests. Tap to view and respond.';
    } else if (isAdmin) {
      title = 'All modification chats';
      subtitle = 'View all customer–carpenter modification threads.';
    } else {
      title = 'My modification requests';
      subtitle = 'Chat with the carpenter about your purchased items.';
    }

    return Scaffold(
      appBar: AppNavBar(
        title: title,
        showBackButton: true,
        showCart: !isCarpenter && !isAdmin,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load',
                  message: _error!,
                  icon: Icons.list_alt,
                ),
              ),
            )
          : _list!.isEmpty
          ? Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: isCarpenter
                      ? 'No requests yet'
                      : 'No modification requests',
                  message: isCarpenter
                      ? 'When customers request modifications from their purchase history, they will appear here.'
                      : 'From your purchase history you can request modifications for an item and chat with a carpenter.',
                  icon: Icons.chat_bubble_outline,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: Builder(
                builder: (context) {
                  // Filter drafts: hide 'pending_order' from carpenters
                  final displayList = isCarpenter
                      ? _list!.where((m) => m.status != 'pending_order').toList()
                      : _list!;

                  // Filter for history: hide completed/cancelled if history=false, show only those if history=true
                  final historyFiltered = isCarpenter
                      ? displayList.where((m) {
                          final isPast = m.status == 'completed' || m.status == 'cancelled';
                          return widget.history ? isPast : !isPast;
                        }).toList()
                      : displayList;

                  // Filter the list in-memory if a productId is specified
                  final filteredList = widget.productId != null
                      ? historyFiltered.where((m) => m.productId == widget.productId).toList()
                      : historyFiltered;

                  if (filteredList.isEmpty) {
                    return Center(
                      child: AppPageWidth(
                        child: AppMessagePanel(
                          title: widget.productId != null
                              ? 'No chats for this item'
                              : 'No modification requests',
                          message: widget.productId != null
                              ? 'You haven\'t started a conversation about this product yet. Purchase this item first to start a formal modification request.'
                              : 'Requests will appear here.',
                          icon: Icons.chat_bubble_outline,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final mod = filteredList[index];
                      final productTitle =
                          mod.orderItemProductName ??
                          mod.orderNumber ??
                          'Request ${mod.id.substring(0, 8)}';
                  final isOpen = mod.status == 'open';
                  final isInProgress = mod.status == 'in_progress';
                  final isCarpenterAction = isCarpenter && (isOpen || isInProgress);
                  final busy = _busyIds.contains(mod.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () =>
                          context.push('/account/modifications/${mod.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            if (mod.orderItemImageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    mod.orderItemImageUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => Container(
                                      width: 56,
                                      height: 56,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    productTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((isCarpenter || isAdmin) &&
                                      mod.requestedByDisplayName != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer: ${mod.requestedByDisplayName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.burntSienna,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_statusLabel(mod.status)} • ${_formatDate(mod.updatedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: (mod.status == 'completed' || mod.status == 'cancelled')
                                              ? Colors.red.shade700
                                              : null,
                                          fontWeight: (mod.status == 'completed' || mod.status == 'cancelled')
                                              ? FontWeight.w600
                                              : null,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isCarpenterAction) ...[
                              if (isOpen) ...[
                                IconButton(
                                  onPressed: busy
                                      ? null
                                      : () => _acceptRequest(mod.id),
                                  tooltip: 'Accept',
                                  icon: busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green.shade700,
                                        ),
                                ),
                                IconButton(
                                  onPressed: busy
                                      ? null
                                      : () => _declineRequest(mod.id),
                                  tooltip: 'Decline',
                                  icon: Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ] else if (isInProgress) ...[
                                TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _completeRequest(mod.id),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.done_all_rounded, size: 18),
                                  label: const Text('Complete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green.shade800,
                                    backgroundColor: Colors.green.withAlpha(20),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                    },
                  );
                },
              ),
            ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final months = [
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
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
