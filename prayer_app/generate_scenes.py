import os

scenes = {
    'dawn': {
        'sky_stops': [('#1e1b4b', '0%'), ('#4c1d95', '35%'), ('#c026d3', '65%'), ('#f472b6', '85%'), ('#fde68a', '100%')],
        'sun': {'cx': 950, 'cy': 310, 'r': 44, 'color': '#fef08a', 'aura1': '#f472b6', 'aura2': '#fb7185'},
        'mountains_far': '#3b1c6e',
        'mountains_mid': '#24104d',
        'lake_base': '#4c1d95',
        'lake_glow': '#fde68a',
        'hill1': '#1b4332',
        'hill2': '#143026',
        'tree_trunk': '#3c2415',
        'tree_dark': '#1e382b',
        'tree_mid': '#2d5a44',
        'tree_light': '#407a5d',
        'flower_colors': ['#ffffff', '#fde68a', '#f472b6', '#fed7aa'],
        'is_night': False,
    },
    'morning': {
        'sky_stops': [('#38bdf8', '0%'), ('#7dd3fc', '45%'), ('#bae6fd', '75%'), ('#e0f2fe', '100%')],
        'sun': {'cx': 950, 'cy': 150, 'r': 48, 'color': '#fde047', 'aura1': '#fef08a', 'aura2': '#fffbeb'},
        'mountains_far': '#60a5fa',
        'mountains_mid': '#3b82f6',
        'lake_base': '#38bdf8',
        'lake_glow': '#fef08a',
        'hill1': '#22c55e',
        'hill2': '#16a34a',
        'tree_trunk': '#5c3a21',
        'tree_dark': '#15803d',
        'tree_mid': '#16a34a',
        'tree_light': '#4ade80',
        'flower_colors': ['#ffffff', '#fef08a', '#f87171', '#c084fc'],
        'is_night': False,
    },
    'noon': {
        'sky_stops': [('#0284c7', '0%'), ('#38bdf8', '50%'), ('#bae6fd', '80%'), ('#e0f2fe', '100%')],
        'sun': {'cx': 950, 'cy': 90, 'r': 52, 'color': '#fef08a', 'aura1': '#fffde7', 'aura2': '#ffffff'},
        'mountains_far': '#38bdf8',
        'mountains_mid': '#0284c7',
        'lake_base': '#0369a1',
        'lake_glow': '#fffde7',
        'hill1': '#16a34a',
        'hill2': '#15803d',
        'tree_trunk': '#4a2f1b',
        'tree_dark': '#14532d',
        'tree_mid': '#15803d',
        'tree_light': '#22c55e',
        'flower_colors': ['#ffffff', '#fde047', '#f472b6', '#a78bfa'],
        'is_night': False,
    },
    'afternoon': {
        'sky_stops': [('#0284c7', '0%'), ('#38bdf8', '40%'), ('#fed7aa', '75%'), ('#fef08a', '100%')],
        'sun': {'cx': 950, 'cy': 220, 'r': 50, 'color': '#fbbf24', 'aura1': '#fde68a', 'aura2': '#fed7aa'},
        'mountains_far': '#475569',
        'mountains_mid': '#334155',
        'lake_base': '#0284c7',
        'lake_glow': '#fde68a',
        'hill1': '#15803d',
        'hill2': '#166534',
        'tree_trunk': '#452b19',
        'tree_dark': '#14532d',
        'tree_mid': '#15803d',
        'tree_light': '#84cc16',
        'flower_colors': ['#ffffff', '#fde047', '#fb923c', '#e879f9'],
        'is_night': False,
    },
    'sunset': {
        'sky_stops': [('#312e81', '0%'), ('#7c2d12', '35%'), ('#ea580c', '60%'), ('#f59e0b', '80%'), ('#fde68a', '100%')],
        'sun': {'cx': 950, 'cy': 330, 'r': 46, 'color': '#fbbf24', 'aura1': '#f97316', 'aura2': '#ef4444'},
        'mountains_far': '#4c1d95',
        'mountains_mid': '#3b0764',
        'lake_base': '#7c2d12',
        'lake_glow': '#fde68a',
        'hill1': '#14532d',
        'hill2': '#052e16',
        'tree_trunk': '#2e180d',
        'tree_dark': '#064e3b',
        'tree_mid': '#0f766e',
        'tree_light': '#d97706',
        'flower_colors': ['#fef08a', '#fb7185', '#fdba74', '#ffffff'],
        'is_night': False,
    },
    'evening': {
        'sky_stops': [('#0f172a', '0%'), ('#1e1b4b', '40%'), ('#312e81', '70%'), ('#4c1d95', '100%')],
        'moon': {'cx': 950, 'cy': 130, 'r': 26, 'glow': '#c4b5fd'},
        'mountains_far': '#1e1b4b',
        'mountains_mid': '#0f172a',
        'lake_base': '#1e1b4b',
        'lake_glow': '#818cf8',
        'hill1': '#064e3b',
        'hill2': '#022c22',
        'tree_trunk': '#1c1917',
        'tree_dark': '#022c22',
        'tree_mid': '#064e3b',
        'tree_light': '#0d9488',
        'flower_colors': ['#e0e7ff', '#c4b5fd', '#ffffff', '#a7f3d0'],
        'is_night': True,
    },
    'night': {
        'sky_stops': [('#020617', '0%'), ('#0f172a', '50%'), ('#1e293b', '100%')],
        'moon': {'cx': 950, 'cy': 120, 'r': 26, 'glow': '#93c5fd'},
        'mountains_far': '#0f172a',
        'mountains_mid': '#020617',
        'lake_base': '#0f172a',
        'lake_glow': '#60a5fa',
        'hill1': '#064e3b',
        'hill2': '#022c22',
        'tree_trunk': '#18181b',
        'tree_dark': '#022c22',
        'tree_mid': '#064e3b',
        'tree_light': '#047857',
        'flower_colors': ['#ffffff', '#bae6fd', '#ddd6fe', '#a7f3d0'],
        'is_night': True,
    },
    'midnight': {
        'sky_stops': [('#020617', '0%'), ('#0b0f19', '55%'), ('#0f172a', '100%')],
        'moon': {'cx': 950, 'cy': 100, 'r': 24, 'glow': '#bfdbfe'},
        'mountains_far': '#0b0f19',
        'mountains_mid': '#020617',
        'lake_base': '#0b0f19',
        'lake_glow': '#38bdf8',
        'hill1': '#042f2e',
        'hill2': '#021a18',
        'tree_trunk': '#121214',
        'tree_dark': '#021a18',
        'tree_mid': '#042f2e',
        'tree_light': '#0f766e',
        'flower_colors': ['#ffffff', '#e0f2fe', '#c7d2fe', '#99f6e4'],
        'is_night': True,
    },
}

