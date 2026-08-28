# 002 — Directional Ayah Carousel Slide Transition

- **Status**: TODO
- **Commit**: v1.0.0
- **Severity**: HIGH
- **Category**: Spatial consistency
- **Estimated scope**: 1 file (`lib/dashboard.dart`), ~20 lines

## Problem

In `lib/dashboard.dart:1223`, verse transitions inside `QuranJuzCard` use an `AnimatedSwitcher` that always slides up from bottom (`Offset(0.0, 0.04)`), regardless of whether the user pressed "Next Ayah" or "Previous Ayah". This violates spatial consistency because horizontal paging controls should push content in the direction of the interaction.

```dart
/* lib/dashboard.dart:1223 — current */
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  ),
  child: KeyedSubtree(
    key: ValueKey<int>(safeIdx),
    child: Column(...),
  ),
)
```

## Target

Track navigation direction (`bool _isForward = true`). When advancing to the next verse (Lego step forward), slide in from right to left (`Offset(0.08, 0.0)` in RTL); when moving backward, slide in from left to right (`Offset(-0.08, 0.0)`). Use a crisp 220ms duration with `Curves.easeOutCubic` and smooth opacity bridge (`0.0 → 1.0`).

```dart
/* target */
bool _isForward = true;

// On Next:
setState(() {
  _isForward = true;
  _ayahIndex = (_ayahIndex + 1) % totalVerses;
});

// On Previous:
setState(() {
  _isForward = false;
  _ayahIndex = (_ayahIndex - 1 + totalVerses) % totalVerses;
});

// In build:
AnimatedSwitcher(
  duration: const Duration(milliseconds: 220),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(_isForward ? 0.06 : -0.06, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  ),
  child: KeyedSubtree(
    key: ValueKey<int>(safeIdx),
    child: Column(...),
  ),
)
```

## Repo conventions to follow

- Duration: 220ms (standard micro-transition inside modal/card).
- Easing: `Curves.easeOutCubic`.
- RTL coordinate awareness.

## Steps

1. In `_QuranJuzCardState` in `lib/dashboard.dart`, add `bool _isForward = true;`.
2. Update the Next and Previous `IconButton` onPressed callbacks and the footer button callback to set `_isForward`.
3. Update `transitionBuilder` in `AnimatedSwitcher` to use directional X offsets.

## Boundaries

- Do NOT alter Juz verse parsing or data structures.
- Do NOT change Quran font or text hierarchy.

## Verification

- **Mechanical**: `flutter test` passes.
- **Feel check**:
  - Click "آیه بعدی" -> Verse slides gracefully from right.
  - Click "آیه قبلی" -> Verse slides gracefully from left.
  - Rapid clicking does not jitter or drop frames.
