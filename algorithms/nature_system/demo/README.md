# Nature System Demo

Visual test scene for the Nature System. Spawns critters from all four kingdoms (Tree, Creature, Flower, Fungus) in a grid layout so you can inspect what the morphology generators produce.

## Controls

| Key | Action |
|-----|--------|
| `1`–`4` | Spawn a random critter (1=tree, 2=creature, 3=flower, 4=fungus) |
| `R` | Randomize all critters (new DNA, same positions) |
| `E` | Run one evolution step |
| `Space` | Spawn a mixed population (clears existing) |
| `C` | Clear all critters |
| `L` | Cycle LOD (0–3) and rebuild all |
| `+`/`-` | Zoom camera in/out |
| `H` | Toggle hybrid mode (spawn body_type between kingdoms) |

## Configuration

| Export | Default | Description |
|--------|---------|-------------|
| `grid_rows` | 4 | Rows per kingdom |
| `grid_cols` | 4 | Columns per kingdom |
| `grid_spacing` | 3.0 | Distance between critters |
| `initial_lod` | 1 | Starting LOD level (0=highest, 3=lowest) |
| `auto_populate` | true | Spawn on ready |
| `auto_evolve` | false | Run evolution automatically |
| `evolve_interval` | 15.0 | Seconds between evolution steps |

## Files

- `nature_system_demo.gd` — Main controller: creates spawner, evolution system, and transmutation manager; handles keyboard input.
- `nature_system_demo.tscn` — Scene with CritterRoot, Camera3D, and UI overlay.

See the parent [Nature System README](../README.md) for architecture and system overview.
