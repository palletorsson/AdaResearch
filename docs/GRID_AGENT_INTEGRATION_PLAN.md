# Grid Agent Integration Plan

> Scope note: this file documents base integration (`gridagent:tier` placement).
> For the broader two-system roadmap (GridModifierAgent + ArtifactSpatialFitPlanner + Blender-style modifier pipeline), see:
> `docs/GRID_MODIFIER_AND_SPATIAL_FIT_PLAN.md`

## Overview
Integrate Grid Agents into the existing AdaResearch grid/map system using the `gridagent:tier` syntax in the interactables layer of map JSON files.

## Integration Strategy

### 1. Use Interactables Layer (RECOMMENDED)

Grid Agents will be placed via the **interactables layer** in map JSON, using a special `gridagent:` prefix:

```json
{
  "layers": {
    "structure": [["1", "1", "1"], ...],
    "utilities": [[" ", " ", " "], ...],
    "interactables": [
      ["gridagent:copy", " ", " "],
      [" ", "gridagent:translate:90", " "],
      [" ", " ", "gridagent:random:180:1.5"]
    ]
  }
}
```

**Syntax**: `gridagent:tier[:rotation[:y_offset[:scale]]]`

**Examples**:
- `gridagent:copy` - COPY tier agent, default placement
- `gridagent:translate:90` - TRANSLATE tier, rotated 90° on Y-axis
- `gridagent:random:180:2.0` - RANDOM tier, rotated 180°, +2.0m Y offset
- `gridagent:ca:0:1.5:2.0` - CA tier, no rotation, +1.5m Y, 2x scale

**Tiers** (matching evolution system):
- `copy` - Tier 1: Copy operations
- `translate` - Tier 2: Translation
- `rotate` - Tier 3: Rotation
- `scale` - Tier 4: Scaling
- `color` - Tier 5: Color manipulation
- `array` - Tier 6: Array/pattern generation
- `sine` - Tier 7: Wave functions
- `random` - Tier 8: Randomness
- `ca` - Tier 9: Cellular automata

### 2. Modify GridInteractablesComponent.gd

Add special handling for `gridagent:` prefix (similar to existing `mc:` handling):

```gdscript
# In generate_interactables(), around line 238:
if lookup_name.begins_with("gridagent:"):
    var y_pos = structure_component.find_highest_y_at(x, z)
    if utilities_component and utilities_component.has_utility_at(x, y_pos, z):
        y_pos += 1
        
    if _place_grid_agent(x, y_pos, z, lookup_name, total_size, overrides, config_data):
        interactable_count += 1
    else:
        placement_errors.append("Failed to place grid agent '%s' at (%d,%d,%d)" % [lookup_name, x, y_pos, z])
    continue
```

Add new method `_place_grid_agent()`:

```gdscript
func _place_grid_agent(x: int, y: int, z: int, lookup_name: String, total_size: float, overrides: Dictionary = {}, config_data: Dictionary = {}) -> bool:
    # Parse: gridagent:tier
    var parts = lookup_name.split(":")
    if parts.size() < 2:
        print("GridInteractablesComponent: Invalid grid agent format: %s" % lookup_name)
        return false
    
    var tier = parts[1].to_lower()  # copy, translate, rotate, etc.
    
    # Load appropriate agent scene based on tier
    var scene_path = "res://commons/hazards/gridagent/grid_agent_%s.tscn" % tier
    if not ResourceLoader.exists(scene_path):
        # Fallback to base agent
        scene_path = "res://commons/hazards/gridagent/grid_agent_base.tscn"
    
    if not ResourceLoader.exists(scene_path):
        print("GridInteractablesComponent: Grid agent scene not found: %s" % scene_path)
        return false
    
    var agent_scene = load(scene_path)
    var agent = agent_scene.instantiate()
    
    # Position
    var position = Vector3(x, y, z) * total_size
    agent.position = position
    
    # Apply overrides (rotation, y_offset, scale)
    if overrides.has("rotation_y_degrees"):
        agent.rotation_degrees.y = float(overrides.get("rotation_y_degrees", 0.0))
    if overrides.has("y_position"):
        agent.position.y += float(overrides.get("y_position", 0.0))
    if overrides.has("uniform_scale"):
        var s = float(overrides.get("uniform_scale", 1.0))
        agent.scale = Vector3.ONE * s
    
    # Set agent tier via metadata
    agent.set_meta("agent_tier", tier)
    agent.set_meta("spawn_position", Vector3i(x, y, z))
    
    # Initialize agent if it has setup method
    if agent.has_method("set_tier"):
        agent.set_tier(tier)
    
    # Add to scene
    parent_node.add_child(agent)
    interactable_objects[Vector3i(x, y, z)] = agent
    
    print("  ✅ Placed grid agent '%s' at (%d,%d,%d)" % [tier, x, y, z])
    return true
```

