import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_surfaces.dart';

class ARSceneScreen extends StatelessWidget {
  const ARSceneScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  Widget build(BuildContext context) {
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
}
