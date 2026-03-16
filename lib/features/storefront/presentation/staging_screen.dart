import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../auth/application/auth_provider.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../../image_generation/data/generated_image_repository.dart';
import '../../image_generation/data/generated_image_storage.dart';
import '../../image_generation/domain/generated_image.dart';
import '../data/ar_background_image_picker_stub.dart'
    if (dart.library.html) '../data/ar_background_image_picker_web.dart'
    as bg_picker;

// ── Per-item state ─────────────────────────────────────────────────────────────

class _StagingItem {
  _StagingItem({
    required this.id,
    required this.product,
    required this.position,
  });

  final String id;
  final Product product;
  Offset position;
  double size = 140.0;
}

// ── Background presets ─────────────────────────────────────────────────────────

const List<({String label, Color color})> _bgOptions = [
  (label: 'Warm', color: AppTheme.parchmentHighlight),
  (label: 'White', color: Colors.white),
  (label: 'Light gray', color: Color(0xFFE8E8E8)),
  (label: 'Soft cream', color: Color(0xFFF5F0E8)),
  (label: 'Cool gray', color: Color(0xFFE0E4E8)),
  (label: 'Dark', color: AppTheme.richCharcoal),
  (label: 'Photo', color: Color(0xFF9E9E9E)),
];

const int _photoIdx = 6;

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Virtual staging canvas — place product thumbnails on a solid colour or room
/// photo background and inspect each piece in 3D on demand.
class StagingScreen extends StatefulWidget {
  const StagingScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  State<StagingScreen> createState() => _StagingScreenState();
}

