# Pyramid Stage

Obelisk-style pyramid stage composition — architectural arrangement of geometric primitives.

## QFEP Connection

Stage design is **composition as meaning**. The central obelisk (hierarchy, F) is balanced by corner pyramids (symmetry, F) and golden cubes (accent, E). The arrangement isn't random — it follows principles of visual balance. This is λ in spatial design: how elements relate creates the experience.

## Structure

```
Top view:                       Side view:
┌─────────────────────────┐         △ Central obelisk
│  △           △          │        /│\
│     ◆     ◆     ◆       │       / │ \
│          △              │      /  │  \
│     ◆  obelisk  ◆       │   △/   │   \△
│          ▽              │  ═══════════════
│     ◆     ◆     ◆       │        Plinth
│  △           △          │
└─────────────────────────┘

△ = Corner pyramids (light blue)
◆ = Golden cubes
Central = Main obelisk (pink/rose)
```

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `plinth_size` | (20, 1, 14) | Base platform dimensions |
| `obelisk_height` | 4.0 | Central pyramid height |
| `small_pyr_height` | 2.5 | Corner pyramid height |
| `cube_size` | 0.9 | Golden cube size |
| `ring_radius_x` | 6.0 | Corner spacing (width) |
| `ring_radius_z` | 4.5 | Corner spacing (depth) |

## Color Scheme

| Element | Color | Meaning |
|---------|-------|---------|
| Plinth | Gray | Grounding, neutral base |
| Obelisk | Pink/rose (translucent) | Central focus, aspiration |
| Corner pyramids | Light blue | Balance, support |
| Cubes | Golden | Accents, treasure |

## Components

1. **Base Plinth**: Scaled cube as foundation
2. **Central Obelisk**: Tall pyramid at center
3. **Corner Pyramids**: Four smaller pyramids at corners
4. **Golden Cubes**: Decorative accents around the composition

## Files

| File | Purpose |
|------|---------|
| `pyramid_stage.gd` | Stage generator |
| `*.tscn` | Scene file |

## Dependencies

Uses shared primitive scenes:
- `res://commons/primitives/pyramid/pyramid.tscn`
- `res://commons/primitives/cubes/cube_scene.tscn`

## Usage

```gdscript
var stage = preload("res://algorithms/primitives/pyramidstage/pyramid_stage.tscn").instantiate()
stage.obelisk_height = 6.0  # Taller central piece
add_child(stage)
```

## VR Experience

Stand on or around the pyramid stage. The composition has clear hierarchy — your eye is drawn to the central obelisk. The corner pyramids anchor the design. The golden cubes provide visual rhythm. This is how architects and set designers think about space.

## Design Principles Demonstrated

- **Hierarchy**: Central element dominates
- **Symmetry**: Corner elements balance
- **Rhythm**: Repeated cube accents
- **Color harmony**: Complementary palette
- **Scale contrast**: Large vs small elements

## See Also

- `primitives/` — Basic shape components
- `arrays/` — Repetitive arrangements
- `criticaltheory/` — Spatial meaning
