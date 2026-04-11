# Maze Spinner

Crystalline core that generates a rotating 5x5 procedural maze around itself.

## Behavior

Extends `HazardCreatureBase`. Procedural generation sequence hazard.

- Generates a random 5x5 maze using procedural algorithms
- Maze walls are thin BoxMesh segments that rotate around the core
- Rotation speed increases during CHASE state
- Regenerates with a new random seed every 8.0 seconds
- Contact with spinning walls deals damage

## Files

| File | Purpose |
|------|---------|
| `maze_spinner.gd` | Main script — maze generation, rotation, regeneration |
| `maze_spinner.tscn` | Scene |