class _StagingScreenState extends State<StagingScreen> {
  final List<_StagingItem> _items = [];
  String? _selectedItemId;
  int _selectedBgIdx = 0;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialProduct());
    }
  }

  Future<void> _loadInitialProduct() async {
    final repo = context.read<ProductRepository>();
    final product = await repo.getProductById(widget.initialProductId!);
    if (product != null && mounted) {
      _addItem(product);
    }
  }

  // ── Item management ──────────────────────────────────────────────────────────

  void _addItem(Product product) {
    final size = MediaQuery.sizeOf(context);
    final offset = Offset(
      (size.width / 2 - 70).clamp(0, size.width - 140) +
          (_items.length % 5) * 18.0,
      (size.height / 2 - 70).clamp(0, size.height - 200) +
          (_items.length % 5) * 18.0,
    );
    setState(() {
      _items.add(
        _StagingItem(id: const Uuid().v4(), product: product, position: offset),
      );
    });
  }

  void _moveItem(String id, Offset delta) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    setState(() => _items[idx].position += delta);
  }

  void _selectItem(String id) =>
      setState(() => _selectedItemId = _selectedItemId == id ? null : id);

  void _deleteSelected() {
    if (_selectedItemId == null) return;
    setState(() {
      _items.removeWhere((i) => i.id == _selectedItemId);
      _selectedItemId = null;
    });
  }

  void _clearAll() => setState(() {
        _items.clear();
        _selectedItemId = null;
      });

  void _resizeSelected(double newSize) {
    final idx = _items.indexWhere((i) => i.id == _selectedItemId);
    if (idx == -1) return;
    setState(() => _items[idx].size = newSize);
  }

  _StagingItem? get _selectedItem {
    if (_selectedItemId == null) return null;
    try {
      return _items.firstWhere((i) => i.id == _selectedItemId);
    } catch (_) {
      return null;
    }
  }

  // ── Background helpers ───────────────────────────────────────────────────────

  bool get _usesPhoto =>
      _selectedBgIdx == _photoIdx &&
      _backgroundImageUrl != null &&
      _backgroundImageUrl!.isNotEmpty;

  Future<void> _pickAndUploadBackground() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) {
      _snack('Sign in to upload a room photo as background');
      return;
    }
    final picked = await bg_picker.pickArBackgroundImage();
    if (picked == null || !mounted) return;
    try {
      final url =
          await uploadArBackgroundImage(auth.currentUser!.id, picked.bytes);
      if (!mounted) return;
      setState(() => _backgroundImageUrl = url);
    } catch (e) {
      if (!mounted) return;
      _snack('Upload failed: $e');
    }
  }

  void _showGeneratedImagesSheet() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.currentUser == null) {
      _snack('Sign in to choose from your generated images');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _GeneratedImagesSheet(
        userId: auth.currentUser!.id,
        onSelect: (url) {
          setState(() => _backgroundImageUrl = url);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Product picker ───────────────────────────────────────────────────────────

  void _showProductPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        repository: context.read<ProductRepository>(),
        onProductSelected: (product) {
          Navigator.of(ctx).pop();
          _addItem(product);
        },
      ),
    );
  }

  // ── 3-D inspection dialog ────────────────────────────────────────────────────

  void _inspect3D(Product product) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ModelViewer(
                  src: product.modelUrlResolved,
                  alt: '3D model of ${product.name}',
                  ar: false,
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: AppTheme.parchment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Snack ────────────────────────────────────────────────────────────────────

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          for (final item in _items) _buildItemWidget(item),
          _buildTopBar(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedItem != null) ...[
                      _buildSelectionToolbar(_selectedItem!),
                      const SizedBox(height: 6),
                    ],
                    _buildBackgroundPanel(),
                    const SizedBox(height: 6),
                    _buildAddFurnitureButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ───────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    if (_usesPhoto) {
      return Positioned.fill(
        child: Image.network(
          _backgroundImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              ColoredBox(color: _bgOptions[_selectedBgIdx].color),
        ),
      );
    }
    return Positioned.fill(
      child: ColoredBox(color: _bgOptions[_selectedBgIdx].color),
    );
  }

  // ── Item widget ──────────────────────────────────────────────────────────────

  Widget _buildItemWidget(_StagingItem item) {
    final isSelected = item.id == _selectedItemId;
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _moveItem(item.id, d.delta),
        onTap: () => _selectItem(item.id),
        child: Stack(
          children: [
            Container(
              width: item.size,
              height: item.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: item.product.imageUrlResolved.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.product.imageUrlResolved),
                        fit: BoxFit.contain,
                      )
                    : null,
                color: item.product.imageUrlResolved.isEmpty
                    ? AppTheme.parchment
                    : null,
              ),
              child: item.product.imageUrlResolved.isEmpty
                  ? const Icon(Icons.chair_outlined, color: AppTheme.mutedClay)
                  : null,
            ),
            if (isSelected)
              Container(
                width: item.size,
                height: item.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.burntSienna,
                    width: 2.5,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.burntSienna,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_with_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.richCharcoal.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Stage Room',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const Spacer(),
              if (_items.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.richCharcoal.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chair_outlined,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        '${_items.length}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _circleButton(
                  icon: Icons.delete_sweep_outlined,
                  onTap: _clearAll,
                  tooltip: 'Clear all',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Selection toolbar ────────────────────────────────────────────────────────

  Widget _buildSelectionToolbar(_StagingItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.richCharcoal.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.open_with_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.product.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _StagingScaleChip(
            value: item.size,
            onChanged: _resizeSelected,
          ),
          const SizedBox(width: 6),
          if (item.product.modelUrlResolved.isNotEmpty) ...[
            _circleButton(
              icon: Icons.view_in_ar_outlined,
              onTap: () => _inspect3D(item.product),
              tooltip: 'Inspect in 3D',
              size: 34,
              iconSize: 17,
            ),
            const SizedBox(width: 6),
          ],
          _circleButton(
            icon: Icons.delete_outline_rounded,
            onTap: _deleteSelected,
            tooltip: 'Delete',
            size: 34,
            iconSize: 17,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 6),
          _circleButton(
            icon: Icons.close_rounded,
            onTap: () => setState(() => _selectedItemId = null),
            tooltip: 'Deselect',
            size: 34,
            iconSize: 17,
          ),
        ],
      ),
    );
  }

  // ── Background panel ─────────────────────────────────────────────────────────

  Widget _buildBackgroundPanel() {
    final isPhoto = _selectedBgIdx == _photoIdx;
    final hasPhoto =
        _backgroundImageUrl != null && _backgroundImageUrl!.isNotEmpty;
    final auth = context.read<AuthProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.richCharcoal.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Background',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_bgOptions.length, (i) {
                      final opt = _bgOptions[i];
                      final sel = i == _selectedBgIdx;
                      final isPhotoOpt = i == _photoIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: opt.label,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedBgIdx = i),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sel ? Colors.white : Colors.white30,
                                  width: sel ? 2.5 : 1,
                                ),
                              ),
                              child: isPhotoOpt
                                  ? Icon(
                                      hasPhoto
                                          ? Icons.image_rounded
                                          : Icons.image_outlined,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          if (isPhoto) ...[
            const SizedBox(height: 10),
            if (!auth.isAuthenticated)
              Text(
                'Sign in to upload a room photo.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white54),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _panelButton(
                    icon: Icons.upload_file,
                    label: 'Upload photo',
                    onPressed: _pickAndUploadBackground,
                  ),
                  _panelButton(
                    icon: Icons.photo_library_outlined,
                    label: 'My images',
                    onPressed: _showGeneratedImagesSheet,
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: () =>
                          setState(() => _backgroundImageUrl = null),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Clear'),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _panelButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Add Furniture button ─────────────────────────────────────────────────────

  Widget _buildAddFurnitureButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _showProductPicker,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Furniture'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.richCharcoal.withValues(alpha: 0.90),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  // ── Circle button helper ─────────────────────────────────────────────────────

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    double size = 42,
    double iconSize = 22,
    Color? color,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.richCharcoal.withValues(alpha: 0.70),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.white, size: iconSize),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }
}

