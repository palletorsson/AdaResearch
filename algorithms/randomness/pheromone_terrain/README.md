# Pheromone Terrain

Agent-modified terrain where walkers deposit pheromones and follow trails — emergent path formation.

## QFEP Connection

Pheromones create **memory in space**. Walkers move randomly (E) but are attracted to existing trails (F, positive feedback). Over time, dominant paths emerge — order from accumulated choices. The terrain literally rises where agents have walked. This is stigmergy: coordination through environment modification.

## Parameters

### Walkers
| Export | Default | Description |
|--------|---------|-------------|
| `walker_count` | 5 | Number of agents |
| `walk_speed` | 2.0 | Steps per second |
| `raise_amount` | 0.05 | Height per step |
| `max_height` | 3.0 | Maximum elevation |

### Pheromones
| Export | Default | Description |
|--------|---------|-------------|
| `pheromone_deposit` | 0.5 | Amount per step |
| `pheromone_decay_rate` | 0.2 | Decay per second |
| `pheromone_attraction` | 0.3 | Trail-following strength |
| `sensor_distance` | 2 | Sensing range |
| `pheromone_color` | Magenta | Trail visualization |

### Terrain
| Export | Default | Description |
|--------|---------|-------------|
| `border_size` | 10 | Protected edge width |

## How It Works

```
1. Walkers move semi-randomly
2. Each step deposits pheromone
3. Pheromone attracts other walkers
4. Terrain rises where walked
5. Pheromones slowly decay
6. Dominant paths emerge
```

## Files

| File | Purpose |
|------|---------|
| `pheromone_terrain.gd` | Simulation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var terrain = preload("res://algorithms/randomness/pheromone_terrain/pheromone.tscn").instantiate()
terrain.walker_count = 10
terrain.pheromone_attraction = 0.6  # Stronger trail-following
add_child(terrain)
```

## See Also

- `swarmintelligence/physarum/` — Similar trail dynamics
- `pathfinding/flow_field/` — Gradient-based navigation
