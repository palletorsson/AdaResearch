# Homage to the Square

Josef Albers in 3D. Nested squares, color interaction, perception.

## QFEP Connection

Albers' squares are **F studying F**: pure geometric forms used to reveal how context changes perception. The same color appears different depending on neighbors. This is QFEP epistemology — the observer is part of the system.

## The Artist

Josef Albers (1888–1976) created over 2,000 "Homage to the Square" paintings at the Bauhaus and Yale. His insight: color is relative, not absolute. A yellow next to blue is not the same yellow next to orange.

## Implementation

Nested squares with:
- 10 layers, each 85% the size of the previous
- Subtle color gradient (warm beige → mauve → coral)
- Slight offset (not perfectly centered, like Albers)
- 3D geometry with vertex colors

## Colors (Outer to Inner)

```
Warm beige → Light beige → Cream → Very light cream →
Mauve → Light purple → Medium pink → Coral → Salmon → Peachy coral
```

## Parameters

```gdscript
var scale_factor = 0.5    # Overall size
var x_offset = 0.5        # Horizontal offset
var z_offset = 0.0        # Depth offset
```

## Perception Experiment

Stand in front of the squares and focus on one color. Notice how it seems to change as you shift attention to its neighbors. The color itself hasn't changed — your perception has.

## Files

- `homagetothesquare.gd` — Albers-style nested squares
- `homagetothesquare.tscn` — Scene setup