# Flower template generator
def generate_flower(x, y, color, size=3.5):
    return f'''
    <g transform="translate({x}, {y})">
      <circle cx="0" cy="-{size*0.7:.1f}" r="{size*0.6:.1f}" fill="{color}" opacity="0.9"/>
      <circle cx="{size*0.7:.1f}" cy="0" r="{size*0.6:.1f}" fill="{color}" opacity="0.9"/>
      <circle cx="0" cy="{size*0.7:.1f}" r="{size*0.6:.1f}" fill="{color}" opacity="0.9"/>
      <circle cx="-{size*0.7:.1f}" cy="0" r="{size*0.6:.1f}" fill="{color}" opacity="0.9"/>
      <circle cx="0" cy="0" r="{size*0.4:.1f}" fill="#fef08a"/>
    </g>'''

# Grass tuft
def generate_grass(x, y, color):
    return f'''
    <g transform="translate({x}, {y})">
      <path d="M0 0 C-2 -10 -8 -16 -12 -18 C-7 -12 -3 -5 0 0 Z" fill="{color}" opacity="0.75"/>
      <path d="M0 0 C0 -12 2 -20 4 -22 C3 -14 1 -6 0 0 Z" fill="{color}" opacity="0.85"/>
      <path d="M0 0 C2 -9 8 -15 11 -17 C7 -11 3 -5 0 0 Z" fill="{color}" opacity="0.75"/>
    </g>'''

# Cypress silhouette on ridge
def generate_cypress(x, y, color, scale=1.0):
    w = 8 * scale
    h = 32 * scale
    return f'''<path d="M{x} {y} C{x-w} {y-h*0.4} {x-w*0.7} {y-h*0.8} {x} {y-h} C{x+w*0.7} {y-h*0.8} {x+w} {y-h*0.4} {x} {y} Z" fill="{color}" opacity="0.85"/>'''

# Distant pine tree
def generate_pine(x, y, color, scale=1.0):
    return f'''
    <g transform="translate({x}, {y}) scale({scale})">
      <polygon points="0,-28 -8,-16 -3,-16 -10,-4 -4,-4 -12,8 12,8 4,-4 10,-4 3,-16 8,-16" fill="{color}" opacity="0.9"/>
      <rect x="-1.5" y="8" width="3" height="6" fill="{color}"/>
    </g>'''

