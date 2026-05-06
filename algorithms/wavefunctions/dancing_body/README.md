# Dancing Body

Humanoid character with wave-function-driven animation — bodies moving to mathematical rhythms.

## QFEP Connection

Dance is **wave functions made flesh**. Sine and cosine govern oscillation — the same math describes pendulums, springs, and bodily movement. The `frequency` and `amplitude` parameters control the mathematical dance. This is λ embodied: form (skeleton) animated by function (waves).

## How It Works

```
Standard animation:        Sine/cosine overlay:
    ○ ← Head                    ○ ← Head wobbles
   ╱│╲                         ╱│╲
    │                       ← │ → ← Torso sways
   ╱ ╲                         ╱ ╲
                            ↙   ↘ ← Limbs oscillate

Skeleton bones driven by periodic functions.
```

## Parameters

### Animation
| Export | Default | Description |
|--------|---------|-------------|
| `animation_speed` | 1.0 | Overall speed |
| `blend_speed` | 2.0 | Transition smoothness |

### Display
| Export | Default | Description |
|--------|---------|-------------|
| `show_body` | true | Mesh visibility |

### Wave Animation
| Export | Default | Description |
|--------|---------|-------------|
| `use_sine_cosine_animation` | false | Enable wave mode |
| `sine_amplitude` | 0.5 | Vertical motion amount |
| `cosine_amplitude` | 0.5 | Horizontal motion amount |
| `frequency` | 1.0 | Oscillation rate |

## Mathematical Movement

When `use_sine_cosine_animation` is enabled:
```gdscript
bone_offset.x = cosine_amplitude * cos(frequency * time)
bone_offset.y = sine_amplitude * sin(frequency * time)
```

Different bones can have:
- Phase offsets (creating wave propagation)
- Different amplitudes (larger for limbs)
- Different frequencies (harmonics)

## Components

| Component | Purpose |
|-----------|---------|
| `player.glb` | Character mesh with skeleton |
| `Skeleton3D` | Bone hierarchy |
| `AnimationTree` | Animation blending |
| `_bone_trackers` | Per-bone wave parameters |

## Files

| File | Purpose |
|------|---------|
| `dancing_body.gd` | Animation controller |
| `player.glb` | Character model |
| `*.tscn` | Scene file |

## Usage

```gdscript
var dancer = preload("res://algorithms/wavefunctions/dancing_body/dancing_body.tscn").instantiate()
dancer.use_sine_cosine_animation = true
dancer.frequency = 2.0  # Faster dance
dancer.sine_amplitude = 0.8  # More dramatic
add_child(dancer)
```

## VR Experience

Watch the body move. In wave mode, the movement is purely mathematical — predictable yet organic-looking. The same equations that describe waves in water describe the swaying of hips and shoulders. Dance is physics.

## Animation Modes

| Mode | Description |
|------|-------------|
| **Standard** | Plays imported GLB animations |
| **Wave** | Bones driven by sine/cosine |
| **Blended** | Mix of both |

## See Also

- `oscillation/` — Pure wave mathematics
- `computationalbiology/morphobody/` — Body simulation
- `joint/08_character_ragdoll/` — Physics-based bodies