// ── Scale chip + dialog ────────────────────────────────────────────────────────

class _StagingScaleChip extends StatelessWidget {
  const _StagingScaleChip({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value / 140 * 100).round();
    return GestureDetector(
      onTap: () => showDialog<double>(
        context: context,
        builder: (ctx) => _StagingScaleDialog(initial: value),
      ).then((result) {
        if (result != null) onChanged(result);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$pct%',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _StagingScaleDialog extends StatefulWidget {
  const _StagingScaleDialog({required this.initial});

  final double initial;

  @override
  State<_StagingScaleDialog> createState() => _StagingScaleDialogState();
}

class _StagingScaleDialogState extends State<_StagingScaleDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Item Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _value,
            min: 60,
            max: 400,
            divisions: 34,
            label: '${(_value / 140 * 100).round()}%',
            onChanged: (v) => setState(() => _value = v),
          ),
          Text(
            '${(_value / 140 * 100).round()}%  (${_value.round()} px)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// ── Product picker sheet ───────────────────────────────────────────────────────

class _ProductPickerSheet extends StatelessWidget {
  const _ProductPickerSheet({
    required this.repository,
    required this.onProductSelected,
  });

  final ProductRepository repository;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mutedClay,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose Furniture',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: repository.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading products: ${snapshot.error}'),
                      );
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AppMessagePanel(
                            title: 'No products',
                            message:
                                'No products found. Add products in the admin panel.',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _ProductPickerTile(
                          product: products[index],
                          onTap: () => onProductSelected(products[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductPickerTile extends StatelessWidget {
  const _ProductPickerTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  String _categorySummary() {
    if (product.categories.isEmpty) return 'Furnishing';
    return product.categories.take(3).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrlResolved.isNotEmpty
                    ? Image.network(
                        product.imageUrlResolved,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categorySummary().toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.burntSienna,
                            letterSpacing: 1.4,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(product.price),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.burntSienna),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppTheme.deepUmber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.parchment,
      child: const Icon(Icons.chair_outlined, color: AppTheme.mutedClay),
    );
  }
}

// ── Generated images sheet ─────────────────────────────────────────────────────

class _GeneratedImagesSheet extends StatelessWidget {
  const _GeneratedImagesSheet({
    required this.userId,
    required this.onSelect,
  });

  final String userId;
  final void Function(String url) onSelect;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GeneratedImageRepository>();
    return FutureBuilder<List<GeneratedImage>>(
      future: repo.getByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No generated images yet',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Generate images from the home page, then they will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Choose a room photo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final url = getGeneratedImageUrl(list[index].imagePath);
                    return GestureDetector(
                      onTap: () => onSelect(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