for name, s in scenes.items():
    stops_svg = '\n'.join([f'    <stop offset="{off}" stop-color="{col}"/>' for col, off in s['sky_stops']])
    
    # Celestial
    celestial_svg = ''
    if s.get('is_night'):
        m = s['moon']
        cx, cy, r = m['cx'], m['cy'], m['r']
        glow = m['glow']
        celestial_svg = f'''
  <!-- Stars -->
  <g opacity="0.6">
    <circle cx="150" cy="80" r="1.5" fill="#ffffff"/>
    <circle cx="280" cy="120" r="1.2" fill="#ffffff"/>
    <circle cx="420" cy="65" r="1.8" fill="#ffffff"/>
    <circle cx="560" cy="140" r="1.3" fill="#ffffff"/>
    <circle cx="700" cy="90" r="1.6" fill="#ffffff"/>
    <circle cx="820" cy="160" r="1.4" fill="#ffffff"/>
    <circle cx="1120" cy="70" r="1.5" fill="#ffffff"/>
    <circle cx="80" cy="190" r="1.0" fill="#ffffff"/>
    <circle cx="640" cy="50" r="2.0" fill="#ffffff"/>
    <circle cx="1020" cy="180" r="1.2" fill="#ffffff"/>
  </g>

  <!-- Glowing Crescent Moon -->
  <g transform="translate({cx}, {cy})">
    <circle cx="0" cy="0" r="{r*3.2:.1f}" fill="{glow}" opacity="0.12"/>
    <circle cx="0" cy="0" r="{r*2.0:.1f}" fill="{glow}" opacity="0.22"/>
    <path d="M0 -{r} A {r} {r} 0 1 0 {r} {r} A {r*1.15:.1f} {r*1.15:.1f} 0 1 1 0 -{r} Z" fill="#ffffff"/>
  </g>'''
    else:
        sun = s['sun']
        cx, cy, r = sun['cx'], sun['cy'], sun['r']
        celestial_svg = f'''
  <!-- Sun with Radiant Corona Aura -->
  <g transform="translate({cx}, {cy})">
    <circle cx="0" cy="0" r="{r*2.6:.1f}" fill="{sun['aura2']}" opacity="0.18"/>
    <circle cx="0" cy="0" r="{r*1.8:.1f}" fill="{sun['aura1']}" opacity="0.32"/>
    <circle cx="0" cy="0" r="{r}" fill="{sun['color']}"/>
  </g>'''

    # Flowers on hills
    flowers_list = []
    import random
    random.seed(42) # Deterministic lovely layout
    for i in range(35):
        fx = 40 + (i * 32) + random.uniform(-10, 10)
        fy = 595 + (random.uniform(10, 85))
        fcol = s['flower_colors'][i % len(s['flower_colors'])]
        fsize = random.uniform(2.6, 4.2)
        flowers_list.append(generate_flower(fx, fy, fcol, fsize))
        if i % 3 == 0:
            flowers_list.append(generate_grass(fx + 8, fy + 4, s['tree_dark']))

    flowers_svg = '\n'.join(flowers_list)

    # Ridge cypress trees
    ridge_trees = [
        generate_cypress(220, 430, s['mountains_mid'], 0.6),
        generate_cypress(235, 435, s['mountains_mid'], 0.5),
        generate_pine(510, 395, s['mountains_mid'], 0.7),
        generate_pine(525, 400, s['mountains_mid'], 0.6),
        generate_cypress(760, 420, s['mountains_mid'], 0.7),
        generate_cypress(775, 425, s['mountains_mid'], 0.55),
        generate_pine(890, 410, s['mountains_mid'], 0.65),
    ]
    ridge_trees_svg = '\n'.join(ridge_trees)

    # Midground small tree on left
    midground_tree_left = f'''
  <!-- Left Midground Tree -->
  <g transform="translate(140, 520)">
    <!-- Trunk -->
    <path d="M0 0 C2 -20 6 -40 4 -60 C1 -50 -3 -30 -2 0 Z" fill="{s['tree_trunk']}"/>
    <!-- Foliage Layers -->
    <ellipse cx="2" cy="-62" rx="34" ry="28" fill="{s['tree_dark']}"/>
    <ellipse cx="-12" cy="-52" rx="22" ry="18" fill="{s['tree_mid']}"/>
    <ellipse cx="14" cy="-56" rx="24" ry="20" fill="{s['tree_mid']}"/>
    <ellipse cx="4" cy="-70" rx="26" ry="20" fill="{s['tree_light']}" opacity="0.9"/>
  </g>'''

    # Masterpiece Foreground Tree on Right
    masterpiece_tree_right = f'''
  <!-- Masterpiece Foreground Tree on Right -->
  <g transform="translate(1040, 470)">
    <!-- Natural organic curved trunk with roots and limbs -->
    <path d="M-12 180 C-8 120 -6 70 -4 30 C-2 15 2 0 6 -15 C3 5 0 25 -2 55 C-3 85 -2 135 14 180 Z" fill="{s['tree_trunk']}"/>
    <path d="M-4 30 C-18 10 -35 8 -50 14 C-36 18 -22 22 -6 28 Z" fill="{s['tree_trunk']}"/>
    <path d="M2 15 C18 -2 38 -5 54 -2 C38 4 24 8 4 18 Z" fill="{s['tree_trunk']}"/>
    
    <!-- Deep Shadow Foliage Foundation -->
    <ellipse cx="0" cy="15" rx="84" ry="68" fill="{s['tree_dark']}"/>
    <ellipse cx="-45" cy="5" rx="55" ry="44" fill="{s['tree_dark']}"/>
    <ellipse cx="48" cy="8" rx="58" ry="46" fill="{s['tree_dark']}"/>
    
    <!-- Mid-tone Leafy Canopy Masses -->
    <ellipse cx="-28" cy="-18" rx="60" ry="48" fill="{s['tree_mid']}"/>
    <ellipse cx="32" cy="-15" rx="62" ry="50" fill="{s['tree_mid']}"/>
    <ellipse cx="2" cy="-35" rx="65" ry="52" fill="{s['tree_mid']}"/>
    <ellipse cx="-55" cy="-2" rx="42" ry="34" fill="{s['tree_mid']}"/>
    <ellipse cx="58" cy="0" rx="44" ry="35" fill="{s['tree_mid']}"/>

    <!-- Sunlit Crown & Shaded Volumes -->
    <ellipse cx="-16" cy="-45" rx="48" ry="38" fill="{s['tree_light']}"/>
    <ellipse cx="22" cy="-42" rx="50" ry="40" fill="{s['tree_light']}"/>
    <ellipse cx="2" cy="-60" rx="44" ry="34" fill="{s['tree_light']}" opacity="0.95"/>
    <ellipse cx="38" cy="-28" rx="32" ry="24" fill="{s['tree_light']}" opacity="0.85"/>
  </g>'''

    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 700" preserveAspectRatio="xMidYMid slice">
