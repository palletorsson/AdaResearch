# Tag-Based Puzzle Event System

## Overview

The Tag-Based Puzzle Event System provides a loosely coupled mechanism for puzzles to trigger actions on pre-placed entities in a map. Instead of puzzles directly spawning rewards, they trigger actions on tagged nodes using a global tag registry.

## Architecture

```
Map JSON (interactables layer)
  ↓
  ├─ Entity: "cube_scene:0:0:1#group:fillhole"
  │    → Registers with TagSystem under tag "fillhole"
  │
  └─ Puzzle: "cross_line_puzzle:0:0:1#fillhole:reveal"
       → On completion, triggers "reveal" action on tag "fillhole"
            → TagSystem executes action on all nodes with that tag
                 → Cube becomes visible
```

## Key Components

### 1. TagSystem (`commons/grid/tag_system.gd`)

A global static utility class that manages tag registrations and action execution.

**Key Functions:**
- `register_tagged_node(tag: String, node: Node)` - Register a node with a tag
- `unregister_tagged_node(tag: String, node: Node)` - Remove registration
- `trigger_tag_action(tag: String, action: String)` - Execute action on all nodes with tag
- Auto-cleanup via `tree_exiting` signal connection

**Supported Actions:**
- `remove` - `queue_free()` the node
- `reveal` - Set `visible = true`, call `show()`
- `hide` - Set `visible = false`, call `hide()`
- `freeze` - Set `freeze = true` (RigidBody3D only)
- `unfreeze` - Set `freeze = false` (RigidBody3D only)
- `enable_physics` - Unfreeze + reveal (RigidBody3D only)
- `disable_physics` - Freeze (RigidBody3D only)

### 2. GridInteractablesComponent Updates

**Token Parsing:**
- Recognizes `#group:tagname` syntax for entity tagging
- Recognizes `#tagname:action` syntax for puzzle triggers
- Parses tags from inline interactables layer tokens

**Example Token Formats:**
```
cube_scene:0:0:1#group:fillhole          → Entity with tag "fillhole"
cross_line_puzzle:0:0:1#fillhole:reveal  → Puzzle that triggers "reveal" on "fillhole"
```

**Artifact Placement:**
- After instantiating an artifact, checks for tag and registers with `TagSystem`
- For puzzles, sets `trigger_tag` and `trigger_action` properties
- Supports `"visible": false` in artifact_definitions to hide entities initially

### 3. LineSnapPuzzleBase Updates

**New Exports:**
```gdscript
@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = ""
```

**Puzzle Completion:**
- When puzzle is solved, calls `TagSystem.trigger_tag_action(trigger_tag, trigger_action)`
- No more hardcoded spawning or reward logic
- Clean separation of concerns

## Usage in Maps

### JSON Structure

```json
{
  "map_info": {
    "name": "Tag System Example"
  },
  "layers": {
    "structure": [
      ["1", "1", "1"],
      ["1", "-", "1"],
      ["1", "1", "1"]
    ],
    "utilities": [
      [" ", " ", " "],
      [" ", " ", " "],
      [" ", " ", " "]
    ],
    "interactables": [
      [" ", " ", " "],
      [" ", "cube_scene:0:0:0#group:fillhole", "cross_line_puzzle:0:0:1#fillhole:reveal"],
      [" ", " ", " "]
    ]
  },
  "artifact_definitions": {
    "cube_scene:0:0:0#group:fillhole": {
      "scene": "res://commons/primitives/cubes/cube_scene.tscn",
      "scale": 1.0,
      "visible": false
    },
    "cross_line_puzzle:0:0:1#fillhole:reveal": {
      "scene": "res://commons/primitives/line/puzzles/cross_line_puzzle.tscn",
      "scale": 1.0
    }
  }
}
```

### Token Syntax

**Entity Tagging:**
```
artifact_name:params#group:tagname
```
- The `group:` prefix indicates this is an entity tag
- `tagname` is the identifier used by puzzles to trigger actions

**Puzzle Triggers:**
```
puzzle_name:params#tagname:action
```
- `tagname` identifies which entities to affect
- `action` is the operation to perform (reveal, remove, hide, etc.)

### Common Patterns

#### 1. Reveal Hidden Object
```json
"interactables": [
  ["hidden_artifact:0:0:1#group:secret", "puzzle:0:0:1#secret:reveal"]
]
"artifact_definitions": {
  "hidden_artifact:0:0:1#group:secret": {
    "scene": "...",
    "visible": false
  }
}
```

#### 2. Remove Obstacle
```json
"interactables": [
  ["barrier:0:0:1#group:obstacle", "puzzle:0:0:1#obstacle:remove"]
]
```

#### 3. Fill Hole with Cube
```json
"structure": [["1", "-", "1"]]
"interactables": [
  [" ", "cube_scene:0:0:0#group:filler", "puzzle:0:0:1#filler:reveal"]
]
"artifact_definitions": {
  "cube_scene:0:0:0#group:filler": {
    "scene": "res://commons/primitives/cubes/cube_scene.tscn",
    "visible": false
  }
}
```

## Benefits

1. **Loose Coupling** - Puzzles don't know about specific rewards
2. **Flexibility** - Multiple entities can respond to one puzzle
3. **Map-Driven** - All behavior configured in JSON
4. **Reusable** - Works with any puzzle type (line, snap point, future additions)
5. **Extensible** - Easy to add new actions
6. **Clean Code** - No spawning logic in puzzle scripts

## Tag Scope

- Tags are **global per scene/map**
- All nodes with the same tag will respond to the trigger
- Tag names must be unique if you want specific targeting
- Multiple nodes can share the same tag for coordinated actions

## Error Handling

The system includes comprehensive console output:
- **Warnings** when triggering a tag with no registered nodes
- **Warnings** when an action fails (e.g., trying to freeze a non-RigidBody3D)
- **Success counts** showing how many nodes responded to each action
- **Debug function** `TagSystem.debug_print_tags()` to inspect all registrations

## Future Extensions

Potential enhancements:
- **Multiple actions per tag** (e.g., `#tag:reveal,enable_physics`)
- **Delayed actions** with timers
- **Conditional triggers** based on game state
- **Action sequences** (reveal then remove after 5 seconds)
- **Tag groups** for hierarchical organization

## Migration from Old System

**Before (hardcoded spawning):**
```gdscript
# In puzzle script
func _complete_puzzle():
    var cube = cube_scene.instantiate()
    cube.position = spawn_position
    get_tree().root.add_child(cube)
```

**After (tag-based):**
```gdscript
# In puzzle script (automatic via base class)
@export var trigger_tag: String = "fillhole"
@export var trigger_action: String = "reveal"

# In map JSON
"cube_scene:0:0:0#group:fillhole"  # Entity
"puzzle:0:0:1#fillhole:reveal"      # Trigger
```

## See Also

- [Line Snap Puzzle System](LINE_SNAP_PUZZLES.md)
- [Snap Point Geometry Puzzles](SNAP_POINT_PUZZLES.md)
- [Grid Interactables System](GRID_INTERACTABLES.md)
