# ReactionDiffusionSpace — How to Use in Maps

## What It Is
Gray-Scott reaction-diffusion model. Two chemicals interact to create Turing patterns — spots, stripes, spirals, coral growths. Chemical B concentration becomes terrain height. Walk across the mathematics of animal coats.

## Scene Path
```
res://commons/context/walkgrids/reaction_diffusion_space.tscn
```

## Drop Into a Map Scene

```gdscript
var rd = preload("res://commons/context/walkgrids/reaction_diffusion_space.tscn").instantiate()
rd.space_size = Vector2(20, 20)
rd.resolution = 80
rd.pattern_preset = ReactionDiffusionSpace.PatternPreset.SPOTS
rd.height_scale = 2.5
rd.position = Vector3(0, 0, 0)
add_child(rd)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `pattern_preset` | SPOTS | SPOTS, STRIPES, SPIRALS, CORAL, HOLES, WORMS, CUSTOM |
| `sim_resolution` | 64 | Simulation grid (independent of mesh resolution) |
| `iterations` | 2000 | Simulation steps (more = more defined patterns) |
| `feed_rate` | 0.055 | Chemical A supply rate (F) |
| `kill_rate` | 0.062 | Chemical B decay rate (k) |
| `seed_count` | 5 | Initial disturbance points |
| `continue_simulation` | false | Keep evolving live after generation |

## Preset F/k Values

| Preset | F | k | Pattern |
|--------|---|---|---------|
| SPOTS | 0.055 | 0.062 | Mitosis-like splitting dots |
| STRIPES | 0.035 | 0.065 | Zebrafish-like lines |
| SPIRALS | 0.014 | 0.054 | Rotating spiral waves |
| CORAL | 0.060 | 0.062 | Branching coral fingers |
| HOLES | 0.039 | 0.058 | Soliton holes in uniform field |
| WORMS | 0.078 | 0.061 | Worm-like squiggly tunnels |

## Map Integration Examples

### Computational Biology Map
```gdscript
# The floor shows how Turing patterns form
func _ready():
    var rd = ReactionDiffusionSpace.new()
    rd.pattern_preset = ReactionDiffusionSpace.PatternPreset.SPOTS
    rd.space_size = Vector2(25, 25)
    rd.sim_resolution = 80
    rd.iterations = 3000
    rd.height_scale = 2.0
    add_child(rd)
```

### Preset Gallery — Walk Through All Patterns
```gdscript
var presets = [
    ReactionDiffusionSpace.PatternPreset.SPOTS,
    ReactionDiffusionSpace.PatternPreset.STRIPES,
    ReactionDiffusionSpace.PatternPreset.SPIRALS,
    ReactionDiffusionSpace.PatternPreset.CORAL,
    ReactionDiffusionSpace.PatternPreset.WORMS,
]
for i in range(presets.size()):
    var rd = ReactionDiffusionSpace.new()
    rd.position.x = i * 25.0
    rd.pattern_preset = presets[i]
    rd.space_size = Vector2(20, 20)
    rd.sim_resolution = 64
    rd.iterations = 2500
    rd.seed_value = 42
    add_child(rd)
```

### Live Evolution — Watch Patterns Form
```gdscript
var rd = ReactionDiffusionSpace.new()
rd.enable_animation = true
rd.continue_simulation = true  # Keep running the model
rd.iterations = 200            # Start with fewer iterations
rd.sim_resolution = 48         # Smaller grid for real-time
add_child(rd)
```

### Custom F/k Exploration
```gdscript
# Let players explore the F/k parameter space
var rd = ReactionDiffusionSpace.new()
rd.pattern_preset = ReactionDiffusionSpace.PatternPreset.CUSTOM
rd.feed_rate = 0.04
rd.kill_rate = 0.06
rd.iterations = 2000
add_child(rd)

# Later, change parameters and regenerate:
rd.feed_rate = 0.055
rd.kill_rate = 0.062
rd.generate_space()
```

## Teaching Suggestions
- Show how tiny F/k changes create completely different patterns
- Compare to real biological patterns (zebrafish, coral, fingerprints)
- Use `seed_count = 1` to show a single seed expanding
- Slow animation mode shows the diffusion process in real-time

## Performance Notes
- `sim_resolution` 64 with 2000 iterations takes ~2-3 seconds to generate
- `sim_resolution` 128 with 3000 iterations can take 10+ seconds — use for pre-baked maps
- `continue_simulation = true` runs 5 RD steps per frame — keep `sim_resolution` ≤ 48
- Mesh resolution and sim resolution are independent — mesh can be 100 while sim is 64 (bilinear upsampled)
