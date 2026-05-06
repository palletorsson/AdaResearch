# Fourier Transform Shape

Epicycle visualization of Fourier series — complex shapes drawn by rotating wheels on wheels.

## QFEP Connection

Fourier analysis reveals that **any shape is a sum of circles**. Complex forms (E, apparent chaos) decompose into simple rotations (F, sine waves). The `wheels` array defines frequency components; together they trace intricate paths. This is λ as synthesis — how simple elements combine into complexity.

## How It Works

```
Wheel 1 (slow):        Wheel 2 (fast):        Combined:
    ●──●                    ●──●                ●
   ╱    ╲                  │  │               ╱ ╲
  ●      ●                 ●──●              ●   ●
   ╲    ╱                                     ╲ ╱
    ●──●                                       ●
    
Large slow circle    + Small fast circle  = Complex path
```

Each wheel rotates at its frequency; the tip of the last wheel traces the shape.

## Wheel Configuration

```gdscript
var wheels = [
    {"freq": 1.0, "radius": 2.0, "phase": 0.0},      # Fundamental
    {"freq": 3.0, "radius": 0.8, "phase": 0.0},      # 3rd harmonic
    {"freq": 5.0, "radius": 0.4, "phase": PI / 2},   # 5th harmonic
    {"freq": 7.0, "radius": 0.2, "phase": PI / 4}    # 7th harmonic
]
```

This specific combination approximates a square wave!

## Parameters

| Property | Description |
|----------|-------------|
| `freq` | Rotation frequency (cycles per period) |
| `radius` | Wheel size |
| `phase` | Starting angle offset |

## Audio Features

- Each wheel generates a sine tone at its frequency
- Theremin-style audio follows the trace tip
- Sound triggers on quadrant crossings

## Files

| File | Purpose |
|------|---------|
| `fourier_transform_shape.gd` | Main visualization |
| `*.tscn` | Scene file |

## Usage

```gdscript
var fourier = preload("res://algorithms/wavefunctions/fouriertransformshape/fourier.tscn").instantiate()
# Modify wheels array for different shapes
add_child(fourier)
```

## Classic Fourier Shapes

| Shape | Frequencies | Amplitudes |
|-------|-------------|------------|
| **Square wave** | 1, 3, 5, 7... | 1, 1/3, 1/5, 1/7... |
| **Triangle wave** | 1, 3, 5, 7... | 1, 1/9, 1/25, 1/49... |
| **Sawtooth** | 1, 2, 3, 4... | 1, 1/2, 1/3, 1/4... |

## VR Experience

Watch wheels spin on wheels. The connecting lines show how each rotation contributes to the final path. The trace line accumulates over time, revealing the complex shape. Audio makes the frequencies audible — you can hear the Fourier series.

## Mathematical Foundation

Any periodic function f(t) can be written:
```
f(t) = Σ (aₙ cos(n·ω·t) + bₙ sin(n·ω·t))
```

The wheels visualize this sum geometrically — each wheel is one term in the series.

## Applications

- **Signal processing**: Decomposing audio/radio signals
- **Image compression**: JPEG uses discrete cosine transform
- **Physics**: Normal modes of vibration
- **Art**: Drawing complex curves mechanically (spirographs)

## See Also

- `oscillation/` — Simple harmonic motion
- `wavefunctions/` — Wave-based mathematics
- `transformation/` — Coordinate systems
