import 'package:flutter/material.dart';
import '../../utils/url_helper.dart';

/// Displays a bookmark's preview image with graceful degradation:
///
/// 1. The stored preview `imageUrl`, resolved against the page URL.
/// 2. A page-screenshot service ([UrlHelper.fallbackPreviewUrl]) — covers
///    pages whose OpenGraph image could not be scraped (AWS WAF / Cloudflare
///    bot challenges respond 202/403 to any HTTP client) and pages whose
///    stored CDN link has expired (e.g. Instagram signed URLs).
/// 3. The static [fallback] widget.
///
/// Renders edge-to-edge (like `Image.network` with `BoxFit.cover` did in the
/// previous call sites) and should be placed inside a `StackFit.expand` stack
/// or similar sized box.
class BookmarkImage extends StatefulWidget {
  final String? imageUrl;
  final String url;
  final Widget fallback;

  const BookmarkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.imageUrl,
  });

  @override
  State<BookmarkImage> createState() => _BookmarkImageState();
}

class _BookmarkImageState extends State<BookmarkImage> {
  static const int _storedImage = 0;
  static const int _screenshot = 1;
  static const int _dead = 2;

  int _stage = _screenshot;

  @override
  void initState() {
    super.initState();
    _stage = _hasStoredImage ? _storedImage : _screenshot;
  }

  @override
  void didUpdateWidget(covariant BookmarkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.imageUrl != widget.imageUrl) {
      _stage = _hasStoredImage ? _storedImage : _screenshot;
    }
  }

  bool get _hasStoredImage =>
      widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

  void _advanceStage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (_stage >= _dead) {
          _stage = _dead;
        } else {
          _stage++;
        }
      });
    });
  }

  String _networkUrl() {
    switch (_stage) {
      case _storedImage:
        return UrlHelper.resolveImageUrl(widget.imageUrl, widget.url) ??
            widget.imageUrl!;
      case _screenshot:
        return UrlHelper.fallbackPreviewUrl(widget.url);
      default:
        return ''; // unreachable
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stage >= _dead) {
      return widget.fallback;
    }

    final url = _networkUrl();
    return Image.network(
      url,
      key: ValueKey(url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        _advanceStage();
        // One transparent frame while the next stage swaps in.
        return const SizedBox.expand();
      },
    );
  }
}
