# Grid Agent System

## Overview

Grid Agents are algorithmic entities that traverse, analyze, and modify MultiMesh grid structures. They represent **queer algorithmic potential** - not enemies to eliminate, but forces to nurture, harness, and collaborate with.

> *"The split between human and alien is fictional; all of this is algorithmic continuity."*

## Core Concept

Unlike traditional game enemies, Grid Agents embody a different relationship to play:

- **Not parasitic horror** → Symbiotic algorithmic potential
- **Not enemies to exterminate** → Entities to understand and direct
- **Not biological aliens** → Pure algorithms (presented as bio-algorithmic convergence)

## Evolution System: 9 Tiers

Grid Agents evolve through a tiered skill system, progressively gaining algorithmic capabilities:

| Tier | Name | Capability | Learning |
|------|------|------------|----------|
| 1 | **COPY** | Duplicate cubes | "I can make more of what exists" |
| 2 | **TRANSLATE** | Move cubes | "I can change position" |
| 3 | **ROTATE** | Rotate structures | "I can change orientation" |
| 4 | **SCALE** | Resize structures | "I can change size" |
| 5 | **COLOR** | Change appearance | "I can change appearance" |
| 6 | **ARRAY** | Create patterns | "I can create patterns through repetition" |
| 7 | **SINE** | Wave functions | "I can use mathematical functions" |
| 8 | **RANDOM** | Generate variation | "I can generate diversity" |
| 9 | **CA** | Cellular automata | "I understand emergent complexity" |

### XP and Progression

- Agents gain XP by:
  - Consuming grid cubes: +1 XP per cube
  - Completing tasks: +5-20 XP (complexity-based)
  - Being nurtured by player: +1 XP/minute
- Unlock costs: `[0, 10, 25, 50, 100, 175, 275, 400, 600]`
- Total mastery: 600 XP

## Placing Agents in Maps

Agents are placed via the **interactables layer** in map JSON files:

```json
{
  "interactables": [
    ["gridagent:copy", " ", " "],
    [" ", "gridagent:translate:90", " "],
    [" ", " ", "gridagent:random:180:1.5:2"]
  ]
}
```

**Syntax**: `gridagent:tier[:rotation[:y_offset[:scale]]]`

**Examples**:
- `gridagent:copy` - COPY tier agent, default placement
- `gridagent:translate:90` - TRANSLATE tier, rotated 90° on Y-axis
- `gridagent:random:180:2.0` - RANDOM tier, rotated 180°, +2.0m Y offset
- `gridagent:ca:0:1.5:2.0` - CA tier, no rotation, +1.5m Y, 2x scale

### Modifier Stack (Pipeline Mode)

Agents can run an ordered modifier stack via `#` config syntax:

```json
{
  "interactables": [
    ["gridagent:copy#stack:array,mirror,twist#array_direction:x#array_count:4#array_spacing:2#mirror_axis:x#twist_axis:y#twist_angle:18#stack_radius:3"]
  ]
}
```

Supported stack ops:
- Existing: `copy`, `translate`, `rotate`, `scale`, `color`, `array`, `sine`, `random`, `ca`
- New pipeline ops: `mirror`, `twist`

Useful stack params:
- `stack_radius`
- `array_direction`, `array_count`, `array_spacing`
- `mirror_axis`, `mirror_keep_original`
- `twist_axis`, `twist_angle`

### Valid Tier Names

- `copy` - Tier 1
- `translate` - Tier 2
- `rotate` - Tier 3
- `scale` - Tier 4
- `color` - Tier 5
- `array` - Tier 6
- `sine` - Tier 7
- `random` - Tier 8
- `ca` - Tier 9

## File Structure

```
commons/hazards/gridagent/
├── grid_agent_base.gd          # Base CharacterBody3D class
├── grid_agent_base.tscn        # Base scene template
├── evolution_tiers.gd          # Tier system & XP tracking
├── grid_interface.gd           # Grid interaction utilities
├── grid_operations.gd          # Tier operation implementations
├── variants/                   # Tier-specific scene files
│   ├── grid_agent_copy.tscn
│   ├── grid_agent_translate.tscn
│   ├── grid_agent_rotate.tscn
│   ├── grid_agent_scale.tscn
│   ├── grid_agent_color.tscn
│   ├── grid_agent_array.tscn
│   ├── grid_agent_sine.tscn
│   ├── grid_agent_random.tscn
│   └── grid_agent_ca.tscn
└── README.md                   # This file
```

## Agent Behavior

### AI States

1. **WANDERING** - Random walk through grid, searching for work
2. **FEEDING** - Consuming grid cubes for energy (gains XP)
3. **WORKING** - Applying tier operations to grid
4. **CAPTURED** - Held by algo-gun, awaiting direction
5. **DIRECTED** - Following player-assigned task

### Tier Operations

Each tier modifies the grid differently:

#### Tier 1: COPY
Finds a nearby cube and duplicates it in an adjacent cell.

```gdscript
# Example usage
var agent = GridAgent.new()
agent.set_tier("copy")
# Agent will randomly copy cubes when working
```

#### Tier 2: TRANSLATE
Moves cubes from one position to another.

#### Tier 3: ROTATE
Rotates a structure 90° around an axis.

#### Tier 4: SCALE
*(Not yet implemented)* Resizes structures.

