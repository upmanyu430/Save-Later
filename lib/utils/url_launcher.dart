import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openUrl(String urlString, {BuildContext? context}) async {
  final trimmed = urlString.trim();
  if (trimmed.isEmpty) {
    debugPrint('Cannot launch empty URL');
    if (context != null && context.mounted) {
      _showErrorSnackBar(context);
    }
    return false;
  }

  try {
    String normalized = trimmed;
    if (!normalized.startsWith(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:'))) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty)) {
      debugPrint('Cannot parse valid URI: $urlString');
      if (context != null && context.mounted) {
        _showErrorSnackBar(context);
      }
      return false;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      debugPrint('Failed to launch URL: $urlString');
      if (context != null && context.mounted) {
        _showErrorSnackBar(context);
      }
      return false;
    }

    return true;
  } catch (e) {
    debugPrint('Error launching $urlString: $e');
    if (context != null && context.mounted) {
      _showErrorSnackBar(context);
    }
    return false;
  }
}

void _showErrorSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final message = l10n?.couldNotOpenLink ?? 'Could not open link';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

