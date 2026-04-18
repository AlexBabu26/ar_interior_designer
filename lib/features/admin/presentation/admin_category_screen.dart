import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../catalog/data/product_repository.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  late Future<List<String>> _categoriesFuture;
  final _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = context.read<ProductRepository>().getCategories();
    });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    try {
      await context.read<ProductRepository>().addCategory(name);
      _newCategoryController.clear();
      _refreshCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    }
  }

  Future<void> _editCategory(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      try {
        await context.read<ProductRepository>().updateCategory(oldName, newName);
        _refreshCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"? This will NOT remove it from existing products but will remove it from the master list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.burntSienna),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ProductRepository>().deleteCategory(name);
        _refreshCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(
        title: 'Manage Categories',
        showBackButton: true,
      ),
      body: AppPageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            AppSectionHeader(
              eyebrow: 'Configuration',
              title: 'Product Categories',
              subtitle: 'Manage the master list of categories available for your collection.',
            ),
            const SizedBox(height: 24),
            AppPanel(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(
                        hintText: 'New category name (e.g. Garden)',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.burntSienna),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return const Center(
                      child: Text('No categories defined yet.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return AppPanel(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(cat),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editCategory(cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black54),
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
