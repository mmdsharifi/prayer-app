import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/prayer_schedule.dart' show faDigits;

/// Digital Live Clock with Pulsating Animated Colon `:`
class LiveClockWidget extends StatefulWidget {
  final DateTime? fixedTime;
  final bool isDark;

  const LiveClockWidget({
    super.key,
    this.fixedTime,
    this.isDark = true,
  });

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _colonOpacity;
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.fixedTime ?? DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _colonOpacity = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.fixedTime == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = widget.fixedTime ?? _currentTime;
    final hourStr = faDigits(time.hour.toString().padLeft(2, '0'));
    final minStr = faDigits(time.minute.toString().padLeft(2, '0'));
    final isDark = widget.isDark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 14.0,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            hourStr,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          FadeTransition(
            opacity: _colonOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                ':',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Text(
            minStr,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
