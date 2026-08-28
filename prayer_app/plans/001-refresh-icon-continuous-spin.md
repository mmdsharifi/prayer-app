# 001 — Refresh Button Continuous Rotation Transition

- **Status**: TODO
- **Commit**: v1.0.0
- **Severity**: HIGH
- **Category**: State indication & Preventing a jarring change
- **Estimated scope**: 1 file (`lib/dashboard.dart`), ~25 lines

## Problem

In `lib/dashboard.dart:475`, when `_isRefreshing` flips to true, the refresh icon (`CupertinoIcons.arrow_2_circlepath`) abruptly disappears and is replaced by a `CircularProgressIndicator`. When fetching completes, the spinner suddenly disappears and the icon snaps back into place. This causes visual layout flutter in the macOS header.

```dart
/* lib/dashboard.dart:475 — current */
IconButton(
  tooltip: 'به‌روزرسانی (Refresh • ⌘R)',
  icon: _isRefreshing
      ? const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 16),
  onPressed: _isRefreshing ? null : _refreshAll,
)
```

## Target

Keep the `CupertinoIcons.arrow_2_circlepath` icon mounted continuously. When `_isRefreshing` is true, drive it with a smooth continuous rotation (`RotationTransition` driven by an `AnimationController` repeating every 750ms with `Curves.linear`). When refresh completes, allow the rotation to complete its cycle and decelerate smoothly (250ms `Curves.easeOutCubic`) rather than popping.

```dart
/* target */
class _RefreshButton extends StatefulWidget {
  final bool isRefreshing;
  final VoidCallback? onPressed;
  const _RefreshButton({required this.isRefreshing, this.onPressed});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(_RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.repeat();
      } else {
        _controller.animateTo(1.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic).then((_) {
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
      icon: RotationTransition(
        turns: _controller,
        child: const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 16),
      ),
      onPressed: widget.isRefreshing ? null : widget.onPressed,
    );
  }
}
```

## Repo conventions to follow

- Flutter standard `SingleTickerProviderStateMixin` with `AnimationController`.
- Easing: `Curves.easeOutCubic` on settling.
- Color: `Colors.white` matching macOS dark header buttons.

## Steps

1. In `lib/dashboard.dart`, add the `_RefreshButton` private widget class.
2. Replace lines 473–484 in `lib/dashboard.dart` with `_RefreshButton(isRefreshing: _isRefreshing, onPressed: _refreshAll)`.

## Boundaries

- Do NOT alter `_refreshAll` logic or async data fetching.
- Do NOT touch other header buttons or layout constraints.

## Verification

- **Mechanical**: `flutter analyze` passes with 0 errors; `flutter test` passes all tests.
- **Feel check**:
  - Click refresh button or press ⌘R.
  - Confirm the icon spins smoothly with no widget popping or layout shift.
  - When network request finishes, confirm the icon decelerates to upright position smoothly.
