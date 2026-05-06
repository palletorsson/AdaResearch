# CellularAutomataSpace — How to Use in Maps

## What It Is
Runs cellular automata (Game of Life and variants) and converts the accumulated generations into geological-layer terrain. Living cells become ridges, dead cells become valleys. Walk through the fossil record of emergent computation.

## Scene Path
```
res://commons/context/walkgrids/cellular_automata_space.tscn
```

## Drop Into a Map Scene

### Quick Setup
```gdscript
var ca = preload("res://commons/context/walkgrids/cellular_automata_space.tscn").instantiate()
ca.space_size = Vector2(25, 25)
ca.resolution = 80
ca.rule_set = CellularAutomataSpace.RuleSet.GAME_OF_LIFE
ca.generations = 50
ca.height_scale = 2.0
ca.position = Vector3(0, 0, 0)
add_child(ca)
```

### Via Script Attachment
1. Add `Node3D` to your scene
2. Attach `CellularAutomataSpace.gd`
3. Configure in Inspector

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `rule_set` | GAME_OF_LIFE | B3/S23 classic. Also: HIGHLIFE, DAY_AND_NIGHT, DIAMOEBA, MAZE, CAVE |
| `initial_density` | 0.4 | % alive at start (0.3-0.5 is interesting) |
| `generations` | 50 | How many steps to simulate |
| `accumulate_history` | true | Stack all generations into height (geological layers) |
| `smooth_passes` | 2 | Box blur passes for walkability |
| `alive_height` | 1.0 | Height per alive cell |
| `enable_animation` | false | Live evolution — terrain changes in real-time |
| `generation_speed` | 5.0 | Generations per second (when animated) |

## Map Integration Examples

### Emergent Systems Map — CA as Teaching Floor
```gdscript
# The floor IS the lesson: Game of Life running beneath your feet
func _ready():
    var ca = CellularAutomataSpace.new()
    ca.space_size = Vector2(30, 30)
    ca.rule_set = CellularAutomataSpace.RuleSet.GAME_OF_LIFE
    ca.generations = 80
    ca.accumulate_history = true
    ca.smooth_passes = 3      # Extra smooth for comfortable walking
    ca.height_scale = 1.2
    add_child(ca)
```

### Side-by-Side Ruleset Comparison
```gdscript
# Show 4 different CA rules next to each other
var rules = [
    CellularAutomataSpace.RuleSet.GAME_OF_LIFE,
    CellularAutomataSpace.RuleSet.MAZE,
    CellularAutomataSpace.RuleSet.CAVE,
    CellularAutomataSpace.RuleSet.DIAMOEBA,
]
for i in range(rules.size()):
    var ca = CellularAutomataSpace.new()
    ca.position.x = i * 28.0
    ca.rule_set = rules[i]
    ca.space_size = Vector2(24, 24)
    ca.generations = 60
    ca.seed_value = 42  # Same seed for fair comparison
    add_child(ca)
```

### Live Evolution Mode
```gdscript
# Terrain evolves while you walk on it
var ca = CellularAutomataSpace.new()
ca.enable_animation = true
ca.generation_speed = 3.0  # Slow enough to feel, fast enough to see
ca.accumulate_history = false  # Only show current state
ca.smooth_passes = 1
add_child(ca)
```

### Cave Generator
```gdscript
# Use CAVE rules for dungeon-like terrain
var cave = CellularAutomataSpace.new()
cave.rule_set = CellularAutomataSpace.RuleSet.CAVE
cave.initial_density = 0.45
cave.generations = 15  # CAVE converges fast
cave.height_scale = 3.0
cave.smooth_passes = 1  # Less smoothing = more dramatic caves
add_child(cave)
```

## Teaching Suggestions
- Start with `generations = 1`, then increment to show evolution
- Use `accumulate_history = true` to show how simple rules create complex geology
- Compare MAZE (connected corridors) vs CAVE (open chambers) vs GAME_OF_LIFE (scattered islands)
- Set `seed_value` identical across multiple spaces to show how rules change outcome

## Performance Notes
- Resolution 80 + 100 generations is fine on desktop
- For VR: resolution 60, generations 50
- Animation mode updates mesh every frame — keep resolution ≤ 60
- `smooth_passes` > 3 adds very little visual difference
