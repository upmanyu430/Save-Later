import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FaviconImage extends StatelessWidget {
  final String? domain;
  final String? url;
  final double size;
  final double borderRadius;
  final Color? fallbackColor;

  const FaviconImage({
    super.key,
    this.domain,
    this.url,
    this.size = 22.0,
    this.borderRadius = 4.0,
    this.fallbackColor,
  });

  String? get resolvedDomain {
    if (domain != null && domain!.trim().isNotEmpty) {
      return domain!.trim();
    }
    if (url != null && url!.trim().isNotEmpty) {
      final clean = url!.trim().startsWith('http://') || url!.trim().startsWith('https://')
          ? url!.trim()
          : 'https://${url!.trim()}';
      try {
        final host = Uri.parse(clean).host;
        if (host.isNotEmpty) return host;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = resolvedDomain;
    final fallback = Icon(
      Icons.public,
      size: size,
      color: fallbackColor ?? AppTheme.border,
    );

    if (d == null || d.isEmpty) {
      return fallback;
    }

    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$d&sz=128';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        faviconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
