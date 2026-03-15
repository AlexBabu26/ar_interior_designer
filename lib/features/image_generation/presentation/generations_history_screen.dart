import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../data/generated_image_repository.dart';
import '../data/generated_image_storage.dart';
import '../domain/generated_image.dart';
import '../../auth/application/auth_provider.dart';

class GenerationsHistoryScreen extends StatelessWidget {
  const GenerationsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Image history')),
        body: const Center(
          child: AppMessagePanel(
            title: 'Sign in required',
            message: 'Sign in to see your generated images.',
            icon: Icons.login,
          ),
        ),
      );
    }

    final repository = context.read<GeneratedImageRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Image history')),
      body: FutureBuilder<List<GeneratedImage>>(
        future: repository.getByUserId(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'Unable to load history',
                  message: '${snapshot.error}',
                  icon: Icons.error_outline_rounded,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: AppPageWidth(
                child: AppMessagePanel(
                  title: 'No generated images yet',
                  message:
                      'Generate an image from the home page and save it to see it here.',
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return AppPageWidth(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _HistoryCard(item: items[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final GeneratedImage item;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.prompt,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepUmber,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              getGeneratedImageUrl(item.imagePath),
              fit: BoxFit.contain,
              width: double.infinity,
              height: 240,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.mutedClay.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Image unavailable',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
