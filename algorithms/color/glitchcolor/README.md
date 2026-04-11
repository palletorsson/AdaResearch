# Glitch Color

Bit manipulation techniques for color — XOR, shifting, and binary corruption as aesthetic tools.

## QFEP Connection

Colors are **numbers in disguise**. RGB values are 8-bit integers (F, discrete); bit operations reveal hidden relationships (E, unexpected patterns). XOR creates interference patterns; bit shifts change brightness in non-linear ways. λ as binary exploration.

## Techniques

| Operation | Effect |
|-----------|--------|
| XOR | Color interference patterns |
| Left shift | Brighten (multiply by 2) |
| Right shift | Darken (divide by 2) |
| AND mask | Extract channels |
| NOT | Invert bits |

## Features

Grid of cubes demonstrating different bit effects:
- Row 1: XOR patterns
- Row 2: Shift operations
- Row 3: Animated bit cycling

## Files

| File | Purpose |
|------|---------|
| `glitch_color.gd` | Bit manipulation demo |
| `*.tscn` | Scene |

## Usage

```gdscript
var glitch = preload("res://algorithms/color/glitchcolor/glitch.tscn").instantiate()
add_child(glitch)
```

## See Also

- `advancedglitch/` — Full glitch system
- `postprocessing/` — Other visual effects
