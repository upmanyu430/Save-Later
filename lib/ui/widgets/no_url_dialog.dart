import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';

void showNoUrlDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NeoBox(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          borderRadius: 12,
          borderWidth: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFF9A826), size: 48), // Accent/Orange color
              const SizedBox(height: 20),
              const Text(
                'No URL',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.border),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please enter a link to save',
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  color: AppTheme.accent,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.border),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
