# 003 — Liquid Glass Card Tactile Micro-Press Feedback

- **Status**: TODO
- **Commit**: v1.0.0
- **Severity**: MEDIUM
- **Category**: Feedback & Physicality
- **Estimated scope**: 1 file (`lib/dashboard.dart`), ~30 lines

## Problem

In `lib/dashboard.dart:35`, `LiquidGlassCard` widgets that accept an `onTap` callback trigger an `InkWell` splash, but have no physical scale feedback on pointer down. On macOS desktop, a subtle interactive compression (`scale: 0.98`) gives native tactile confirmation that the card was pressed.

```dart
/* lib/dashboard.dart:35 — current */
child: InkWell(
  onTap: onTap,
  borderRadius: br,
  splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
  highlightColor: Colors.white.withValues(alpha: 0.05),
  child: Container(
    width: double.infinity,
    padding: padding,
    ...
```

## Target

When `onTap != null`, wrap the card container in a pointer-down scale feedback listener with 140ms `Curves.easeOutCubic` curve:
- On PointerDown: `scale: 0.985`
- On PointerUp / PointerCancel: `scale: 1.0`

```dart
/* target */
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
              onHighlightChanged: widget.onTap != null ? (val) => setState(() => _isPressed = val) : null,
              borderRadius: br,
              splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Container(
                width: double.infinity,
                padding: widget.padding,
                ...
```

## Repo conventions to follow

- Duration: 140ms (press feedback budget: 100–160ms).
- Scale: `0.985` (subtle restraint for desktop UI).
- Easing: `Curves.easeOutCubic`.

## Steps

1. Convert `LiquidGlassCard` to a `StatefulWidget` in `lib/dashboard.dart`.
2. Add `_isPressed` state and bind `onHighlightChanged` to `InkWell`.
3. Wrap `ClipRRect` with `AnimatedScale(scale: ..., duration: 140ms, curve: Curves.easeOutCubic)`.

## Boundaries

- Do NOT change gradient colors, border width, or shadows of `LiquidGlassCard`.
- Apply scale only when `onTap != null` (cards without onTap stay strictly static).

## Verification

- **Mechanical**: `flutter test` passes.
- **Feel check**:
  - Click on interactive cards (e.g. Next Prayer card or widget button).
  - Verify subtle 0.985 compression on mouse down and instant smooth bounce back on release.
