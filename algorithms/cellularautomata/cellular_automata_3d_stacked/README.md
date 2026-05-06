# Cellular Automata 3D Stacked

1D CA rules extruded into 3D over time.

## QFEP Connection

This converts **time into space**: each generation of the 1D cellular automaton becomes a new layer in 3D. Rule 110 becomes a walkable sculpture. Computation becomes architecture.

## The Algorithm

1. Start with a seed pattern (4×4 grid at base)
2. **Phase 1 (OUT)**: Expand outward using CA rules
3. **Phase 2 (UP)**: Stack new layers upward
4. Each generation adds cubes based on neighbor states

```
Time →

Gen 0:  ■         Layer 0
Gen 1:  ■■        Layer 0 (expanded)
Gen 2:  ■■■       Layer 0 (expanded)
Gen 3:   ■        Layer 1 (stacked)
Gen 4:  ■■        Layer 1 (expanded)
...
```

## Growth Phases

| Phase | Behavior |
|-------|----------|
| OUT | Expand horizontally based on CA rules |
| UP | Move to next Y layer, reset horizontal |

## Parameters

```gdscript
@export var grid_size = 20              # Grid dimensions
@export var generation_interval = 0.5   # Seconds between generations
```

## VR Experience

Watch the CA grow from a seed into a layered structure. Walk through the emerging architecture. Each layer is a frozen moment of the automaton's evolution.

## Files

- `CellularAutomata3DStacked.gd` — Stacked growth algorithm
- `CellularAutomata3DStacked.tscn` — Scene setup
