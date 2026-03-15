import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_nav_bar.dart';
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
        appBar: AppNavBar(
          title: 'Image history',
          showBackButton: true,
          onBack: () => context.pop(),
        ),
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
      appBar: AppNavBar(
        title: 'Image history',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 400 ? 2 : 1);
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _HistoryCard(item: items[index]);
                },
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
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Image.network(
                getGeneratedImageUrl(item.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.mutedClay.withValues(alpha: 0.15),
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
                  color: AppTheme.mutedClay.withValues(alpha: 0.2),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: AppTheme.deepUmber.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image unavailable',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.prompt,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(item.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepUmber,
                    fontSize: 12,
                  ),
                ),
              ],
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
