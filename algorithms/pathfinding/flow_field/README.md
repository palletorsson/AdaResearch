# Flow Field Pathfinding

Hundreds of agents navigate simultaneously using a shared vector field — no individual path calculations needed.

## QFEP Connection

Flow fields are **pre-computed order** — the entire field stores the "answer" to navigation. Individual agents follow local vectors without global knowledge, yet all reach the goal. This is F (structure) enabling massive E (many independent agents) without chaos.

## How It Works

```
1. Cost Field        2. Integration Field    3. Vector Field
┌─────────────┐      ┌─────────────┐         ┌─────────────┐
│ 1 1 255 1 1 │      │ 5 4 ∞  6 7 │         │ → → ■ ← ← │
│ 1 1 255 1 1 │  →   │ 4 3 ∞  5 6 │    →    │ → → ■ ← ← │
│ 1 1 1   1 1 │      │ 3 2 1  2 3 │         │ → → ↓ ← ← │
│ 1 1 1   1 1 │      │ 4 3 2  1 2 │         │ → → ↓ ← ← │
│ 1 1 1  [T]1 │      │ 5 4 3  2 1 │         │ → → ↘ ← 0 │
└─────────────┘      └─────────────┘         └─────────────┘
    Costs             Distance to Target      Direction to Go
```

Three fields:
1. **Cost Field**: Movement difficulty (1=easy, 255=wall)
2. **Integration Field**: Dijkstra distances from target
3. **Vector Field**: Direction toward lower integration values

## Components

| File | Purpose |
|------|---------|
| `FlowGrid.gd` | Field computation and storage |
| `FlowAgent.gd` | Agent steering behavior |
| `FieldVisualizer.gd` | Arrow visualization |
| `FlowFieldMain.gd` | Demo orchestration |

## Scenarios

The demo cycles through:

| Mode | Description |
|------|-------------|
| 0 | Open field, target at center |
| 1 | Obstacles blocking paths |
| 2 | Moving target |
| 3 | Multiple targets |
| 4 | Maze-like walls |
| 5 | Perlin noise field (no target) |

## Agent Behavior

```gdscript
# 1. Look up vector at current position
var desired_dir = grid.get_vector(position)

# 2. Steer toward desired direction
var target_vel = desired_dir * speed
velocity = velocity.lerp(target_vel, steer_force * delta)

# 3. Move
move_and_slide()
```

Agents don't pathfind individually — they just follow the field.

## Parameters

### Grid
| Variable | Default | Description |
|----------|---------|-------------|
| `width` / `height` | 40 | Grid dimensions |
| `cell_size` | 1.0 | World units per cell |

### Agent
| Variable | Default | Description |
|----------|---------|-------------|
| `speed` | 8.0 | Movement speed |
| `steer_force` | 20.0 | Turning responsiveness |

## Files

| File | Purpose |
|------|---------|
| `FlowFieldMain.tscn` | Demo scene |
| `FlowAgent.tscn` | Agent prefab |

## Usage

```gdscript
var flow = preload("res://algorithms/pathfinding/flow_field/FlowFieldMain.tscn").instantiate()
add_child(flow)
```

## Performance

Flow fields excel when:
- Many agents need paths to same target
- Target changes infrequently
- Real-time individual pathfinding is too expensive

Computation is O(n) for n cells, but only needed when target/obstacles change.

## VR Experience

Watch 200 agents stream toward the target, flowing around obstacles like water. The arrow visualization shows the underlying field — every agent's next move is predetermined by its position. Change scenarios to see how the field reshapes.

## See Also

- `steering/noc_ch05/noc_5_04_flow_field_vr` — Flow field following
- `transformation/vector_field/` — Decorative vector fields
- `graphtheory/` — Graph-based pathfinding
