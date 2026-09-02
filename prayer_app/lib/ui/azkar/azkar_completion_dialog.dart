import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ─────────────────────── Confetti Particle System ───────────────────────

class ConfettiParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rotation;
  final double vRot;
  final bool isCircle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.vRot,
    required this.isCircle,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      // Physical motion: initial burst + gravity + horizontal drift
      final t = progress * 2.2;
      final currentX = size.width / 2 + (p.vx * t * 140) + math.sin(t * 4 + p.rotation) * 15;
      final currentY = size.height * 0.28 + (p.vy * t * 110) + (0.5 * 380 * t * t);
      final currentRot = p.rotation + p.vRot * progress * 6;

      if (currentY > size.height + 40 || currentX < -40 || currentX > size.width + 40) {
        continue;
      }

      paint.color = p.color.withValues(alpha: opacity * 0.92);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.4,
          height: p.size * 0.75,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────── Azkar Completion Celebratory Dialog ───────────────────────

class AzkarCompletionDialog extends StatefulWidget {
  final String categoryTitle;
  final bool isDark;
  final VoidCallback onReturnToDashboard;
  final VoidCallback? onReviewAzkar;

  const AzkarCompletionDialog({
    super.key,
    required this.categoryTitle,
    required this.isDark,
    required this.onReturnToDashboard,
    this.onReviewAzkar,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryTitle,
    required bool isDark,
    required VoidCallback onReturnToDashboard,
    VoidCallback? onReviewAzkar,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.45),
      builder: (dialogCtx) => AzkarCompletionDialog(
        categoryTitle: categoryTitle,
        isDark: isDark,
        onReturnToDashboard: onReturnToDashboard,
        onReviewAzkar: onReviewAzkar,
      ),
    );
  }

  @override
  State<AzkarCompletionDialog> createState() => _AzkarCompletionDialogState();
}

class _AzkarCompletionDialogState extends State<AzkarCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late List<ConfettiParticle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    const colors = [
      Color(0xFF10B981), // Emerald
      Color(0xFF38BDF8), // Sky Blue
      Color(0xFFF59E0B), // Gold / Amber
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFF34D399), // Mint
      Color(0xFFFBBF24), // Yellow
      Colors.white,
    ];

    _particles = List.generate(65, (i) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 0.4 + _rng.nextDouble() * 1.8;
      return ConfettiParticle(
        x: 0,
        y: 0,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 1.2, // bias upwards initially
        size: 5.0 + _rng.nextDouble() * 7.0,
        color: colors[_rng.nextInt(colors.length)],
        rotation: _rng.nextDouble() * math.pi * 2,
        vRot: (_rng.nextDouble() - 0.5) * 8.0,
        isCircle: i % 3 == 0,
      );
    });

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti Canvas in the background
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, _) => CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _animCtrl.value,
                ),
              ),
            ),
          ),
        ),

        // Dialog Content
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E293B).withValues(alpha: 0.92),
                              const Color(0xFF0F172A).withValues(alpha: 0.95),
                              const Color(0xFF070D1A).withValues(alpha: 0.98),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.96),
                              const Color(0xFFF8FAFC).withValues(alpha: 0.92),
                              const Color(0xFFEFF6FF).withValues(alpha: 0.94),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF34D399).withValues(alpha: 0.35)
                          : const Color(0xFF10B981).withValues(alpha: 0.40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing Festive Icon
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Main Title: الحمدلله
                      Text(
                        '«الْحَمْدُ لِلَّٰهِ»',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'اذکار امروز خوانده شده',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      Text(
                        'تمام ${widget.categoryTitle} به لطف خداوند با موفقیت و تسبیح به پایان رسید.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Spiritual Ayah Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.20),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Action Button 1: بازگشت به صفحه اصلی (Primary)
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop(); // Close dialog
                                widget.onReturnToDashboard();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.house_fill, color: Colors.white, size: 17),
                                    SizedBox(width: 8),
                                    Text(
                                      'بازگشت به صفحه اصلی',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Button 2: مرور مجدد ذکرها (Secondary)
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(); // Close dialog
                              widget.onReviewAzkar?.call();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text(
                                  'مرور مجدد ذکرها',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
