# Physarum Simulation

Slime mold agents that self-organize into efficient transport networks — emergent intelligence without a brain.

## QFEP Connection

Physarum polycephalum is a **single-celled organism** that solves optimization problems (shortest path, network design) through purely local chemical signaling. No central control, no memory, no planning — just λ at the edge of chaos. The slime mold embodies QFEP: it maintains identity (F) while constantly reshaping to maximize resource flow (E).

## How It Works

```
┌─────────────────────────────────────────┐
│  Agent Model (Jeff Jones, 2010)         │
│                                         │
│     [L]     [C]     [R]                 │
│       \      |      /                   │
│        \     |     /   ← Sensors        │
│         \    |    /                     │
│          \   |   /                      │
│           \  |  /                       │
│            [Agent]                      │
│               ↓                         │
│            Movement                     │
└─────────────────────────────────────────┘
```

Each agent:
1. **Senses** trail concentration at three points (left, center, right)
2. **Turns** toward strongest concentration (or randomly if center is weakest)
3. **Moves** forward
4. **Deposits** trail chemical at current position

The trail grid:
- **Decays** over time (0.95 factor)
- **Diffuses** to neighbors (averaging)
- **Attracts** agents, creating positive feedback loops

## Components

| File | Purpose |
|------|---------|
| `PhysarumAgent.gd` | Individual agent behavior |
| `PhysarumGrid.gd` | Trail data structure (decay, diffuse) |
| `PhysarumColony.gd` | Colony manager, spawning, visualization |
| `physarum_veins.gdshader` | Trail visualization shader |

## Parameters

### Agent (PhysarumAgent.gd)
| Export | Default | Description |
|--------|---------|-------------|
| `speed` | 3.0 | Movement speed |
| `sensor_angle` | 0.785 | Angle between sensors (45°) |
| `turn_angle` | 0.785 | Rotation per turn (45°) |
| `sensor_dist` | 3.0 | How far sensors sample |
| `deposit_amount` | 5.0 | Trail deposited per step |

### Colony (PhysarumColony.gd)
| Export | Default | Description |
|--------|---------|-------------|
| `num_agents` | 500 | Total agents in colony |
| `grid_resolution` | 256 | Trail grid size |
| `terrain_size` | (50, 50) | World dimensions |

### Grid (PhysarumGrid.gd)
| Variable | Default | Description |
|----------|---------|-------------|
| `decay_rate` | 0.95 | Trail evaporation (higher = thinner trails) |
| `diffuse_rate` | 0.5 | Trail spreading |

## Emergent Behaviors

Given enough time, the colony:
- **Finds shortest paths** between food sources
- **Forms efficient networks** minimizing total length
- **Adapts** when food sources move
- **Recreates** the Tokyo rail network (famous 2010 experiment)

## Files

| File | Purpose |
|------|---------|
| `PhysarumAgent.tscn` | Agent scene |
| `PhysarumColony.tscn` | Full simulation scene |

## Usage

```gdscript
var colony = preload("res://algorithms/swarmintelligence/physarum/PhysarumColony.tscn").instantiate()
colony.num_agents = 1000
add_child(colony)
```

## VR Experience

Watch the slime mold grow from above. Place food sources (attractors) and observe how the network reorganizes to connect them. The trails pulse with activity — you're watching distributed computation in real-time.

## Scientific Background

*Physarum polycephalum* (many-headed slime mold) can:
- Solve mazes
- Design efficient networks
- Anticipate periodic events
- Make risk-averse decisions

All without neurons. This challenges assumptions about intelligence and computation.

## See Also

- `emergentsystems/` — Other self-organizing systems
- `steering/` — Agent-based movement
- `graphtheory/` — Network optimization
