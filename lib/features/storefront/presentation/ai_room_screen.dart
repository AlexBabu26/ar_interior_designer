import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/app_nav_bar.dart';
import '../../../app/app_surfaces.dart';
import '../../../app/app_theme.dart';
import '../../auth/application/auth_provider.dart';
import '../../image_generation/data/generated_image_repository.dart';
import '../../image_generation/data/generated_image_storage.dart';
import '../../image_generation/data/nvidia_nim_image_repository.dart';
import '../../image_generation/domain/generated_image.dart';

class AIRoomScreen extends StatefulWidget {
  const AIRoomScreen({super.key});

  @override
  State<AIRoomScreen> createState() => _AIRoomScreenState();
}

class _AIRoomScreenState extends State<AIRoomScreen> {
  final _promptController = TextEditingController();
  final _repository = NvidiaNimImageRepository();

  static const _apiKey =
      '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';
  static const _proxyUrl = 'http://localhost:8080/generate_image';

  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? _imageBytes;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _imageBytes = null;
    });
    final result = await _repository.generateImage(
      apiKey: _apiKey,
      prompt: _promptController.text,
      proxyUrl: _proxyUrl,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _imageBytes = result.imageBytes != null
          ? Uint8List.fromList(result.imageBytes!)
          : null;
      _error = result.error;
    });
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null || _imageBytes == null || _imageBytes!.isEmpty) return;

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final imagePath = await saveGeneratedImageToStorage(userId, _imageBytes!);
      await context.read<GeneratedImageRepository>().insert(
        userId: userId,
        prompt: prompt,
        imagePath: imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to your history')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final repository = context.read<GeneratedImageRepository>();

    return Scaffold(
      appBar: const AppNavBar(title: 'AI Room Designer'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          AppPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader(
                  eyebrow: 'Inspiration',
                  title: 'Dream your space',
                  subtitle:
                      'Use our AI to visualize concepts, then find furniture that matches your generated style.',
                ),
                const SizedBox(height: 24),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!auth.isAuthenticated) ...[
                        AppMessagePanel(
                          title: 'Sign in to generate',
                          message:
                              'Keep your room ideas in your personalized history.',
                          icon: Icons.login,
                        ),
                      ] else ...[
                        TextField(
                          controller: _promptController,
                          decoration: const InputDecoration(
                            labelText: 'Describe your room',
                            hintText:
                                'e.g. A mid-century living room with large windows',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _generate,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              _isLoading ? 'Designing...' : 'Generate Design',
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        AppMessagePanel(
                          title: 'Generation failed',
                          message: _error!,
                          icon: Icons.error_outline_rounded,
                        ),
                      ],
                      if (_imageBytes != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save to my history',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppSectionHeader(
                  eyebrow: 'History',
                  title: 'Your past creations',
                  subtitle: 'Review and refine ideas you Have explored before.',
                ),
                const SizedBox(height: 18),
                if (!auth.isAuthenticated)
                  const AppMessagePanel(
                    title: 'Sign in to see history',
                    message: 'Your history is tied to your account.',
                    icon: Icons.history,
                  )
                else
                  FutureBuilder<List<GeneratedImage>>(
                    future: repository.getByUserId(auth.currentUser!.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const AppMessagePanel(
                          title: 'No designs yet',
                          message: 'Generate your first design above.',
                          icon: Icons.auto_awesome_outlined,
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            GeneratedImageCard(item: items[index]),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratedImageCard extends StatelessWidget {
  const GeneratedImageCard({super.key, required this.item});
  final GeneratedImage item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              getGeneratedImageUrl(item.imagePath),
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              item.prompt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
