import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../catalog/data/product_repository.dart';
import '../../catalog/domain/product.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            onPressed: () => context.push('/admin/products/new'),
            icon: const Icon(Icons.add),
            tooltip: 'Add product',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: FutureBuilder<List<Product>>(
        future: repository.getAdminProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load products: ${snapshot.error}'),
              ),
            );
          }

          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(product.imageUrl),
                ),
                title: Text(product.name),
                subtitle: Text(
                  '${product.isActive ? 'Active' : 'Inactive'} · \$${product.price.toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/admin/products/${product.id}/edit'),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: products.length,
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
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                return parsed == null ? 'Enter a valid price' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an image URL'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelUrlController,
              decoration: const InputDecoration(labelText: 'Primary 3D Model URL'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a model URL'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriesController,
              decoration: const InputDecoration(
                labelText: 'Categories',
                helperText: 'Comma-separated, for example Chairs, Living Room',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isActive,
              title: const Text('Active'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Saving...' : 'Save Product'),
            ),
          ],
        ),
      ),
    );
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
