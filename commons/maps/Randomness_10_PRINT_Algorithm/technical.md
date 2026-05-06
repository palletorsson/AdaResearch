# Randomness_10_PRINT_Algorithm - Technical Tutorial

## The Original 10 PRINT

The complete program in Commodore 64 BASIC:

```basic
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
```

### Decoding the Line

- `10` - Line number (required in BASIC)
- `PRINT` - Output to screen
- `CHR$(205.5+RND(1))` - The magic:
  - `RND(1)` returns random float 0.0-1.0
  - Adding 205.5 gives range 205.5-206.5
  - `CHR$()` converts to character: 205 = `/` diagonal, 206 = `\` diagonal
  - Integer truncation means 50% chance of each
- `;` - Suppress newline (continue on same line)
- `: GOTO 10` - Loop forever

### Godot Implementation

```gdscript
extends Node3D

var maze_width = 40
var maze_height = 30
var cell_size = 1.0

func _ready():
    generate_maze()

func generate_maze():
    for y in range(maze_height):
        for x in range(maze_width):
            var slash_type = randi() % 2  # 0 or 1
            spawn_slash(x, y, slash_type)

func spawn_slash(x: int, y: int, type: int):
    var mesh_instance = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(0.1, 0.1, cell_size * 1.4)  # Thin diagonal
    mesh_instance.mesh = box

    # Position at grid cell
    mesh_instance.position = Vector3(x * cell_size, 0, y * cell_size)

    # Rotate based on type
    if type == 0:
        mesh_instance.rotation.y = deg_to_rad(45)   # / slash
    else:
        mesh_instance.rotation.y = deg_to_rad(-45)  # \ slash

    add_child(mesh_instance)
```

### 3D Extension

The `ten_print_maze_3d` interactable extends the 2D concept:

```gdscript
# 3D 10 PRINT with vertical dimension
func generate_3d_maze():
    for z in range(depth):
        for y in range(height):
            for x in range(width):
                # Binary choice in each dimension
                var choice = randi() % 2
                spawn_3d_element(x, y, z, choice)
```

### Probability and Pattern

With exactly 50% probability:
- Expected ratio: 1:1 slashes
- Local clusters appear but dissolve
- No long-range correlations
- Apparent "paths" are illusory—pure coincidence

```gdscript
# Adjusting probability changes the texture
func biased_10_print(bias: float = 0.5):
    for y in range(height):
        for x in range(width):
            var slash = 0 if randf() < bias else 1
            spawn_slash(x, y, slash)

# bias = 0.5: balanced maze
# bias = 0.7: more / slashes, diagonal stripes emerge
# bias = 0.9: almost all /, nearly horizontal lines
# bias = 1.0: all /, perfect order (no randomness)
```

### The remove_random Interaction

The `remove_random` elements demonstrate selective removal:

```gdscript
# Removing random elements reveals underlying structure
func remove_random_elements(probability: float = 0.3):
    for child in get_children():
        if randf() < probability:
            child.queue_free()
```

## Implementation Notes

### Multiple Instances
The map contains three `ten_print_maze_3d` instances at different positions and rotations, demonstrating that:
- Same algorithm + different seed = different pattern
- Same algorithm + same seed = identical pattern
- The "randomness" is deterministic but unpredictable

### Shader Gallery
The `Shader_Gallery` element shows visual processing of the maze patterns—how fragment shaders can transform procedural geometry.

### Grid Configuration
- `cube_size: 1.0`
- `gutter: 0.0`
- `show_grid: true`
- Elevated structure (heights 1-3) creates viewing platforms

## Key Takeaway
10 PRINT is the canonical example of **emergence from simplicity**. A single binary choice, repeated infinitely, creates infinite variety. The algorithm has no memory, no state, no plan—yet produces patterns that look designed. This is entropy harnessed: maximum simplicity generating maximum complexity.

## Axiom References
- `commons/context/clipboard/tutorial_text/ten_print_axioms.md`

## Within the Sequence

Randomness_10_PRINT_Algorithm reproduces the famous Commodore 64 one-liner as a demonstration that a single random choice, applied uniformly across a grid, produces a characteristic emergent pattern.

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
