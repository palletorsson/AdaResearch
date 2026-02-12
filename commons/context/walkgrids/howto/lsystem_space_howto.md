# LSystemSpace — How to Use in Maps

## What It Is
Lindenmayer system turtle graphics rendered as a height field. Branching grammars become ridge networks — the branches are elevated, the spaces between are walkable valleys. Trees, fractals, space-filling curves, river deltas.

## Scene Path
```
res://commons/context/walkgrids/lsystem_space.tscn
```

## Drop Into a Map Scene

```gdscript
var ls = preload("res://commons/context/walkgrids/lsystem_space.tscn").instantiate()
ls.preset = LSystemSpace.LSystemPreset.TREE
ls.space_size = Vector2(25, 25)
ls.resolution = 80
ls.height_scale = 2.0
add_child(ls)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `preset` | TREE | TREE, KOCH_ISLAND, DRAGON_CURVE, SIERPINSKI, HILBERT_CURVE, RIVER_DELTA, CUSTOM |
| `axiom` | "F" | Starting string |
| `iterations` | 4 | How many times to expand rules |
| `angle_degrees` | 25.0 | Turn angle for +/- commands |
| `step_length` | 2.0 | Distance per F step |
| `branch_width` | 1.5 | Width of ridge in the height field |
| `width_decay` | 0.7 | Branches get thinner deeper in |
| `height_per_branch` | 0.3 | Height added per branch depth |
| `smooth_passes` | 3 | Gaussian smoothing for walkability |

## Preset Details

| Preset | Axiom | Rule F | Angle | Character |
|--------|-------|--------|-------|-----------|
| TREE | F | FF+[+F-F-F]-[-F+F+F] | 22.5° | Organic branching |
| KOCH_ISLAND | F-F-F-F | F-F+F+FF-F-F+F | 90° | Snowflake outline |
| DRAGON_CURVE | FX | X→X+YF+, Y→-FX-Y | 90° | Folded paper curve |
| SIERPINSKI | F-G-G | F→F-G+F+G-F, G→GG | 120° | Triangle fractal |
| HILBERT_CURVE | A | A→-BF+AFA+FB- | 90° | Space-filling |
| RIVER_DELTA | F | F[+F]F[-F]F | 25.7° | Branching rivers |

## Map Integration Examples

### Fractals Map — Branching Tree Floor
```gdscript
func _ready():
    var ls = LSystemSpace.new()
    ls.preset = LSystemSpace.LSystemPreset.TREE
    ls.space_size = Vector2(30, 30)
    ls.iterations = 4
    ls.height_scale = 1.5
    ls.smooth_passes = 4  # Extra smooth for walking
    add_child(ls)
```

### Grammar Comparison — Same Axiom, Different Rules
```gdscript
var presets = [
    LSystemSpace.LSystemPreset.TREE,
    LSystemSpace.LSystemPreset.KOCH_ISLAND,
    LSystemSpace.LSystemPreset.RIVER_DELTA,
    LSystemSpace.LSystemPreset.SIERPINSKI,
]
for i in range(presets.size()):
    var ls = LSystemSpace.new()
    ls.position.x = i * 28.0
    ls.preset = presets[i]
    ls.space_size = Vector2(24, 24)
    add_child(ls)
```

### Space-Filling Hilbert Curve
```gdscript
# A curve that visits every point — creates a maze-like terrain
var ls = LSystemSpace.new()
ls.preset = LSystemSpace.LSystemPreset.HILBERT_CURVE
ls.iterations = 4          # 4 iterations fills the space well
ls.branch_width = 2.0      # Wider corridors
ls.height_per_branch = 0.5
ls.smooth_passes = 2       # Less smoothing = more defined paths
add_child(ls)
```

### Custom L-System
```gdscript
var ls = LSystemSpace.new()
ls.preset = LSystemSpace.LSystemPreset.CUSTOM
ls.axiom = "F"
ls.rule_f = "F[+F][-F]F[+F]"
ls.angle_degrees = 30.0
ls.iterations = 5
ls.step_length = 1.5
add_child(ls)
```

### Iteration Progression
```gdscript
# Show how complexity grows with each iteration
for i in range(5):
    var ls = LSystemSpace.new()
    ls.position.x = i * 25.0
    ls.preset = LSystemSpace.LSystemPreset.TREE
    ls.iterations = i + 1  # 1, 2, 3, 4, 5
    ls.space_size = Vector2(20, 20)
    add_child(ls)
```

## Teaching Suggestions
- Start with `iterations = 1`, add one at a time to show growth
- Compare TREE (stochastic feel) with HILBERT (deterministic fill)
- Use CUSTOM mode to let students write their own rules
- RIVER_DELTA shows how simple branching creates natural drainage patterns
- SIERPINSKI demonstrates how L-systems can encode fractals

## Performance Notes
- TREE/RIVER_DELTA at iterations 4-5 are instant
- HILBERT_CURVE at iterations 5+ generates very long strings — keep ≤ 5
- DRAGON_CURVE iterations 10 generates ~2000 segments, which is fine
- `smooth_passes` 3-4 for comfortable walking, 1-2 for dramatic ridges
