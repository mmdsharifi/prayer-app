# Animation Improvement Plans

This directory contains self-contained, recipe-exact implementation plans for animation and motion improvements in the Prayer App, created via the `improve-animations` workflow based on Emil Kowalski's motion design principles.

## Plans Index

| # | Plan | Severity | Category | Status |
| :--- | :--- | :--- | :--- | :--- |
| **001** | [Refresh Button Continuous Rotation Transition](001-refresh-icon-continuous-spin.md) | **HIGH** | State indication & Layout stability | `DONE` |
| **002** | [Directional Ayah Carousel Slide Transition](002-directional-ayah-slide-transition.md) | **HIGH** | Spatial consistency | `DONE` |
| **003** | [Liquid Glass Card Tactile Micro-Press Feedback](003-liquid-card-press-feedback.md) | **MEDIUM** | Feedback & Physicality | `DONE` |
| **004** | [Active Prayer Capsule Coordinated Morph](004-active-prayer-capsule-morph.md) | **MEDIUM** | State indication & Spatial consistency | `DONE` |
| **005** | [Initial Load Card Stagger Entrance](005-initial-load-card-stagger.md) | **LOW** | Group entrance & Delight | `DONE` |

## Recommended Execution Order

1. **Plan 001** (`001-refresh-icon-continuous-spin.md`) — Eliminates header layout flutter during data refreshes.
2. **Plan 002** (`002-directional-ayah-slide-transition.md`) — Fixes horizontal spatial paging logic for Quran readings.
3. **Plan 003** (`003-liquid-card-press-feedback.md`) — Adds desktop tactile micro-compression to interactive Liquid Glass cards.
4. **Plan 004** (`004-active-prayer-capsule-morph.md`) — Refines the active prayer highlight pulse.
5. **Plan 005** (`005-initial-load-card-stagger.md`) — Adds smooth staggered entrance on app launch.

## Dependencies

- All plans are independent and self-contained; they modify non-overlapping sections in `lib/dashboard.dart`.
