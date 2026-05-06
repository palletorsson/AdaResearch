# Color Trails

VR hand-tracking color trails — spline-smoothed ribbons that follow your hands through space with gradient coloring and glow effects.

## QFEP Connection

Trails make **movement visible**. The ephemeral gesture (E, transient) leaves a colored trace (F, recorded). The `trail_lifetime` parameter controls how long the past persists. Short lifetimes = pure present; long lifetimes = accumulated history. λ as temporal perception.

## How It Works

```
Hand movement:
    ·→·→·→·→·
      ↘   ↗
       ·→·

Trail ribbon:
    ════════════╗
      ╲       ╱  ║
       ════════╝

Spline-smoothed, gradient-colored, fading with age.
```

Features:
- **Per-hand gradients**: Different colors for left/right
- **Spline smoothing**: Curves instead of jagged lines
- **Width/alpha curves**: Trails taper and fade
- **Additive glow**: Bright, ethereal appearance
- **Trigger activation**: Draw only when pressing

## Parameters

### Trail Settings
| Export | Default | Description |
|--------|---------|-------------|
| `trail_max_points` | 256 | Maximum trail length |
| `trail_lifetime` | 1.75 | Seconds before fading |
| `min_sample_distance` | 0.01 | Minimum point spacing |
| `base_width` | 0.08 | Trail ribbon width |
| `only_when_trigger_pressed` | true | Require trigger input |

### Smoothing
| Export | Default | Description |
|--------|---------|-------------|
| `smooth_spline` | true | Enable spline interpolation |
| `smooth_samples_per_segment` | 6 | Spline resolution |
| `ribbon_jitter` | 0.002 | Slight randomization |

### Appearance
| Export | Default | Description |
|--------|---------|-------------|
| `left_gradient` | Gradient | Left hand color ramp |
| `right_gradient` | Gradient | Right hand color ramp |
| `width_curve` | Curve | Width over trail length |
| `alpha_curve` | Curve | Opacity over trail length |
| `additive_glow` | true | Bright blending mode |
| `disable_depth_test` | false | Always visible |

### Input
| Export | Description |
|--------|-------------|
| `left_hand_path` | NodePath to left controller |
| `right_hand_path` | NodePath to right controller |

## Files

| File | Purpose |
|------|---------|
| `color_trails.gd` | Trail generation and rendering |
| `color_trails.tscn` | Scene with default setup |

## Usage

```gdscript
var trails = preload("res://algorithms/color/colortrails/color_trails.tscn").instantiate()
trails.trail_lifetime = 3.0  # Longer trails
trails.base_width = 0.12  # Thicker ribbons
trails.left_hand_path = $XROrigin3D/LeftHand
trails.right_hand_path = $XROrigin3D/RightHand
add_child(trails)
```

## VR Experience

Press trigger and move your hands. Colored ribbons flow from your fingertips, smoothly curving through space. Left and right hands leave different colored trails. The ribbons fade gracefully, creating ephemeral light paintings in the air.

## Technical Notes

- Uses `ArrayMesh` for dynamic ribbon geometry
- Spline interpolation via Catmull-Rom or similar
- Additive blending for glow effect
- Points stored with position, age, and velocity

## Gradient Suggestions

| Left Hand | Right Hand | Mood |
|-----------|------------|------|
| Pink → Purple | Cyan → Blue | Synthwave |
| Red → Orange | Blue → White | Fire & Ice |
| Green → Yellow | Purple → Pink | Queer palette |
| White → White | White → White | Pure light |

## See Also

- `drawing/` — Persistent drawing tools
- `postprocessing/` — Other visual effects
- `oscillation/` — Rhythmic movement patterns
