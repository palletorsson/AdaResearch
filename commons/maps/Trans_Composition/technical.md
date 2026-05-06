# Trans_Composition - Technical Notes

## Transform Composition

A transformation matrix combines translation (T), rotation (R), and scale (S):

```
M = T × R × S

┌                 ┐   ┌             ┐   ┌           ┐   ┌         ┐
│ 1  0  0  tx │   │ r11 r12 r13 0│   │ sx  0  0  0│   │ x │
│ 0  1  0  ty │ × │ r21 r22 r23 0│ × │  0 sy  0  0│ × │ y │
│ 0  0  1  tz │   │ r31 r32 r33 0│   │  0  0 sz  0│   │ z │
│ 0  0  0   1 │   │   0   0   0 1│   │  0  0  0  1│   │ 1 │
└                 ┘   └             ┘   └           ┘   └   ┘
```

**Order matters:** Scale first, then rotate, then translate.

## Chair Assembly Target Transforms

```gdscript
# Seat: wide, flat
seat.target_scale = Vector3(0.4, 0.04, 0.4)
seat.target_position = Vector3(0, 0.45, 0)

# Legs: tall, thin (4 pieces)
leg.target_scale = Vector3(0.04, 0.44, 0.04)
leg.target_position = Vector3(±0.16, 0.22, ±0.16)

# Back: tall, wide, thin
back.target_scale = Vector3(0.36, 0.5, 0.04)
back.target_position = Vector3(0, 0.72, -0.18)
```

## Scale Snap Values

Discrete steps for educational clarity:

```gdscript
scale_snap_values = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
```

Two-handed scaling calculates distance ratio:

```gdscript
var scale_delta = current_hand_distance / initial_hand_distance
var index_delta = round((scale_delta - 1.0) * sensitivity)
new_index = clamp(start_index + index_delta, 0, max_index)
```

## Transform Verification

Each piece is validated against tolerances:

```gdscript
position_tolerance = 0.08  # 8cm
rotation_tolerance = 15.0  # 15 degrees
scale_tolerance = 0.15     # 15%

func _is_piece_at_target(piece, target) -> bool:
    # Position check
    var pos_delta = piece.position.distance_to(target.position)
    if pos_delta > position_tolerance:
        return false

    # Rotation check (euler angles)
    var rot_diff = max_axis_difference(piece.rotation, target.rotation)
    if rot_diff > rotation_tolerance:
        return false

    # Scale check
    var scale_diff = (piece.scale - target.scale).length()
    if scale_diff > scale_tolerance:
        return false

    return true
```

## Grow Animation

On completion, assembled furniture scales from model size to real size:

```gdscript
model_scale = 0.3   # Working size (within reach)
final_scale = 1.0   # Real furniture size

# Tween animation
tween.tween_property(piece, "scale",
    piece.scale * (final_scale / model_scale),
    grow_duration)
```

## Key Files

- `grab_cube_scalable.gd` - Two-handed scaling logic
- `transform_puzzle_base.gd` - Transform verification
- `furniture_assembly_puzzle.gd` - Chair piece definitions
- `chair_assembly_puzzle.tscn` - Puzzle scene
