# Profile Substrate

> See the signal. Watch the curve breathe.

Universal 1D continuous curve renderer. ImmediateMesh ribbon strips over a grid background. Multiple overlaid traces, vertical markers, glow passes. Built for waveforms, loss curves, noise profiles, and anything that's a function of one variable.

## Architecture

```
profile_cartridge.gd     — Base class (RefCounted): initialize(), step(), trace colors
profile_renderer.gd      — ImmediateMesh ribbon strips + grid quad + markers
profile_substrate.gd     — Manager: cartridge lifecycle, play/pause/step, config
profile_line.gdshader    — Per-vertex color + emission pulse for traces
profile_grid.gdshader    — Procedural grid lines + center axes
profile_substrate.tscn   — Minimal scene: renderer + label
```

### Scene Tree

```
ProfileSubstrate (Node3D) [profile_substrate.gd]
├── Renderer (Node3D) [profile_renderer.gd]
│   ├── GridBackground (MeshInstance3D) — QuadMesh with grid shader
│   ├── Trace_0 (MeshInstance3D) — ImmediateMesh ribbon
│   ├── Trace_1 (MeshInstance3D) — ImmediateMesh ribbon
│   └── ...
└── Label3D — algorithm display name
```

### Rendering

Each trace is drawn as a **triangle strip ribbon** with width in the Z direction:
- Multiple glow passes (wider, dimmer) for phosphor CRT feel
- Main trace at configured color
- Hot center pass (thinner, brighter) for the sharp core

**Dimensions:** 0.4m wide × 0.25m tall (readable in VR at arm's reach).

**Grid:** Procedural shader with configurable divisions, center axes highlighted.

## 16 Cartridges

### Waveforms (7)

| Cartridge | What it shows |
|-----------|--------------|
| `sine` | Pure sine wave (phosphor green, scrolling) |
| `square` | Square wave (cyan) |
| `saw` | Sawtooth wave (amber) |
| `triangle` | Triangle wave (magenta) |
| `fourier` | Harmonics building into square wave (2 traces) |
| `beat` | Two close frequencies → amplitude modulation (3 traces) |
| `lissajous` | X/Y components of Lissajous figure (2 traces) |

### Noise & Randomness (4)

| Cartridge | What it shows |
|-----------|--------------|
| `noise` | 1D Perlin noise, scrolling |
| `noise_octaves` | Octaves layering up (N+1 traces: sum + individual) |
| `random_walk` | 1D walk displacement, scrolling, auto-scaling |
| `brownian` | Brownian bridge (constrained to return to zero) |

### Statistics & ML (3)

| Cartridge | What it shows |
|-----------|--------------|
| `bell_curve` | Gaussian forming via CLT (histogram + theoretical) |
| `gradient_descent` | Ball on loss landscape with momentum + marker |
| `logistic` | Bifurcation diagram: order → chaos |

### Physics (2)

| Cartridge | What it shows |
|-----------|--------------|
| `damped` | Exponential decay oscillation + envelope |
| `spring` | Real-time spring-mass, touch to perturb |

## Map Placement

```
"profile_sine"                              # Named variant
"profile#algorithm:fourier"                 # Config syntax
"profile#algorithm:noise#samples:512"       # Higher resolution
"profile#algorithm:spring#interval:0.01"    # Faster physics
```

## Cartridge Interface

```gdscript
class_name ProfileCartridge extends RefCounted

# Traces
func get_trace_count() -> int          # how many overlaid lines
func get_trace_color(index) -> Color
func get_trace_width(index) -> float   # multiplier on base width
func get_trace_emission(index) -> float

# Display
func get_y_range() -> Vector2          # [min, max] Y values
func show_grid() -> bool
func get_x_divisions() -> int
func get_y_divisions() -> int

# Lifecycle
func initialize(sample_count) -> Array[PackedFloat32Array]
func step(traces, step_index, delta_time) -> Dictionary
func on_touch(x_normalized, traces) -> Array
```

### Step Result

```gdscript
{
    "traces": Array[PackedFloat32Array] or null,
    "markers": [{x: float, color: Color, label: String}],
    "done": bool,
    "description": String
}
```

## Registry

`commons/artifacts/registry/profile.json` — 17 entries (1 generic + 16 named variants)
