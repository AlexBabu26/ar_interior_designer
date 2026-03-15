import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_surfaces.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';
import '../data/product_model_picker_stub.dart'
    if (dart.library.html) '../data/product_model_picker_web.dart' as model_picker;
import '../data/product_model_upload.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: FutureBuilder<List<Product>>(
        future: repository.getAdminProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load products',
                  message: '${snapshot.error}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            );
          }

          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'No products found',
                  message:
                      'Create the first product to start building the showroom collection.',
                  icon: Icons.add_business_outlined,
                  action: FilledButton.icon(
                    onPressed: () => context.push('/admin/products/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
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
                      eyebrow: 'Admin products',
                      title: 'Collection management',
                      subtitle:
                          'Review active products, launch edits, and keep the showroom presentation consistent.',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/admin/products/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final product in products) ...[
                      AppPanel(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              product.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.isActive ? 'Active' : 'Inactive'} · \$${product.price.toStringAsFixed(2)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '/admin/products/${product.id}/edit',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _modelUrlController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingModel = false;
  Product? _loadedProduct;
  Future<Product?>? _loadFuture;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadFuture = context.read<ProductRepository>().getProductById(
        widget.productId!,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoriesController.dispose();
    _modelUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFuture == null) {
      return _buildScaffold(context);
    }

    return FutureBuilder<Product?>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_loadedProduct == null && snapshot.data != null) {
          _loadedProduct = snapshot.data;
          _seedControllers(snapshot.data!);
        }

        return _buildScaffold(context);
      },
    );
  }

  Scaffold _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppPageWidth(
              maxWidth: 860,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    eyebrow: widget.productId == null
                        ? 'New product'
                        : 'Edit product',
                    title: widget.productId == null
                        ? 'Add a new showroom piece'
                        : 'Refine this showroom piece',
                    subtitle:
                        'Keep product content detailed, accurate, and presentation-ready for the storefront and AR flow.',
                  ),
                  const SizedBox(height: 24),
                  AppPanel(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a description'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Price'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            return parsed == null
                                ? 'Enter a valid price'
                                : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter an image URL'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _modelUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'Primary 3D model path',
                                  hintText: 'Upload a .glb/.gltf file or enter path',
                                  helperText: 'Stored under web/product_assets/models',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Upload a 3D model file or enter path'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.icon(
                                  onPressed: _isUploadingModel ? null : _pickAndUploadModel,
                                  icon: _isUploadingModel
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.upload_file),
                                  label: Text(_isUploadingModel ? 'Uploading...' : 'Upload file'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _categoriesController,
                          decoration: const InputDecoration(
                            labelText: 'Categories',
                            helperText:
                                'Comma-separated, for example Chairs, Living Room',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          value: _isActive,
                          title: const Text('Active'),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _save,
                            child: Text(
                              _isSaving ? 'Saving...' : 'Save Product',
                            ),
                          ),
                        ),
                        if (widget.productId != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _confirmDelete,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete product'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadModel() async {
    final picked = await model_picker.pickProductModelFile();
    if (picked == null || picked.bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected or could not read file.')),
      );
      return;
    }
    setState(() => _isUploadingModel = true);
    try {
      final path = await uploadProductModel(
        fileBytes: picked.bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      _modelUrlController.text = path;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model uploaded: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingModel = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
          'This will permanently remove the product and its 3D models. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await context.read<ProductRepository>().deleteProduct(widget.productId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted.')),
      );
      context.go('/admin/products');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete product: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final repository = context.read<ProductRepository>();

    try {
      final productId = await repository.saveProduct(
        Product(
          id: widget.productId ?? '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          imageUrl: _imageUrlController.text.trim(),
          categories: _categoriesController.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          modelUrl: _modelUrlController.text.trim(),
          isActive: _isActive,
        ),
      );

      await repository.savePrimaryModel(
        productId: productId,
        modelUrl: _modelUrlController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully.')),
      );
      context.go('/admin/products');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save product: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _seedControllers(Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(2);
    _imageUrlController.text = product.imageUrl;
    _categoriesController.text = product.categories.join(', ');
    _modelUrlController.text = product.modelUrl;
    _isActive = product.isActive;
  }
}
