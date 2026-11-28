import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A GPU-composited, interruptible pill toggle switch matching Save Later's
/// tactile neo-brutalist UI language.
class NeoSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeTrackColor;
  final Color? inactiveTrackColor;
  final Color thumbColor;
  final String? semanticLabel;

  const NeoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor = const Color(0xFF26D5A8),
    this.inactiveTrackColor,
    this.thumbColor = Colors.white,
    this.semanticLabel,
  });

  @override
  State<NeoSwitch> createState() => _NeoSwitchState();
}

class _NeoSwitchState extends State<NeoSwitch> with TickerProviderStateMixin {
  static const double _trackWidth = 52.0;
  static const double _trackHeight = 32.0;
  static const double _thumbSize = 26.0;
  static const double _thumbInset = 3.0;
  static const double _maxTravel = _trackWidth - _thumbSize - (_thumbInset * 2);
  static const Cubic _switchCurve = Cubic(0.23, 1.0, 0.32, 1.0);

  late final AnimationController _toggleController;
  late final Animation<double> _positionAnimation;
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  bool get _isEnabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _positionAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: _switchCurve,
      reverseCurve: _switchCurve,
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _pressAnimation = CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
      reverseCurve: _switchCurve,
    );
  }

  @override
  void didUpdateWidget(covariant NeoSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _toggleController.value = widget.value ? 1.0 : 0.0;
      } else if (widget.value) {
        _toggleController.forward();
      } else {
        _toggleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_isEnabled) return;
    _pressController.reverse();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedInactive = widget.inactiveTrackColor ?? colors.divider;

    return Semantics(
      toggled: widget.value,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: _isEnabled ? 1.0 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _isEnabled ? (_) => _pressController.forward() : null,
          onTapCancel: _isEnabled ? () => _pressController.reverse() : null,
          onTap: _handleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            child: Center(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _positionAnimation,
                    _pressAnimation,
                  ]),
                  builder: (context, child) {
                    final t = _positionAnimation.value;
                    final press = _pressAnimation.value;
                    final trackColor = Color.lerp(
                      resolvedInactive,
                      widget.activeTrackColor,
                      t,
                    )!;
                    final thumbScale = 1.0 - (press * 0.08);
                    final dx = _thumbInset + (_maxTravel * t);

                    return Container(
                      width: _trackWidth,
                      height: _trackHeight,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(_trackHeight / 2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.scale(
                            scale: thumbScale,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          offset: const Offset(0, 1.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
