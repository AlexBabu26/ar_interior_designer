import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppPageWidth extends StatelessWidget {
  const AppPageWidth({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
    this.centered = false,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.8,
              color: AppTheme.burntSienna,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        if (eyebrow != null) const SizedBox(height: 8),
        Text(
          title,
          style: textTheme.headlineLarge,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: textTheme.bodyLarge?.copyWith(color: AppTheme.deepUmber),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class AppMessagePanel extends StatelessWidget {
  const AppMessagePanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.chair_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.parchment,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.richCharcoal),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: AppPageWidth(
          padding: EdgeInsets.zero,
          child: AppPanel(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }
}
