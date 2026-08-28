# 005 — Initial Load Card Stagger Entrance

- **Status**: TODO
- **Commit**: v1.0.0
- **Severity**: LOW
- **Category**: Group entrance & Delight
- **Estimated scope**: 1 file (`lib/dashboard.dart`), ~35 lines

## Problem

In `lib/dashboard.dart:890`, when the application launches or finishes loading data, the entire column of Liquid Glass cards appears statically with no entrance transition. On macOS, a subtle cascaded stagger entrance gives an elevated, native feel.

```dart
/* lib/dashboard.dart:890 — current */
SingleChildScrollView(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...
          compactMetricsBar,
          const SizedBox(height: 12),
          compactPrayerTimesStrip,
          const SizedBox(height: 14),
          quranCard,
          ...
```

## Target

Introduce a lightweight `_StaggerItem` wrapper:
- Triggered once on initial load.
- Stagger delay: 35ms per sequential item.
- Motion: `translateY(12px) → 0px` and `opacity: 0.0 → 1.0` over 240ms with `Curves.easeOutCubic`.
- Total budget: ~340ms across all 4 sections. Non-blocking to user input.

```dart
/* target */
class _StaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerItem({required this.index, required this.child});

  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 35 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
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
```

## Repo conventions to follow

- Delay: 35ms per item.
- Duration: 240ms per item.
- Easing: `Curves.easeOutCubic`.

## Steps

1. In `lib/dashboard.dart`, add the `_StaggerItem` helper class.
2. Wrap `compactMetricsBar` (`index: 0`), `compactPrayerTimesStrip` (`index: 1`), `quranCard` (`index: 2`), and the bottom row/column (`index: 3`) with `_StaggerItem`.

## Boundaries

- Do NOT re-animate on regular state updates (e.g. 15s timer ticks).
- Stagger must run on initial mount only.

## Verification

- **Mechanical**: `flutter test` passes.
- **Feel check**:
  - Launch app from closed state.
  - Cards gracefully settle into place sequentially in under 350ms.