### 3. File Structure

```
res://commons/hazards/gridagent/
├── grid_agent_base.gd              # Base class for all agents
├── grid_agent_base.tscn            # Base scene
├── evolution_tiers.gd              # Tier definitions and XP system
├── grid_interface.gd               # Interface to MultiMesh grids
├── grid_operations.gd              # Operation implementations
│
├── variants/
│   ├── grid_agent_copy.tscn       # Tier 1
│   ├── grid_agent_translate.tscn  # Tier 2
│   ├── grid_agent_rotate.tscn     # Tier 3
│   ├── grid_agent_scale.tscn      # Tier 4
│   ├── grid_agent_color.tscn      # Tier 5
│   ├── grid_agent_array.tscn      # Tier 6
│   ├── grid_agent_sine.tscn       # Tier 7
│   ├── grid_agent_random.tscn     # Tier 8
│   └── grid_agent_ca.tscn         # Tier 9
│
└── README.md                       # Documentation
```

### 4. Agent Scenes

Each tier scene inherits from `grid_agent_base.tscn` and adds:
- Specific visual appearance (mesh, shader, particle effects)
- Tier-specific capabilities configuration
- Audio cues for that tier's operations

**Base structure**:
```
GridAgent (CharacterBody3D or RigidBody3D)
├── CollisionShape3D
├── MeshInstance3D (octahedron or tier-specific shape)
├── NavigationAgent3D
├── ThoughtBubble (from BlockBuilderEntity)
├── AnimationPlayer
└── Script: grid_agent_base.gd
```

### 5. Benefits of This Approach

✅ **Consistent with existing system**: Uses same pattern as `mc:`, `ib:`, `tt:`
✅ **JSON-driven**: Map designers place agents like any other object
✅ **No registry pollution**: Doesn't add 9+ entries to artifact registry
✅ **Flexible placement**: Supports rotation, offset, scale via colon syntax
✅ **Easy testing**: Drop into any map's interactables layer
✅ **Progressive unlocking**: Can enable/disable tiers via game state

### 6. Example Usage in Maps

**Tutorial map** (only basic tiers):
```json
"interactables": [
  ["gridagent:copy", " ", " "],
  [" ", " ", "gridagent:translate"]
]
```

**Advanced lab** (multiple tiers with configuration):
```json
"interactables": [
  ["gridagent:random:0:1.5", " ", " "],
  [" ", "gridagent:ca:90:2.0:1.5", " "]
]
```

**Puzzle map** (agent must be captured and directed):
```json
"interactables": [
  ["gridagent:copy", " ", " "],
  [" ", " ", " "]
],
"utilities": [
  [" ", "3t:CAPTURE_THE_AGENT", " "],
  [" ", " ", "algo_gun"]  // Via custom utility type
]
```

### 7. Alternative: Utility Layer (NOT RECOMMENDED)

Could add to UtilityRegistry, but this is less ideal:
- Agents are interactive game entities, not environmental utilities
- Would clutter the utility registry
- Utilities are typically stationary; agents move

### 8. Alternative: Artifact Registry (NOT RECOMMENDED)

Could add 9 separate artifacts, but:
- Registry is for static, collectible artifacts
- Agents are dynamic, AI-driven entities
- Would add too many similar entries

## Conclusion

**Use the interactables layer with `gridagent:tier` syntax**, handled via special case in `GridInteractablesComponent.generate_interactables()`, similar to how Marching Cubes (`mc:`) is handled.

This is the most elegant, consistent, and flexible solution.

