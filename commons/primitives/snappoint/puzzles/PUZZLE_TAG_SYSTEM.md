# Puzzle Tag System Documentation

## Overview

The puzzle tag system provides a decoupled, flexible way to connect puzzles with obstacles and rewards. Both **line puzzles** and **snappoint puzzles** use the same tag-based system.

## Core Concept

```
Puzzle → Triggers Action → On Tagged Objects
```

- **Puzzles** have a `trigger_tag` and `trigger_action`
- **Objects** register with tags using `#group:tagname`
- When puzzle completes → `TagSystem.trigger_tag_action(tag, action)` executes
- All objects with that tag respond to the action

## JSON Syntax

### Basic Format

```json
"puzzle_name:x:y:z#tag:action"
"object_name:x:y:z#group:tag"
```

### Examples

**Example 1: Reveal Reward**
```json
"snap_tetrahedron_puzzle:0:0:0#reward:reveal"
"cube_scene:0:1:0#group:reward"
```
- Cube starts **hidden** (auto-hide because action is "reveal")
- Complete tetrahedron → Cube **appears**

**Example 2: Remove Obstacle**
```json
"cross_line_puzzle:5:0:3#wall:remove"
"barrier_cube:5:0:4#group:wall"
```
- Barrier starts **visible**
- Complete line puzzle → Barrier **instantly removes**

**Example 3: Shrink and Remove**
```json
"snap_triangle_puzzle:2:0:1#blocker:shrink_and_remove"
"pillar:2:0:2#group:blocker"
```
- Pillar starts **visible**
- Complete triangle → Pillar **shrinks with animation and removes**

**Example 4: Multiple Objects, One Tag**
```json
"snap_pyramid_puzzle:0:0:0#prizes:reveal"
"cube_scene:0:1:0#group:prizes"
"sphere_scene:1:1:0#group:prizes"
"prism_scene:2:1:0#group:prizes"
```
- All three objects start **hidden**
- Complete pyramid → All three **appear together**

## Available Actions

| Action | Effect | Auto-Hide? | Use Case |
|--------|--------|------------|----------|
| `reveal` | Make visible + enable collisions | ✅ Yes | Hidden rewards |
| `hide` | Make invisible + disable collisions | ❌ No | Temporary hiding |
| `remove` | Instant delete | ❌ No | Simple obstacles |
| `shrink_and_remove` | Tween shrink → delete | ❌ No | Animated obstacles |
| `freeze` | Stop physics | ❌ No | Lock objects |
| `unfreeze` | Enable physics | ❌ No | Release objects |
| `enable_physics` | Unfreeze + show | ❌ No | Spawn physics objects |
| `disable_physics` | Freeze only | ❌ No | Stop physics |

## Auto-Hide Logic

The system **automatically hides** tagged objects on map start when:

1. **`trigger_action = "reveal"`** (automatic - smart detection)
2. **OR** `auto_hide_tagged = true` (manual override in scene file)

### Why Auto-Hide?

- `reveal` → Object should start hidden, appear on completion
- `remove`/`shrink_and_remove` → Object should start visible, disappear on completion
- System automatically detects the right behavior!

## Setup Guide

### Step 1: Place Puzzle in Map JSON

```json
"interactables": [
    "snap_tetrahedron_puzzle:0:0:0#treasure:reveal"
]
```

Format: `puzzle_name:x:y:z#tag_name:action_name`

### Step 2: Tag Objects

```json
"interactables": [
    "snap_tetrahedron_puzzle:0:0:0#treasure:reveal",
    "cube_scene:0:1:0#group:treasure",
    "sphere_scene:1:1:0#group:treasure"
]
```

Format: `object_name:x:y:z#group:tag_name`

### Step 3: Test

1. Load map
2. Objects with tag "treasure" should be **hidden** (because action is "reveal")
3. Complete the tetrahedron puzzle
4. Objects should **appear**!

## How It Works Under the Hood

### On Map Load

```gdscript
// 1. GridInteractablesComponent parses JSON
"cube_scene:0:1:0#group:treasure"

// 2. Spawns cube and registers with TagSystem
var cube = cube_scene.instantiate()
TagSystem.register_tagged_node("treasure", cube)

// 3. Spawns puzzle and sets properties
var puzzle = snap_tetrahedron_puzzle.instantiate()
puzzle.trigger_tag = "treasure"        // From #treasure:reveal
puzzle.trigger_action = "reveal"       // From #treasure:reveal

// 4. Puzzle's _ready() runs
if trigger_action == "reveal" and trigger_tag != "":
    await get_tree().process_frame
    await get_tree().process_frame
    TagSystem.trigger_tag_action("treasure", "hide")  // Auto-hide!
    // Cube is now hidden
```

### On Puzzle Completion

