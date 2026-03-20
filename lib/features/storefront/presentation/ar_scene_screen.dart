import 'dart:io';

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../../app/currency.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';

class _PlacedObject {
  _PlacedObject({
    required this.node,
    required this.anchor,
    required this.product,
    required this.scale,
  });

  ARNode node;
  final ARAnchor anchor;
  final Product product;
  double scale;
}

class ARSceneScreen extends StatefulWidget {
  const ARSceneScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  State<ARSceneScreen> createState() => _ARSceneScreenState();
}

class _ARSceneScreenState extends State<ARSceneScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final List<_PlacedObject> _placedObjects = [];
  String? _selectedNodeName;

  bool _isPlacingProduct = false;
  Product? _pendingProduct;

  double _pendingScale = 0.2;

  bool _arReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProductId != null) {
      _loadInitialProduct();
    }
  }

  Future<void> _loadInitialProduct() async {
    final repo = context.read<ProductRepository>();
    final product = await repo.getProductById(widget.initialProductId!);
    if (product != null && product.modelUrlResolved.isNotEmpty && mounted) {
      setState(() {
        _pendingProduct = product;
        _isPlacingProduct = true;
      });
    }
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    _arObjectManager!.onInitialize();

    _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
    _arObjectManager!.onNodeTap = _onNodeTapped;
    _arObjectManager!.onPanEnd = _onPanEnd;
    _arObjectManager!.onRotationEnd = _onRotationEnd;

    _applyInteractionMode();

    setState(() {
      _arReady = true;
    });
  }

  void _applyInteractionMode() {
    final interacting = !_isPlacingProduct;
    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: interacting,
      handleRotation: interacting,
      showAnimatedGuide: !interacting,
    );
  }

  Future<void> _onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    if (!_isPlacingProduct || _pendingProduct == null) return;

    final planeHit = hitTestResults
        .where((hit) => hit.type == ARHitTestResultType.plane)
        .toList();

    if (planeHit.isEmpty) {
      _showSnack('No surface detected. Try pointing at the floor.');
      return;
    }

    final hit = planeHit.first;
    final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await _arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor != true) {
      _showSnack('Could not anchor to that surface. Try again.');
      return;
    }

    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: _pendingProduct!.modelUrlResolved,
      scale: vm.Vector3(_pendingScale, _pendingScale, _pendingScale),
      position: vm.Vector3.zero(),
      data: {'productId': _pendingProduct!.id},
    );

    final didAddNode = await _arObjectManager!.addNode(
      newNode,
      planeAnchor: newAnchor,
    );

    if (didAddNode == true) {
      setState(() {
        _placedObjects.add(_PlacedObject(
          node: newNode,
          anchor: newAnchor,
          product: _pendingProduct!,
          scale: _pendingScale,
        ));
        _isPlacingProduct = false;
        _pendingProduct = null;
      });
      _applyInteractionMode();
    } else {
      _arAnchorManager!.removeAnchor(newAnchor);
      _showSnack('Failed to place the model. Check the 3D file URL.');
    }
  }

  Future<void> _onNodeTapped(List<String> nodeNames) async {
    if (nodeNames.isEmpty) return;
    setState(() {
      if (_selectedNodeName == nodeNames.first) {
        _selectedNodeName = null;
      } else {
        _selectedNodeName = nodeNames.first;
      }
    });
  }

  void _onPanEnd(String nodeName, Matrix4 newTransform) {
    // Plugin already moved the node on the native side; nothing extra needed.
  }

  void _onRotationEnd(String nodeName, Matrix4 newTransform) {
    // Plugin already rotated the node on the native side.
  }

  void _enterPlacementMode(Product product) {
    setState(() {
      _pendingProduct = product;
      _isPlacingProduct = true;
      _selectedNodeName = null;
    });
    _applyInteractionMode();
  }

  void _cancelPlacement() {
    setState(() {
      _isPlacingProduct = false;
      _pendingProduct = null;
    });
    _applyInteractionMode();
  }

  Future<void> _deleteSelected() async {
    if (_selectedNodeName == null) return;
    final index = _placedObjects.indexWhere(
      (obj) => obj.node.name == _selectedNodeName,
    );
    if (index == -1) return;

    final obj = _placedObjects[index];
    _arObjectManager!.removeNode(obj.node);
    _arAnchorManager!.removeAnchor(obj.anchor);

    setState(() {
      _placedObjects.removeAt(index);
      _selectedNodeName = null;
    });
  }

  Future<void> _scaleSelected(double newScale) async {
    if (_selectedNodeName == null) return;
    final idx = _placedObjects.indexWhere(
      (o) => o.node.name == _selectedNodeName,
    );
    if (idx == -1) return;

    final obj = _placedObjects[idx];
    await _arObjectManager!.removeNode(obj.node);

    final replacement = ARNode(
      type: NodeType.webGLB,
      uri: obj.product.modelUrlResolved,
      scale: vm.Vector3(newScale, newScale, newScale),
      position: vm.Vector3.zero(),
      data: {'productId': obj.product.id},
    );

    final ok = await _arObjectManager!.addNode(
      replacement,
      planeAnchor: obj.anchor as ARPlaneAnchor,
    );

    if (ok == true) {
      setState(() {
        obj.node = replacement;
        obj.scale = newScale;
        _selectedNodeName = replacement.name;
      });
    } else {
      await _arObjectManager!.addNode(obj.node, planeAnchor: obj.anchor as ARPlaneAnchor);
      _showSnack('Could not rescale the model.');
    }
  }

  Future<void> _clearAll() async {
    for (final obj in _placedObjects) {
      _arObjectManager?.removeNode(obj.node);
      _arAnchorManager?.removeAnchor(obj.anchor);
    }
    setState(() {
      _placedObjects.clear();
      _selectedNodeName = null;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  _PlacedObject? get _selectedObject {
    if (_selectedNodeName == null) return null;
    final idx = _placedObjects.indexWhere(
      (o) => o.node.name == _selectedNodeName,
    );
    return idx == -1 ? null : _placedObjects[idx];
  }

  void _showProductPicker() {
    final repo = context.read<ProductRepository>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        repository: repo,
        onProductSelected: (product) {
          Navigator.of(ctx).pop();
          _enterPlacementMode(product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isAndroid) {
      return _buildARScaffold(context);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('AR Scene'),
      ),
      body: const Center(
        child: AppPageWidth(
          child: AppMessagePanel(
            title: 'AR not available',
            message:
                'The interactive AR scene requires an Android device with ARCore support.',
            icon: Icons.view_in_ar_outlined,
          ),
        ),
      ),
    );
  }

  Widget _buildARScaffold(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          _buildTopBar(context),
          if (_isPlacingProduct && _pendingProduct != null)
            _buildPlacementBanner(context),
          if (_selectedNodeName != null) _buildSelectionToolbar(context),
          _buildBottomControls(context),
          if (kDebugMode) _buildDebugBanner(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.richCharcoal.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'AR Scene',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const Spacer(),
              if (_placedObjects.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.richCharcoal.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chair_outlined,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${_placedObjects.length}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              if (_placedObjects.isNotEmpty) const SizedBox(width: 8),
              if (_placedObjects.isNotEmpty)
                _circleButton(
                  icon: Icons.delete_sweep_outlined,
                  onTap: _clearAll,
                  tooltip: 'Clear all',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementBanner(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.burntSienna.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a surface to place ${_pendingProduct!.name}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                _ScaleChip(
                  value: _pendingScale,
                  onChanged: (v) => setState(() => _pendingScale = v),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cancelPlacement,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context) {
    final selected = _selectedObject;
    if (selected == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.richCharcoal.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_with_rounded, color: Colors.white54, size: 14),
                SizedBox(width: 6),
                Text('Drag to move · Two fingers to rotate',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.richCharcoal.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 14),
                _circleButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final s = (selected.scale - 0.03).clamp(0.01, 1.0);
                    _scaleSelected(s);
                  },
                  tooltip: 'Scale down',
                  size: 34,
                  iconSize: 16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${(selected.scale * 500).round()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                _circleButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final s = (selected.scale + 0.03).clamp(0.01, 1.0);
                    _scaleSelected(s);
                  },
                  tooltip: 'Scale up',
                  size: 34,
                  iconSize: 16,
                ),
                const SizedBox(width: 10),
                _circleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: _deleteSelected,
                  tooltip: 'Delete',
                  size: 34,
                  iconSize: 16,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                _circleButton(
                  icon: Icons.close_rounded,
                  onTap: () => setState(() => _selectedNodeName = null),
                  tooltip: 'Deselect',
                  size: 34,
                  iconSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _arReady && !_isPlacingProduct
                      ? _showProductPicker
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Furniture'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppTheme.richCharcoal.withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugBanner(BuildContext context) {
    return Positioned(
      bottom: 70,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade800.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Debug mode — ARCore tracking may be unreliable. Test in profile/release.',
            style: TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

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
          color: AppTheme.richCharcoal.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.white, size: iconSize),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }
}

class _ScaleChip extends StatelessWidget {
  const _ScaleChip({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  String get _label {
    final pct = (value * 500).round();
    return '${pct}%';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog<double>(
          context: context,
          builder: (ctx) => _ScaleDialog(initial: value),
        ).then((result) {
          if (result != null) onChanged(result);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _label,
          style:
              const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _ScaleDialog extends StatefulWidget {
  const _ScaleDialog({required this.initial});
  final double initial;

  @override
  State<_ScaleDialog> createState() => _ScaleDialogState();
}

class _ScaleDialogState extends State<_ScaleDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Model Scale'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _value,
            min: 0.01,
            max: 1.0,
            divisions: 99,
            label: '${(_value * 500).round()}%',
            onChanged: (v) => setState(() => _value = v),
          ),
          Text('${(_value * 500).round()}%'),
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                    final products = (snapshot.data ?? [])
                        .where((p) => p.modelUrlResolved.isNotEmpty)
                        .toList();

                    if (products.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AppMessagePanel(
                            title: 'No 3D models',
                            message:
                                'No products with 3D models found. Upload .glb files in the admin panel first.',
                            icon: Icons.view_in_ar_outlined,
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
                        final product = products[index];
                        return _ProductPickerTile(
                          product: product,
                          onTap: () => onProductSelected(product),
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
  const _ProductPickerTile({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

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
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.parchment,
      child: const Icon(Icons.chair_outlined, color: AppTheme.mutedClay),
    );
  }
}
