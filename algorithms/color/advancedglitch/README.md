# Advanced Glitch

Digital corruption and bit manipulation techniques — datamoshing, pixel sorting, channel corruption, and buffer overflows as aesthetic tools.

## QFEP Connection

Glitch art embraces **error as expression**. These techniques corrupt ordered data (F) into chaotic artifacts (E). The `glitch_strength` and `corruption_rate` control how much entropy you inject. Glitch is λ made visible: the moment systems fail, something unexpected emerges.

## Techniques

### Datamoshing
Corrupted video compression artifacts:
```
Frame N:     [████████]
Frame N+1:   [▓▓░░▓▓▓▓]  ← Motion data from different frame
Result:      [▓███░▓██]  ← Smeared, ghosted
```

### Pixel Sorting
Reorder pixels by brightness/hue:
```
Original:    [4][2][7][1][5]
Sorted:      [1][2][4][5][7]
```
Creates waterfall-like streaks in images.

### Channel Corruption
Offset or swap RGB channels:
```
R channel: shift left 5px
G channel: unchanged
B channel: shift right 3px
Result: Chromatic fringing / RGB split
```

### Bit Manipulation
Direct manipulation of binary data:
- **XOR patterns**: A ⊕ B creates interference
- **Bit crushing**: Reduce bit depth (posterization)
- **Buffer overflow**: Read past array bounds

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `auto_animate` | true | Continuous corruption |
| `glitch_strength` | 0.5 | Overall intensity |
| `corruption_rate` | 0.1 | Frequency of glitches |
| `temporal_speed` | 1.0 | Animation speed |

## Demo Objects

Grid of 9 effect demonstrations:
1. Datamoshing
2. Pixel sorting
3. Channel corruption
4. Memory corruption
5. Buffer overflow
6. Bit crushing
7. XOR patterns
8. Chromatic shift
9. Digital decay

## Files

| File | Purpose |
|------|---------|
| `advanced_glitch.gd` | Main system |
| `advanced_glitch.tscn` | Demo scene |

## Usage

```gdscript
var glitch = preload("res://algorithms/color/advancedglitch/advanced_glitch.tscn").instantiate()
glitch.glitch_strength = 0.8  # Heavy corruption
glitch.corruption_rate = 0.3  # Frequent glitches
add_child(glitch)
```

## VR Experience

Objects in the demo grid demonstrate different corruption techniques. Watch as data decays, channels separate, pixels sort themselves into streams. The glitch strength controls how broken things get — from subtle artifacts to complete visual chaos.

## Cultural Context

Glitch art emerged from:
- **Video game glitches**: Missingno, corrupted saves
- **Datamoshing**: Compressed video artifacts
- **Net.art**: Intentional digital decay
- **Vaporwave**: Nostalgic corruption aesthetics

Glitch reveals the fragility of digital systems — and finds beauty in their failure.

## See Also

- `effects/` — Other visual effects
- `shaders/` — GPU-based corruption
- `randomness/` — Stochastic processes
