import 'dart:async' show Timer;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ─────────────────────── Liquid Glass Card & Foundations ───────────────────────

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool isDark;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.isDark = true,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(18);
    final isDark = widget.isDark;

    return AnimatedScale(
      scale: (_isPressed && widget.onTap != null) ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: widget.onTap != null
                  ? (val) => setState(() => _isPressed = val)
                  : null,
              borderRadius: br,
              splashColor: isDark
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                  : const Color(0xFF0284C7).withValues(alpha: 0.08),
              highlightColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              child: Container(
                width: double.infinity,
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.45, 1.0],
                          colors: [
                            const Color(0xFF1E293B).withValues(alpha: 0.62), // Translucent Slate-Navy Glass Sheen
                            const Color(0xFF0F172A).withValues(alpha: 0.70), // Midnight Blue Glass Body
                            const Color(0xFF070D1A).withValues(alpha: 0.78), // Deep Obsidian Blue Base
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.50, 1.0],
                          colors: [
                            const Color(0xFFFFFFFF).withValues(alpha: 0.88), // Pure Crisp White Glass Sheen
                            const Color(0xFFF8FAFC).withValues(alpha: 0.80), // Airy Light Frosted Body
                            const Color(0xFFEFF6FF).withValues(alpha: 0.74), // Subtle Morning Sky Tint Base
                          ],
                        ),
                  borderRadius: br,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF7DD3FC).withValues(alpha: 0.28) // Refractive Ice-Blue Glass Rim
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.95), // Specular White Glass Rim
                    width: isDark ? 0.9 : 1.2,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 26,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            blurRadius: 18,
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Backward-compatible alias
class GlassCard extends LiquidGlassCard {
  const GlassCard({
    super.key,
    required super.child,
    super.padding,
    super.isDark,
    super.onTap,
  });
}

class DashboardRefreshButton extends StatefulWidget {
  final bool isRefreshing;
  final VoidCallback? onPressed;
  final bool isDark;

  const DashboardRefreshButton({
    super.key,
    required this.isRefreshing,
    this.onPressed,
    this.isDark = true,
  });

  @override
  State<DashboardRefreshButton> createState() => _DashboardRefreshButtonState();
}

class _DashboardRefreshButtonState extends State<DashboardRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isRefreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(DashboardRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.repeat();
      } else {
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        ).then((_) {
          if (mounted) _controller.reset();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'به‌روزرسانی (Refresh • ⌘R)',
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      icon: RotationTransition(
        turns: _controller,
        child: Icon(
          CupertinoIcons.arrow_2_circlepath,
          color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
          size: 15,
        ),
      ),
      onPressed: widget.isRefreshing ? null : widget.onPressed,
    );
  }
}

class StaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerItem({super.key, required this.index, required this.child});

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.index == 0) {
      _ctrl.forward();
    } else {
      _timer = Timer(Duration(milliseconds: 35 * widget.index), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final bool isDark;

  const CardTitle(
    this.title, {
    super.key,
    required this.icon,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    size: 14.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      );
}