```gdscript
// 1. Shape detected (e.g., tetrahedron formed)
func _on_tetrahedron_formed(points: Array):
    if all_points_are_ours:
        _complete_puzzle()  // Base class method

// 2. Base class executes tag action
func _complete_puzzle():
    // ... lock points, play sound ...
    
    if trigger_tag != "":
        TagSystem.trigger_tag_action(trigger_tag, trigger_action)
        // → TagSystem.trigger_tag_action("treasure", "reveal")
    
    // ... show success message ...

// 3. TagSystem finds and reveals all tagged objects
TagSystem.trigger_tag_action("treasure", "reveal"):
    var nodes = _tagged_nodes["treasure"]  // [cube, sphere]
    for node in nodes:
        node.visible = true
        node.show()
    // Cube and sphere are now visible!
```

## Advanced Usage

### Chained Puzzles

Multiple puzzles can trigger the same tag:

```json
"snap_triangle_puzzle:0:0:0#door:reveal"
"snap_pyramid_puzzle:5:0:0#door:reveal"
"final_door:10:0:0#group:door"
```

- Door stays hidden until **both** puzzles complete
- First puzzle reveals door (but it's already hidden)
- Second puzzle reveals door (makes it appear)

### Mixed Actions

Different puzzles can trigger different actions on same tag:

```json
"puzzle_a:0:0:0#walls:hide"
"puzzle_b:5:0:0#walls:reveal"
"wall_1:2:0:0#group:walls"
"wall_2:3:0:0#group:walls"
```

- Puzzle A completion → Hides walls
- Puzzle B completion → Reveals walls

### Legacy Spawn System

For backward compatibility, puzzles still support direct spawning:

```json
"snap_tetrahedron_puzzle:0:0:0"
```

Then in scene file, set:
```
Legacy Spawn System
  ├─ Enable Spawn: ✓
  ├─ Spawn Scene Path: "res://commons/primitives/cubes/cube_scene.tscn"
  ├─ Spawn Position: (0, 0, 1)
  └─ Spawn Scale: 0.5
```

**Recommendation**: Use tag system instead! More flexible and decoupled.

## Common Patterns

### Pattern 1: Hidden Treasure
```json
"puzzle#treasure:reveal"
"reward#group:treasure"
```
✅ Auto-hides, reveals on complete

### Pattern 2: Blocking Wall
```json
"puzzle#obstacle:shrink_and_remove"
"wall#group:obstacle"
```
✅ Starts visible, shrinks away on complete

### Pattern 3: Multiple Rewards
```json
"puzzle#loot:reveal"
"cube_a#group:loot"
"cube_b#group:loot"
"cube_c#group:loot"
```
✅ All appear together

### Pattern 4: Progressive Unlock
```json
"puzzle_1#stage1:reveal"
"puzzle_2#stage2:reveal"
"path_1#group:stage1"
"path_2#group:stage2"
```
✅ Sequential unlocking

## Debugging

### Check Console Output

On map load, look for:
```
TagSystem: Registered node 'CubeInstance' with tag 'treasure'
SnapTetrahedronPuzzle: Auto-hid objects with tag 'treasure' (action=reveal)
```

On puzzle complete:
```
SnapTetrahedronPuzzle: Puzzle completed!
TagSystem: Triggering action 'reveal' on 2 nodes with tag 'treasure'
  - 'CubeInstance': visible = true
  - 'SphereInstance': visible = true
TagSystem: Action 'reveal' executed on 2/2 nodes
```

### Common Issues

**Problem**: Objects don't hide on start
- **Check**: Is action set to "reveal"?
- **Check**: Did puzzle spawn after objects? (auto-hide has 2-frame delay)
- **Fix**: Set `auto_hide_tagged = true` in scene file manually

**Problem**: Objects don't respond to puzzle completion
- **Check**: Are tags matching exactly? (case-sensitive)
- **Check**: Are objects registered? (look for "Registered node" in console)
- **Fix**: Verify JSON syntax: `#group:tagname` for objects, `#tag:action` for puzzles

**Problem**: Multiple puzzles interfering
- **Solution**: Use different tags for different puzzle groups

## File Structure

```
commons/primitives/
├── line/puzzles/
│   ├── line_snap_puzzle_base.gd          # Line puzzle base class
│   ├── triangle_line_puzzle.gd           # Uses tag system
│   └── ...
└── snappoint/puzzles/
    ├── snap_point_puzzle_base.gd         # Snappoint puzzle base class
    ├── snap_triangle_puzzle.gd           # Uses tag system
    ├── snap_tetrahedron_puzzle.gd        # Uses tag system
    ├── snap_pyramid_puzzle.gd            # Uses tag system
    ├── snap_octahedron_puzzle.gd         # Uses tag system
    └── snap_wedge_puzzle.gd              # Uses tag system

commons/grid/
└── tag_system.gd                         # Central tag registry and actions
```

## Summary

✅ **Decoupled**: Puzzles don't know about specific objects
✅ **Flexible**: One tag can control multiple objects
✅ **Automatic**: Smart auto-hide based on action type
✅ **Simple**: Just add `#tag:action` and `#group:tag` to JSON
✅ **Consistent**: Same system for both line and snappoint puzzles

Happy puzzle designing! 🧩✨
