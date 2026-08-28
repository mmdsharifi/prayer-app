# Design System — اذکار من

## Visual Theme

Liquid Glass Dark Atmosphere with Dynamic Celestial Lighting. The interface mirrors the 8 astronomical phases of the day (dawn, morning, noon, afternoon, sunset, evening, night, midnight) through ambient particle drifts, celestial glow pulses, and translucent frosted glass surfaces.

## Color Palette

### Base Surfaces & Backgrounds
- **Canvas Deep Midnight**: `#070D1A` (90% lightness reduction, dark blue-black)
- **Glass Card Fill (Dark)**: `rgba(11, 20, 38, 0.55)`
- **Glass Card Fill (Day)**: `rgba(255, 255, 255, 0.12)`
- **Specular Border Highlight**: `rgba(255, 255, 255, 0.14)` (1.0px width)
- **Active Capsule Gradient**: `linear-gradient(135deg, rgba(16, 185, 129, 0.32), rgba(5, 150, 105, 0.22))`

### Accent Roles
- **Emerald Pulse (Primary / Active Prayer)**: `#10B981` / `#34D399`
- **Ice Blue (Sky / Calendar / Celestial Info)**: `#38BDF8` / `#7DD3FC`
- **Amber Glow (Azkar / Sunnah Fasting / Sunrise)**: `#F59E0B` / `#FDE68A`
- **Sunset Crimson (Maghrib / Twilight Aura)**: `#FB7185` / `#FDA4AF`

## Typography

### Font Families
- **Primary UI & Digits**: `Vazirmatn`, sans-serif (Weights: 400, 600, 700, 800)
- **Sacred Verses & Arabic**: `Amiri` / Traditional Arabic Naskh

### Typographic Hierarchy
- **Next Prayer Big Clock**: 38px, Weight 900, Tabular Figures (`FontFeature.tabularFigures()`), `#FFFFFF`
- **Section Headers & Titles**: 16–18px, Weight 800, Letter-spacing -0.3px, `#FFFFFF`
- **Metric Badges & Prayer Names**: 12–13.5px, Weight 700, `#E2E8F0`
- **Quran & Hadith Arabic Body**: 17–19px, Line-height 1.85, `#F8FAFC`
- **Persian Translation & Notes**: 12–13px, Line-height 1.6, `#CBD5E1`
- **Subtitles & Timestamps**: 10.5–11.5px, Weight 600, `#94A3B8`

## Components & Elevation

### Liquid Glass Card (`LiquidGlassCard`)
- **Border Radius**: 18px / 20px continuous squircle
- **Backdrop Blur**: `sigmaX: 18, sigmaY: 18`
- **Border**: 1.0px solid `rgba(255, 255, 255, 0.14)`
- **Shadow**: `BoxShadow(color: rgba(0, 0, 0, 0.35), blurRadius: 24, offset: (0, 8))`
- **Tactile Feedback**: `AnimatedScale(scale: 0.985, duration: 140ms)` on tap/press

### Active Prayer Capsule
- **Border Radius**: 11px
- **Border**: 1.2px solid `rgba(52, 211, 153, 0.65)`
- **Glow**: `BoxShadow(color: rgba(16, 185, 129, 0.25), blurRadius: 12, offset: (0, 2))`
- **Scale Morph**: `AnimatedScale(scale: 1.025, duration: 280ms)`

### Motion & Physics
- **Continuous Refresh Rotation**: 750ms linear spin with 250ms `Curves.easeOutCubic` settle.
- **Directional Verse Transitions**: RTL-aware horizontal slide (`Offset(0.06, 0.0)` forward, `Offset(-0.06, 0.0)` backward).
- **Card Stagger Entrance**: 35ms delay per index, 260ms duration with `Curves.easeOutCubic`.
