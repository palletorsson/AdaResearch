# Let your approach choose the transform

**Learning elements**

- World-space separation and horizontal distance
- Mapping a distance range to a bounded fraction
- Driving scale or rotation from the same input
- Keeping a shrinking body's base on the floor

Approach the slat wall, then step back. The slats return. Farther on, blocks shrink around you and recover when you leave. Your relation to the object now supplies the changing value.

Continue with one familiar box. Replace Scale's chosen factor with a value calculated from the player. Remove the doorway group and witness. The museum supplies the tracked body; the lesson creates the cube and its response. Like the previous visual studies, this cube does not block your route. The installed exhibits supply their own collision.

## The complete study

Put this `lesson.gd` on an empty `TransformStudy` at floor level, with zero rotation and unit scale. Leave several metres of clear approach space. The player already exists when the study enters the scene.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var cube := MeshInstance3D.new()
var player: Node3D
var near_distance := 1.0
var far_distance := 4.0
var minimum := 0.25
var turn_instead := false

func _ready() -> void:
    assert(far_distance > near_distance and near_distance >= 0.0)
    assert(minimum > 0.0 and minimum <= 1.0)
    cube.mesh = BoxMesh.new()
    add_child(cube)
    cube.position.y = 0.5
    player = get_tree().get_first_node_in_group("player_body") as Node3D
    if player == null:
        player = get_tree().get_first_node_in_group("em_walker") as Node3D

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var separation := player.global_position - global_position
    separation.y = 0.0
    respond(separation.length())

func respond(distance: float) -> void:
    var closeness := 1.0 - clampf((distance - near_distance) / (far_distance - near_distance), 0.0, 1.0)
    if turn_instead:
        cube.scale = Vector3.ONE
        cube.position.y = 0.5
        cube.rotation_degrees.y = 90.0 * closeness
    else:
        var factor := lerpf(1.0, minimum, closeness)
        cube.rotation_degrees.y = 0.0
        cube.scale = Vector3.ONE * factor
        cube.position.y = factor * 0.5
```

The lookup selects the supplied XR body in group `player_body`, or the desktop museum walker in `em_walker`. These are named connections to the existing player. If neither exists, the cube remains at its starting pose; the script does not invent a player.

Both positions in the subtraction are **world positions**. Taking the difference in one frame avoids confusing a local coordinate with a world coordinate. Setting its Y component to zero measures horizontal distance: crouching should not alter this study's response just by changing height.

## Turn metres into a size

At four metres or farther, `closeness` is zero. At one metre or nearer, it is one. Halfway between, at 2.5 metres, it is one half. Subtracting the near distance shifts the range; dividing by its width gives a fraction; `clampf` bounds it; subtracting from one makes closer mean larger input.

`lerpf(1.0, minimum, closeness)` uses that input to shrink the cube from a one-metre side to a quarter-metre side. The mesh is centred on its origin. Moving its centre to half the current height keeps its bottom on the floor.

Walk away. The same calculation restores the larger cube. No new cube is created and none is removed. At the same distance, it gives the same size whether or not you have approached before. Trace kept earlier positions after the point moved on; this study keeps no record of earlier approaches.

Compare that return with the lattice's retained cut elsewhere in this hall. Leaving does not put its missing cells back. This tutorial selects the reversible distance-to-transform relation; the lattice changes which cells remain. Both are visible in the hall.

## Keep the input, change the response

Set `turn_instead` to `true`. The cube now keeps its size and turns from zero to 90 degrees around Y as you approach. At 2.5 metres it turns 45 degrees. One bodily relation can control different transforms.

Return to shrinking and set `far_distance` to `6.0`. Predict where the response starts and where it reaches half its range. The start moves to six metres; halfway is now 3.5 metres, not three. Keep the near limit at one.

Our one-body study responds immediately. The installed wall smooths movement and attends to neighbouring parts. Carry the distance-to-transform relation into a combined opening.
