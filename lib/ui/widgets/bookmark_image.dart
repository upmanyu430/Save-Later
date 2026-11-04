import 'dart:async';
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
/// While network images are loading, [fallback] is displayed underneath
/// with an immediate appearance, and the network image smoothly fades in
/// when decoded. A timeout ensures slow or stalled screenshot services
/// gracefully fall back to [fallback] rather than hanging.
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
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _stage = _hasStoredImage ? _storedImage : _screenshot;
    _scheduleTimeout();
  }

  @override
  void didUpdateWidget(covariant BookmarkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.imageUrl != widget.imageUrl) {
      _timeoutTimer?.cancel();
      _stage = _hasStoredImage ? _storedImage : _screenshot;
      _scheduleTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  bool get _hasStoredImage =>
      widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

  void _scheduleTimeout() {
    _timeoutTimer?.cancel();
    if (_stage >= _dead) return;

    final timeoutDuration = _stage == _storedImage
        ? const Duration(seconds: 8)
        : const Duration(seconds: 10);

    _timeoutTimer = Timer(timeoutDuration, () {
      if (mounted && _stage < _dead) {
        _advanceStage();
      }
    });
  }

  void _advanceStage() {
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (_stage >= _dead) {
          _stage = _dead;
        } else {
          _stage++;
          _scheduleTimeout();
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
    if (url.trim().isEmpty) {
      return widget.fallback;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always display the fallback underneath immediately so no grey void is ever visible
        widget.fallback,
        Image.network(
          url,
          key: ValueKey(url),
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              _timeoutTimer?.cancel();
            }
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (_, __, ___) {
            _advanceStage();
            // Fallback is already displayed underneath in the stack
            return const SizedBox.expand();
          },
        ),
      ],
    );
  }
}
