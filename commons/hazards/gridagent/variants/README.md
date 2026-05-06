# Grid Agent Variants

Preset scene files for each of the 9 Grid Agent tiers. Each `.tscn` instances the base `grid_agent_base.tscn` with the tier pre-configured.

## Scenes

| File | Tier | Capability |
|------|------|------------|
| `grid_agent_copy.tscn` | 1 — COPY | Duplicate cubes |
| `grid_agent_translate.tscn` | 2 — TRANSLATE | Move cubes |
| `grid_agent_rotate.tscn` | 3 — ROTATE | Rotate structures |
| `grid_agent_scale.tscn` | 4 — SCALE | Resize structures |
| `grid_agent_color.tscn` | 5 — COLOR | Change appearance |
| `grid_agent_array.tscn` | 6 — ARRAY | Create patterns |
| `grid_agent_sine.tscn` | 7 — SINE | Wave functions |
| `grid_agent_random.tscn` | 8 — RANDOM | Generate variation |
| `grid_agent_ca.tscn` | 9 — CA | Cellular automata |

## Usage

Placed via map interactables layer as `gridagent:<tier>`. See parent README for full syntax.