<defs>
  <linearGradient id="sky_{name}" x1="0" y1="0" x2="0" y2="1">
{stops_svg}
  </linearGradient>
  <radialGradient id="lakeGlow_{name}" cx="50%" cy="35%">
    <stop offset="0%" stop-color="{s['lake_glow']}" stop-opacity="0.45"/>
    <stop offset="100%" stop-color="{s['lake_glow']}" stop-opacity="0.0"/>
  </radialGradient>
</defs>

<!-- Sky -->
<rect width="1200" height="700" fill="url(#sky_{name})"/>

{celestial_svg}

<!-- Far Mountain Ridge -->
<path d="M0 410 C160 330 310 395 480 345 C650 295 810 380 970 325 C1090 355 1160 380 1200 370 L1200 700 L0 700 Z" fill="{s['mountains_far']}" opacity="0.85"/>

<!-- Mid Mountain Ridge with Pine/Cypress Groves -->
<path d="M0 455 C190 390 380 445 560 410 C740 375 920 440 1080 395 C1150 415 1180 430 1200 425 L1200 700 L0 700 Z" fill="{s['mountains_mid']}"/>
{ridge_trees_svg}

<!-- Atmospheric Mist Belt -->
<rect x="0" y="435" width="1200" height="35" fill="#ffffff" opacity="0.06"/>

<!-- Lake Water with Soft Specular Reflection -->
<ellipse cx="780" cy="560" rx="540" ry="130" fill="url(#lakeGlow_{name})"/>
<path d="M0 515 C280 488 560 530 840 500 C1010 482 1130 512 1200 505 L1200 700 L0 700 Z" fill="{s['lake_base']}"/>

<!-- Rolling Meadow Hills (Smooth organic foreground) -->
<path d="M0 580 C220 535 460 590 700 550 C940 515 1090 565 1200 550 L1200 700 L0 700 Z" fill="{s['hill1']}"/>
<path d="M0 625 C260 585 540 635 810 605 C1010 580 1130 620 1200 610 L1200 700 L0 700 Z" fill="{s['hill2']}"/>

<!-- Wildflower Meadow & Grass Details -->
{flowers_svg}

{midground_tree_left}

{masterpiece_tree_right}

</svg>
'''
    with open(f'/Users/user/prayer-app/prayer_app/assets/scenes/{name}.svg', 'w') as f:
        f.write(svg_content)
    print(f'Generated {name}.svg')