#### Tier 5: COLOR
Changes cube colors in a region.

#### Tier 6: ARRAY
*(Not yet implemented)* Creates linear/grid arrays.

#### Tier 7: SINE
*(Not yet implemented)* Applies wave transformations.

#### Tier 8: RANDOM
*(Not yet implemented)* Adds controlled randomness.

#### Tier 9: CA
Applies cellular automata rules (growth, erosion).

## Integration with Grid System

The Grid Agent system integrates with the existing grid infrastructure:

### GridInteractablesComponent

Handles `gridagent:` prefix in interactables layer:

```gdscript
# In commons/grid/GridInteractablesComponent.gd
if lookup_name.begins_with("gridagent:"):
    var y_pos = structure_component.find_highest_y_at(x, z)
    if _place_grid_agent(x, y_pos, z, lookup_name, total_size, overrides, config_data):
        interactable_count += 1
```

### Grid Interface

Utilities for agents to interact with different grid types:

- `GridStructureComponent` (commons/grid/)
- `CellularAutomata3D` (algorithms/cellularautomata/)
- `CAGrid` (algorithms/cellularautomata/)

Grid operations are abstracted to work with any system.

## Public API

### GridAgent Methods

```gdscript
# Set agent tier
agent.set_tier("translate")

# Capture/release (called by algo-gun)
agent.capture()
agent.release()

# Direct to position
agent.direct_to_position(Vector3(5, 2, 3))

# Award evolution points
agent.add_xp(50)
```

### GridOperations Static Methods

```gdscript
# Tier 1: Copy
GridOperations.copy_cube(grid, source, target)

# Tier 2: Translate
GridOperations.translate_cube(grid, from, to)

# Tier 3: Rotate
GridOperations.rotate_structure_90(grid, center, axis, radius)

# Tier 5: Color
GridOperations.colorize_region(grid, center, color, radius)

# Tier 9: CA
GridOperations.apply_ca_step(grid, center, "growth", radius)
```

### GridInterface Utilities

```gdscript
# Find grid at position
var grid = GridInterface.get_grid_at_position(world_pos)

# Cell operations
var cell = GridInterface.get_cell_at_position(grid, world_pos)
var occupied = GridInterface.is_cell_occupied(grid, cell)
GridInterface.place_cube_at_cell(grid, cell, Color.RED)
GridInterface.remove_cube_at_cell(grid, cell)

# Neighbors
var moore = GridInterface.get_neighbors_moore(cell)  # 26 neighbors
var von_neumann = GridInterface.get_neighbors_von_neumann(cell)  # 6 neighbors
var count = GridInterface.count_occupied_neighbors_moore(grid, cell)
```

### EvolutionTiers Utilities

```gdscript
# Parse tier
var tier = EvolutionTiers.parse_tier("translate")  # Returns Tier.TIER_2_TRANSLATE

# Get info
var name = EvolutionTiers.get_display_name(tier)  # "Translate"
var desc = EvolutionTiers.get_description(tier)   # "I can change position"
var color = EvolutionTiers.get_color(tier)        # Color(0.5, 1.0, 0.5)

# XP system
var cost = EvolutionTiers.get_unlock_cost(tier)
var unlocked = EvolutionTiers.is_tier_unlocked(tier, current_xp)
var max_tier = EvolutionTiers.get_max_tier_for_xp(current_xp)
```

## Testing

### Test Map

A test map is available at `commons/maps/test_gridagent/map_data.json`:

- 9x9 grid with simple structure
- One COPY-tier agent at center
- Demonstrates wandering, feeding, and copying behaviors

Load it in-game to observe agent behavior.

### Development Notes

- Agents create their own collision shapes and meshes in `_ready()`
- Thought labels show current state and tier description
- Colors match tier (see `EvolutionTiers.TIER_COLORS`)
- Operations execute on timers (default: every 2 seconds)

## Future Extensions

### Planned Features

1. **Algo-Gun Integration** - Capture and direct agents
2. **More Operations** - Complete Tier 4-9 implementations
3. **Agent Variants** - Specialized agents (e.g., "Erosion Agent", "Crystal Agent")
4. **Swarm Coordination** - Multiple agents working together
5. **Evolution Animations** - Visual effects for tier-ups
6. **Skill Plugins** - Extensible system for custom operations

### Extensibility

The system is designed for easy extension:

- Add new tiers in `EvolutionTiers`
- Implement operations in `GridOperations`
- Create variant scenes in `variants/`
- Register custom grid types in `GridInterface`

## Philosophical Framework

Grid Agents embody **algorithmic continuity without binary opposition**:

- **Not Human vs Alien** → All algorithms, different expressions
- **Not Order vs Chaos** → Growth and erosion as complementary forces
- **Not Control vs Freedom** → Direction and autonomy in dialogue

The agent isn't conquered but **collaborated with**:

- Capturing ≠ domination (it's communication)
- Directing ≠ enslavement (it's shared purpose)
- Nurturing → mutual transformation

Like the headcrab "reconfigures embodiment," the Grid Agent **reconfigures geometric space**, and together player and agent **co-create new structures**.

## Credits

Based on the `BlockBuilderEntity` prototype, evolved for grid-specific interactions. Part of the AdaResearch project's exploration of algorithmic embodiment and queer potential in computational space.

