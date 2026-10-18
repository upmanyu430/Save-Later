import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FaviconImage extends StatefulWidget {
  final String? domain;
  final String? url;
  final double size;
  final double borderRadius;
  final Color? fallbackColor;
  final Widget? fallback;

  const FaviconImage({
    super.key,
    this.domain,
    this.url,
    this.size = 22.0,
    this.borderRadius = 4.0,
    this.fallbackColor,
    this.fallback,
  });

  @override
  State<FaviconImage> createState() => _FaviconImageState();
}

class _FaviconImageState extends State<FaviconImage> {
  int _serviceIndex = 0;
  String? _currentDomain;

  static String? cleanDomain(String? domain, String? url) {
    if (domain != null && domain.trim().isNotEmpty) {
      var d = domain.trim().toLowerCase();
      if (d.startsWith('https://')) d = d.substring(8);
      if (d.startsWith('http://')) d = d.substring(7);
      if (d.contains('/')) d = d.split('/')[0];
      if (d.contains(':')) d = d.split(':')[0];
      if (d.isNotEmpty) return d;
    }
    if (url != null && url.trim().isNotEmpty) {
      final clean = url.trim().startsWith('http://') || url.trim().startsWith('https://')
          ? url.trim()
          : 'https://${url.trim()}';
      try {
        final uri = Uri.parse(clean);
        if (uri.host.isNotEmpty) return uri.host.toLowerCase();
      } catch (_) {}
    }
    return null;
  }

  List<String> _getFaviconUrls(String domain) {
    String? rootDomain;
    final parts = domain.split('.');
    if (parts.length > 2) {
      rootDomain = parts.sublist(parts.length - 2).join('.');
    }

    final urls = <String>[
      'https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$domain&size=128',
      'https://icons.duckduckgo.com/ip3/$domain.ico',
      'https://www.google.com/s2/favicons?domain=$domain&sz=128',
    ];

    if (rootDomain != null && rootDomain.isNotEmpty) {
      urls.add('https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$rootDomain&size=128');
      urls.add('https://www.google.com/s2/favicons?domain=$rootDomain&sz=128');
    }

    urls.add('https://$domain/favicon.ico');
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final domain = cleanDomain(widget.domain, widget.url);
    if (domain != _currentDomain) {
      _currentDomain = domain;
      _serviceIndex = 0;
    }

    final defaultFallback = widget.fallback ??
        Icon(
          Icons.public,
          size: widget.size,
          color: widget.fallbackColor ?? AppTheme.border,
        );

    if (domain == null || domain.isEmpty) {
      return defaultFallback;
    }

    final urls = _getFaviconUrls(domain);
    if (_serviceIndex >= urls.length) {
      return defaultFallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        urls[_serviceIndex],
        key: ValueKey('${domain}_$_serviceIndex'),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _serviceIndex < urls.length) {
              setState(() {
                _serviceIndex++;
              });
            }
          });
          return defaultFallback;
        },
      ),
    );
  }
}
