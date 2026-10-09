# L-System Ecosystem

Multiple L-System trees competing for space — emergent forest dynamics from individual growth rules.

## QFEP Connection

Competition introduces **selection pressure** on growth strategies. Tall-sparse vs wide-dense trees fight for light and space (E, conflict); survival depends on context (F, constraints). The same grammar produces different outcomes depending on neighbors. This is λ in ecology: individual rules meeting environmental feedback.

## How It Works

```
Initial:            Growing:              Competition:
    │  │  │           ╱│╲   │   ╱│╲        ╲│╱ ╲│╱ ╱│╲
    │  │  │          ╱╱│╲╲  │  ╱╱│╲╲        ╲│╳│╳│╱
    ◯  ◯  ◯          ╱ │ ╲  │  ╱ │ ╲         │ │ │
                     │ │ │  │  │ │ │         │ │ │
─────────────────  ─────────────────────  ─────────────────
  Seeds planted      Trees growing         Crowding limits
```

## Tree Strategies

| Strategy | Description | Growth Pattern |
|----------|-------------|----------------|
| `TALL_SPARSE` | Reaches for light | Few branches, vertical focus |
| `WIDE_DENSE` | Spreads out | Many branches, horizontal focus |
| `BALANCED` | Moderate approach | Even distribution |
| `AGGRESSIVE` | Fast expansion | Quick growth, unstable |
| `CONSERVATIVE` | Slow and steady | Gradual, resilient |

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `num_trees` | 5 | Trees in ecosystem |
| `tree_generations` | 4 | Growth iterations |
| `forest_radius` | 3.0 | Planting area |
| `growth_speed` | 2.0 | Animation rate |
| `show_growth_animation` | true | Animate or instant |
| `competition_enabled` | true | Enable space competition |
| `tree_step_length` | 0.25 | Segment length |
| `tree_thickness` | 0.06 | Branch thickness |

## Tree Data Structure

```gdscript
class LSystemTree:
    var position: Vector3     # World position
    var turtle: Turtle3D      # Drawing system
    var lsystem              # Grammar rules
    var strategy: int        # Growth strategy
    var growth_rate: float   # Speed modifier
    var current_generation: int
    var health: float        # Survival metric
    var color: Color         # Visual ID
```

## Competition Mechanics

When `competition_enabled`:
- Trees check for nearby branches
- Overlapping regions reduce health
- Low-health trees grow slower or die
- Space becomes a limited resource

## Files

| File | Purpose |
|------|---------|
| `ecosystem.gd` | Forest simulation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var forest = preload("res://algorithms/lsystems/Ecosystem/ecosystem.tscn").instantiate()
forest.num_trees = 10
forest.competition_enabled = true
add_child(forest)
```

## VR Experience

Watch a forest grow from seeds. Different strategies produce different forms — some trees shoot up tall, others spread wide. With competition enabled, crowded trees struggle while those with space thrive. It's natural selection in miniature.

## Emergent Behaviors

Without explicit programming, the system produces:
- **Canopy stratification**: Tall trees above, shade-tolerant below
- **Resource partitioning**: Trees find their niches
- **Edge effects**: Boundary trees have advantages
- **Succession**: Early colonizers vs late specialists

## See Also

- `lsystems/Growth/` — Single tree growth
- `emergentsystems/ecosystemsimulation2/` — Agent-based ecology
- `cellularautomata/` — Grid-based competition
