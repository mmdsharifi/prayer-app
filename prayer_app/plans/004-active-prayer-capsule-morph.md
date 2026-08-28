# 004 — Active Prayer Capsule Coordinated Morph

- **Status**: TODO
- **Commit**: v1.0.0
- **Severity**: MEDIUM
- **Category**: State indication & Spatial consistency
- **Estimated scope**: 1 file (`lib/dashboard.dart`), ~25 lines

## Problem

In `lib/dashboard.dart:711`, when the active prayer changes (e.g. Fajr -> Sunrise transition), `AnimatedContainer` alters individual cell colors over 250ms, but lacks a cohesive pulse or indicator focus to clearly communicate the newly active prayer state.

```dart
/* lib/dashboard.dart:711 — current */
return AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  padding: EdgeInsets.symmetric(
    horizontal: compact ? 7 : 12,
    vertical: compact ? 6 : 8,
  ),
  decoration: active
      ? BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.32),
              const Color(0xFF059669).withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF34D399).withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        )
      : null,
  child: Column(...),
);
```

## Target

Enhance the `AnimatedContainer` transition to 280ms with `Curves.easeOutCubic`, and add an `AnimatedScale` or synchronized scale highlight (`scale: active ? 1.02 : 1.0`) so the active prayer capsule physically lifts and highlights smoothly when active.

```dart
/* target */
return AnimatedScale(
  scale: active ? 1.02 : 1.0,
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeOutCubic,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 7 : 12,
      vertical: compact ? 6 : 8,
    ),
    decoration: active
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.32),
                const Color(0xFF059669).withValues(alpha: 0.22),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : null,
    child: Column(...),
  ),
);
```

## Repo conventions to follow

- Duration: 280ms (`Curves.easeOutCubic`).
- Color: Emerald palette (`#10B981`, `#34D399`).

## Steps

1. In `lib/dashboard.dart`, wrap `AnimatedContainer` inside `AnimatedScale(scale: active ? 1.02 : 1.0, duration: 280ms, curve: Curves.easeOutCubic)`.
2. Ensure duration in `AnimatedContainer` is 280ms with `Curves.easeOutCubic`.

## Boundaries

- Do NOT change prayer calculation logic.
- Do NOT alter table typography or cell padding constraints.

## Verification

- **Mechanical**: `flutter test` passes.
- **Feel check**:
  - Verify active prayer cell smoothly lifts with a subtle emerald bloom when time boundary crosses.
