# Pathfinding

Find the way. A* is just the beginning.

## QFEP Connection

Pathfinding is **F-minimization** — find the shortest/cheapest path. But real navigation involves uncertainty: flow fields handle many agents, potential fields create smooth motion. The best path isn't always the shortest; sometimes you explore (E) to find better routes.

## Contents

| File | Description |
|------|-------------|
| `FlowGrid.gd` | Grid-based flow field data structure |
| `FlowFieldMain.gd` | Flow field computation and management |
| `FlowAgent.gd` | Agent that follows flow field |
| `FieldVisualizer.gd` | Visualize flow vectors |

## Key Concepts

1. **Graph search** — Nodes, edges, costs
2. **A*** — Best-first search with heuristic: f(n) = g(n) + h(n)
3. **Dijkstra** — A* with h(n) = 0 (no heuristic)
4. **Flow fields** — Precomputed direction at each cell
5. **Potential fields** — Attract to goal, repel from obstacles
6. **Navigation mesh** — Walkable polygon regions

## Flow Fields

Instead of computing paths per-agent, compute direction everywhere once:

```
┌─────────────────┐
│ ↘ ↓ ↓ ↓ ↙      │
│ → ↓ ↓ ↓ ←      │
│ → → ◎ ← ←      │  ◎ = goal
│ → ↑ ↑ ↑ ←      │
│ ↗ ↑ ↑ ↑ ↖      │
└─────────────────┘
```

Agents just follow local arrows. Works for thousands of agents.

## A* vs Flow Field

| A* | Flow Field |
|----|------------|
| Per-agent computation | One-time computation |
| Optimal path | Locally optimal |
| Few agents | Many agents |
| Dynamic goals | Static goals |

## VR Experience

- Watch pathfinding solve mazes
- See flow field vectors in 3D
- Place obstacles, watch paths update
- Be surrounded by navigating agents

## Files

- 4 GDScript files
- 2 scene files
