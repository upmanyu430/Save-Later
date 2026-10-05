import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String urlString) async {
  final uri = Uri.parse(urlString);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint(e.toString());
  }
}
