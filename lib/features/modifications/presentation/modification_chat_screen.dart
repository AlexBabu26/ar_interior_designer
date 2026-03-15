import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../auth/application/auth_provider.dart';
import '../data/modification_repository.dart';
import '../domain/furniture_modification.dart';
import '../domain/furniture_modification_message.dart';

class ModificationChatScreen extends StatefulWidget {
  const ModificationChatScreen({
    super.key,
    required this.modificationId,
  });

  final String modificationId;

  @override
  State<ModificationChatScreen> createState() => _ModificationChatScreenState();
}

class _ModificationChatScreenState extends State<ModificationChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  FurnitureModification? _modification;
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ModificationRepository>();
      final m = await repo.getModificationWithMessages(widget.modificationId);
      if (!mounted) return;
      setState(() {
        _modification = m;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final repo = context.read<ModificationRepository>();
      await repo.addMessage(
        modificationId: widget.modificationId,
        content: text,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _assignCarpenter() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final repo = context.read<ModificationRepository>();
      await repo.assignCarpenter(widget.modificationId);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final repo = context.read<ModificationRepository>();
      await repo.updateStatus(widget.modificationId, status);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;
    final isCarpenter = auth.isCarpenter;
    final isAdmin = auth.isAdmin;

    if (_loading) {
      return Scaffold(
        appBar: AppNavBar(
          title: 'Modification chat',
          showBackButton: true,
          onBack: () => context.pop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _modification == null) {
      return Scaffold(
        appBar: AppNavBar(
          title: 'Modification chat',
          showBackButton: true,
          onBack: () => context.pop(),
        ),
        body: Center(
          child: AppPageWidth(
            child: AppMessagePanel(
              title: 'Unable to load chat',
              message: _error ?? 'Not found',
              icon: Icons.chat_bubble_outline,
            ),
          ),
        ),
      );
    }

    final mod = _modification!;
    final canSend = mod.status != 'cancelled' &&
        (mod.requestedBy == userId ||
            mod.assignedCarpenterId == userId ||
            isAdmin);
    final canAssignCarpenter =
        isCarpenter && mod.assignedCarpenterId == null && mod.status == 'open';
    final canChangeStatus = (isCarpenter && mod.assignedCarpenterId == userId) ||
        isAdmin &&
            mod.status != 'cancelled';

    final productName = mod.orderItemProductName ?? mod.orderNumber ?? 'Modification';
    final customerName = mod.requestedByDisplayName;
    final subtitle = customerName != null
        ? '$productName · $customerName'
        : productName;

    return Scaffold(
      appBar: AppNavBar(
        title: 'Modification chat',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          AppPageWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusChip(mod.status),
                      if (canAssignCarpenter) ...[
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _assignCarpenter,
                          tooltip: 'Accept request',
                          icon: const Icon(Icons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          onPressed: _sending ? null : () => _updateStatus('cancelled'),
                          tooltip: 'Decline request',
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _sending ? null : _assignCarpenter,
                          child: const Text('Take this request'),
                        ),
                      ],
                      if (canChangeStatus && mod.status == 'in_progress') ...[
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _sending
                              ? null
                              : () => _updateStatus('completed'),
                          child: const Text('Mark completed'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: mod.messages.length,
              itemBuilder: (context, index) {
                final msg = mod.messages[index];
                return _MessageBubble(
                  message: msg,
                  isMe: msg.senderId == userId,
                  isCarpenter: msg.senderId == mod.assignedCarpenterId,
                );
              },
            ),
          ),
          if (canSend) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final label = status == 'in_progress'
        ? 'In progress'
        : status == 'completed'
            ? 'Completed'
            : status == 'cancelled'
                ? 'Cancelled'
                : 'Open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'completed'
            ? Colors.green.shade100
            : status == 'in_progress'
                ? Colors.blue.shade100
                : status == 'cancelled'
                    ? Colors.grey.shade200
                    : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isCarpenter,
  });

  final FurnitureModificationMessage message;
  final bool isMe;
  final bool isCarpenter;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                isCarpenter ? 'Carpenter' : 'Customer',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
