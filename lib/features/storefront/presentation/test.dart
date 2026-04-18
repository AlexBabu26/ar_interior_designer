Widget build(BuildContext context) {
  return Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.go('/catalog/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image: fixed aspect ratio — never grows unbounded
          AspectRatio(
            aspectRatio: 1.1,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.mutedClay.withValues(alpha: 0.2),
                    image: DecorationImage(
                      image: NetworkImage(product.imageUrlResolved),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product.isOutOfStock)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'STOCK OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content: auto-height, no expanding
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categorySummary(product),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.burntSienna,
                    letterSpacing: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.deepUmber),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      formatCurrency(product.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_outward_rounded, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
