# Color Mixing

Interactive demonstrations of additive (RGB) and subtractive (CMY) color mixing — the fundamental physics of light and pigment.

## QFEP Connection

Color mixing reveals **two incompatible truths coexisting**. RGB (light) and CMY (pigment) follow opposite rules: red + green = yellow in light, but makes brown in paint. Neither is "correct" — they're different physical systems with different logics. This is λ-territory: context determines truth.

## Two Mixing Modes

### Additive (RGB) — Light/Screens

```
     🔴 Red
    / \
   /   \
  ▢─────▢
 🟢    🔵
Green   Blue

Overlaps:
R + G = Yellow
G + B = Cyan  
B + R = Magenta
R + G + B = White
```

Light adds. More colors = brighter.

### Subtractive (CMY) — Ink/Paint

```
     🩵 Cyan
    / \
   /   \
  ▢─────▢
🩷     🟡
Magenta Yellow

Overlaps:
C + M = Blue
M + Y = Red
Y + C = Green
C + M + Y = Black
```

Pigment subtracts. More colors = darker.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `plane_size` | 2.0 | Size of color planes |
| `plane_thickness` | 0.15 | Plane depth |
| `plane_opacity` | 0.5 | Transparency |
| `separation` | 0.5 | Overlap distance |

## Scenes

| Scene | Purpose |
|-------|---------|
| `color_mixing.tscn` | Basic demo |
| `visual_color_mixing.tscn` | Visual emphasis |
| `interactive_color_mixing.tscn` | Grabbable disks |
| `advanced_mixing_examples.tscn` | Complex combinations |

## Files

| File | Purpose |
|------|---------|
| `color_mixing.gd` | Main mixing logic |
| `color_display_disk.gd` | Interactive disk component |

## Usage

```gdscript
var mixing = preload("res://algorithms/color/color_mixing/color_mixing.tscn").instantiate()
mixing.plane_opacity = 0.7  # More opaque
add_child(mixing)
```

## VR Experience

Two setups side by side:
- **Left**: Subtractive (CMY) — overlapping translucent planes
- **Right**: Additive (RGB) — emissive overlapping lights

Walk between them, observe the overlaps. The same geometric arrangement produces opposite color results. In interactive mode, grab and move the color disks to explore combinations.

## Why Two Systems?

| | Additive (Light) | Subtractive (Pigment) |
|---|---|---|
| **Medium** | Emitted light | Reflected light |
| **Primaries** | Red, Green, Blue | Cyan, Magenta, Yellow |
| **Combination** | Gets brighter | Gets darker |
| **All primaries** | White | Black |
| **No color** | Black | White |
| **Used in** | Screens, projectors | Printers, paint |

## Physics Note

Subtractive mixing works because pigments *absorb* certain wavelengths:
- Cyan absorbs red → reflects blue + green
- Magenta absorbs green → reflects red + blue
- Yellow absorbs blue → reflects red + green

When all three overlap, all wavelengths are absorbed → black.

## See Also

- `colorspaces/` — Color space representations
- `colortrails/` — Color in motion
- `shaders/` — GPU color manipulation
