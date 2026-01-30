# Double Helix

Procedural DNA double helix generator — the mathematical structure of life's information storage.

## QFEP Connection

DNA is **information encoded in geometry**. The double helix is a specific shape (F, structure) that enables replication and transcription (E, dynamics). The `phase_offset` parameter controls the relative rotation of the two strands — a physical constraint that enables the chemistry of life.

## How It Works

```
Side view:            Top view:
    ●                    ●
   ╱│╲                  ╱ ╲
  ● │ ●                ●   ●
   ╲│╱                  ╲ ╱
    ●                    ●
   ╱│╲                 
  ● │ ●         Two helices offset by 
   ╲│╱          phase (typically π)
    ●
```

Two helical strands connected by rungs (base pairs).

## Parameters

### Helix Geometry
| Export | Default | Range | Description |
|--------|---------|-------|-------------|
| `helix_radius` | 0.65 | 0.1-20 | Distance from axis |
| `helix_height` | 6.0 | 1-20 | Total height |
| `helix_turns` | 5 | 1-20 | Number of full rotations |
| `points_per_turn` | 32 | 4-128 | Resolution per turn |

### Strand Appearance
| Export | Default | Range | Description |
|--------|---------|-------|-------------|
| `strand_point_radius` | 0.08 | 0.02-0.4 | Backbone bead size |
| `strand_segments` | 24 | 6-64 | Sphere smoothness |

### Structure
| Export | Default | Range | Description |
|--------|---------|-------|-------------|
| `rung_every` | 3 | 1-16 | Base pair frequency |
| `phase_offset` | 0.0 | — | Strand rotation offset |

## Mathematical Form

```
Strand 1:
x(t) = radius × cos(turns × 2π × t)
y(t) = height × t
z(t) = radius × sin(turns × 2π × t)

Strand 2:
x(t) = radius × cos(turns × 2π × t + phase_offset)
y(t) = height × t
z(t) = radius × sin(turns × 2π × t + phase_offset)
```

## Files

| File | Purpose |
|------|---------|
| `double_helix.gd` | Generator script |
| `*.tscn` | Scene file |

## Usage

```gdscript
var dna = preload("res://algorithms/wavefunctions/doublehelix/double_helix.tscn").instantiate()
dna.helix_turns = 10
dna.phase_offset = PI  # Standard DNA offset
add_child(dna)
```

## VR Experience

Walk along the DNA molecule. The double helix spirals above and around you. The rungs connecting the strands represent base pairs — A-T and G-C in real DNA. The structure is both elegant and functional.

## Biological Notes

Real DNA:
- ~10 base pairs per turn
- 3.4 nm per turn height (pitch)
- 2 nm diameter
- Right-handed helix (B-DNA form)

The `phase_offset` creates the major and minor grooves that proteins use to read DNA.

## See Also

- `computationalbiology/` — Biological simulations
- `lsystems/` — Growth patterns
- `arrays/` — Periodic structures
