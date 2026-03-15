import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../data/generated_image_storage.dart';
import '../data/generated_image_repository.dart';
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
          FutureBuilder<String>(
            future: resolveGeneratedImagePath(item.imagePath),
            builder: (context, pathSnapshot) {
              if (!pathSnapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final file = File(pathSnapshot.data!);
              if (!file.existsSync()) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.mutedClay.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Image file not found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 240,
                ),
              );
            },
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
