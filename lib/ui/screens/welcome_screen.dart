import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_constants.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';

/// First-run neo-brutalist onboarding screen shown when `hasSeenWelcome` is false.
class WelcomeScreen extends StatefulWidget {
  final bool hapticFeedback;
  final VoidCallback? onCompleted;

  const WelcomeScreen({
    super.key,
    this.hapticFeedback = true,
    this.onCompleted,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isSubmitting = false;

  Future<void> _handleGetStarted() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcome', true);
    } catch (error) {
      debugPrint('Unable to persist hasSeenWelcome: $error');
    }
    if (!mounted) return;
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingXl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppDimensions.paddingXl * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Centered brand emblem with neo-brutalist hard shadow
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.shadow,
                                    offset: const Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/splash_emblem.png',
                                width: 76,
                                height: 76,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => NeoBox(
                                  color: AppTheme.accent,
                                  borderColor: AppTheme.border,
                                  shadowColor: colors.shadow,
                                  borderRadius: 18,
                                  shadowOffset: 0,
                                  padding: EdgeInsets.zero,
                                  child: const Center(
                                    child: Icon(
                                      Icons.bookmark_rounded,
                                      size: 40,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingXl),
                            Text(
                              l10n.welcomeTitle,
                              style: GoogleFonts.gabarito(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                height: 1.08,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingMd),
                            Text(
                              l10n.welcomeSubtitle,
                              style: GoogleFonts.gabarito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingXl),
                            _WelcomeFeatureRow(
                              icon: Icons.bolt_rounded,
                              badgeColor: AppTheme.accent,
                              text: l10n.welcomeFeatureQuickSave,
                            ),
                            const SizedBox(height: AppDimensions.paddingMd),
                            _WelcomeFeatureRow(
                              icon: Icons.folder_copy_outlined,
                              badgeColor: AppTheme.secondary,
                              text: l10n.welcomeFeatureOrganize,
                            ),
                            const SizedBox(height: AppDimensions.paddingMd),
                            _WelcomeFeatureRow(
                              icon: Icons.lock_outline_rounded,
                              badgeColor: AppTheme.primary,
                              text: l10n.welcomeFeaturePrivate,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),
                        NeoButton(
                          onPressed: _isSubmitting ? null : _handleGetStarted,
                          color: AppTheme.accent,
                          borderColor: AppTheme.border,
                          borderRadius: AppDimensions.radiusMd,
                          borderWidth: AppDimensions.borderWidthLg,
                          shadowOffset: AppDimensions.shadowOffsetXl,
                          enableFeedback: widget.hapticFeedback,
                          minTouchTargetSize: 54.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingXl,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.getStarted,
                                style: GoogleFonts.gabarito(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: colors.onAccent,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingSm),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: colors.onAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeFeatureRow extends StatelessWidget {
  final IconData icon;
  final Color badgeColor;
  final String text;

  const _WelcomeFeatureRow({
    required this.icon,
    required this.badgeColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return NeoBox(
      color: colors.card,
      borderRadius: AppDimensions.radiusMd,
      borderWidth: AppDimensions.borderWidthMd,
      shadowOffset: AppDimensions.shadowOffsetLg,
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: AppTheme.border,
                width: AppDimensions.borderWidthSm,
              ),
            ),
            child: Icon(icon, size: 22, color: colors.onAccent),
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.gabarito(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
