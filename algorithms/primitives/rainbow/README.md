# Rainbow

Procedural double rainbow with atmospheric effects — ROYGBIV color bands arcing through 3D space.

## QFEP Connection

The rainbow is **order from chaos** — white light (high entropy, all frequencies) passes through water droplets and emerges as separated, ordered bands (low entropy, discrete frequencies). Nature's own spectral analysis, visible when conditions align.

## How It Works

```
      ╭──────────────────╮  ← Secondary (fainter, reversed)
     ╱                    ╲
    ╱  ╭────────────────╮  ╲
   ╱  ╱                  ╲  ╲
      ╲                  ╱    ← Primary (ROYGBIV)
       ╲                ╱
        ╲              ╱
         ╲            ╱
          ───────────
```

Two concentric arcs:
1. **Primary rainbow**: Inner, brighter, normal color order (Red outside → Violet inside)
2. **Secondary rainbow**: Outer, fainter, reversed colors (Violet outside → Red inside)

## Color Bands

| Color | RGB | Index |
|-------|-----|-------|
| Red | (1.0, 0.0, 0.0) | 0 |
| Orange | (1.0, 0.5, 0.0) | 1 |
| Yellow | (1.0, 1.0, 0.0) | 2 |
| Green | (0.0, 1.0, 0.0) | 3 |
| Blue | (0.0, 0.0, 1.0) | 4 |
| Indigo | (0.3, 0.0, 0.5) | 5 |
| Violet | (0.5, 0.0, 1.0) | 6 |

## Parameters

| Constant | Value | Description |
|----------|-------|-------------|
| `RAINBOW_RADIUS` | 15.0 | Arc radius |
| `RAINBOW_HEIGHT` | 8.0 | Peak height |
| `RAINBOW_SEGMENTS` | 64 | Arc smoothness |
| `RAINBOW_THICKNESS` | 0.8 | Band width |
| `SECONDARY_OFFSET` | 3.0 | Gap between rainbows |
| `SECONDARY_FADE` | 0.4 | Secondary alpha multiplier |

## Components

- **Color bands**: Mesh tubes for each spectral color
- **Atmosphere**: Additional visual effects

## Files

| File | Purpose |
|------|---------|
| `rainbow.tscn` | Scene root |
| `rainbow.gd` | Generation logic |

## Usage

```gdscript
var rainbow = preload("res://algorithms/primitives/rainbow/rainbow.tscn").instantiate()
add_child(rainbow)
```

## Physics Background

Real rainbows form when:
1. Light enters water droplet
2. Refracts (bends) at entry
3. Reflects off back of droplet
4. Refracts again at exit

Different wavelengths bend different amounts → color separation.
Secondary rainbow: light reflects twice inside → reversed, dimmer.

## VR Experience

Stand beneath the rainbow arc. The double rainbow with its color reversal demonstrates optical physics in an immersive way. Walk toward it — like real rainbows, it stays at a constant angular distance.

## See Also

- `color/` — Color theory explorations
- `wavefunctions/` — Wave-based phenomena
- `shaders/` — Iridescence and spectral effects
