# Transformation — seven tutorial drafts

6 October 2026 · For author and independent AI review. Not yet accepted or installed as the canonical tutorial track.

We are working inside the existing Endless Museum. Each lesson prints one complete reduced study. The museum supplies the room, camera, light and player; named player groups are the only scene lookup. All new lesson geometry is built in code. A new study root in each hall reconstructs the selected relation; no claim is made that a runtime node travels between halls. The familiar BoxMesh and learned operations continue. Revised reflective drafts accompany the tutorials. The canonical manuscripts and installed exhibits are preserved.

Read for spatial progression and explanatory sufficiency. The illustrations are imagined encounters, not runtime test evidence. Full code and native checks are available with this draft.


---

<!-- hall:Trans_Pre -->

# A cube that moves, turns and grows

**Learning elements**

- Translation: changing position
- Rotation: changing orientation
- Uniform scale: changing size
- Elapsed time and a returning fraction
- Collection: overlap detection and a signal

In Trans_Pre, one cube rises. The next rises and turns. Another adds a pulse in size. Follow one corner: each example keeps the earlier movement and adds another operation.

We continue with the cube shape from Primitives. Here Godot's `BoxMesh` supplies it; we change the whole object's transform. The construction of faces has already done its work. This lesson makes one animated pickup that you collect by walking into it.

## The complete study

The Endless Museum is already running. Its room, light, camera and player are supplied. Put an empty `Node3D` named `TransformStudy` in clear floor space beside the exhibits and attach `lesson.gd`. Use floor level as its origin, zero rotation and unit scale. Each coordinate below is in this study's local frame. The script creates every part of the pickup.

Read the complete result once, then use the small edits below to build up its behaviour.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var cube := MeshInstance3D.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.2
var period := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    cube.mesh = BoxMesh.new()
    add_child(cube)
    cube.position = start

    var sensor := Area3D.new()
    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    cube.add_child(sensor)
    var hitbox := CollisionShape3D.new()
    hitbox.shape = BoxShape3D.new()
    sensor.add_child(hitbox)
    sensor.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    elapsed += delta
    var t := pingpong(2.0 * elapsed / period + 0.5, 1.0)
    cube.position = start + Vector3.UP * lerpf(-rise, rise, t)
    cube.rotation_degrees.y = turn_speed * elapsed
    cube.scale = Vector3.ONE * lerpf(1.0 - pulse, 1.0 + pulse, t)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("em_walker") or body.is_in_group("player_body"):
        print("Collected")
        queue_free()
```

`BoxMesh.new()` describes a one-metre cube centred on its origin. The `MeshInstance3D` holds its position, orientation and size. The same mesh remains throughout.

## Add one movement at a time

First set `turn_speed` and `pulse` to `0.0`. Keep `rise` at `0.35`. The cube moves 35 centimetres above and below `start`, keeping its size and facing.

`elapsed += delta` counts seconds. `pingpong` makes `t` travel between zero and one at a steady rate, reversing at each end. The factor `2.0 / period` gives one outward-and-return journey per period. Adding `0.5` starts halfway up, moving upward. With `period = 4.0`, `t` is 0.5 at the start, 1 after a second, 0.5 after two, 0 after three, and 0.5 after four.

`lerpf(-rise, rise, t)` chooses a height offset between the lower and upper limits. At `t = 0.5` it gives zero: the cube is back at `start`. This is the steady rise and fall of the museum example. It changes direction immediately at the ends; a softened turn would be a different timing choice.

Restore `turn_speed` to `45.0`. The cube now rises **and** turns 45 degrees per second around Y. Its mesh has not changed. After eight seconds it completes one turn.

Restore `pulse` to `0.2`. The second `lerpf` now chooses a size factor between `0.8` and `1.2`. Multiplying `Vector3.ONE` gives all three axes the same factor, so the cube keeps its proportions. Rise and pulse share the returning fraction; the turn continues at its own steady rate. The assertion keeps the period positive and prevents the pulse from collapsing the cube to zero size. The installed specimen uses a larger pulse, from 0.7 to 1.3; this study keeps the same operation with a smaller range.

Each update assigns a pose from the starting values and elapsed time. Adding that whole pose repeatedly would make the cube drift. `elapsed` is kept between updates; `t` is calculated afresh from that clock, and the three transform properties are assigned from those values.

## Walk into it

An `Area3D` detects overlap. Its `BoxShape3D` describes the detection box; it does not provide a solid wall. Because the area belongs to the cube, the box follows its movement, turning and uniform scale.

`body_entered` is a signal announcing that a physics body entered the area. `connect` names the function to call. The museum supplies the desktop walker in group `em_walker` on layer 1, and the XR body in group `player_body` on layer 20. The mask listens to both layers; the group check accepts the player. These are the declared connections to the existing museum.

Walk into the cube. `queue_free()` removes the study at the end of the frame, and Output prints `Collected`. A passing ordinary prop does not collect it. The installed pickup's score and flourish remain outside this small reconstruction.

## Make another version

Set `period` to `8.0`. Predict which movements slow down. The rise and pulse take twice as long; the turn still advances at 45 degrees per second. Explain why. Then choose a different rise while preserving the cube's proportions.

Carry these three operations into the next hall. There, a transformed surface offers somewhere to stand.


---

<!-- hall:Trans_Introduction -->

# Three ways to make a crossing

**Learning elements**

- Translation, rotation and scale as different ways to reach
- A bounded fraction controlling a transform
- Interpolation between two values
- A returning function for repeated construction

Try the three installed crossings. One carries you, one grows, one turns into alignment. The far bank gives each change a purpose. A correctly moving object can still fail to reach it.

Keep the `MeshInstance3D` and `BoxMesh` construction from Trans_Pre. Remove its collection area: these examples need to remain for comparison. Make three small studies beside the real crossings. Their geometry is visible but has no blocking collision; use the installed crossings for standing and riding. The museum's rider transport is supplied, not reconstructed here.

## Make the comparison

Attach this complete `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` in a clear area about ten metres wide. Its origin is at floor level. The three lanes run along local Z, at X = −4, 0 and 4. Their bank tops are one metre above the origin. The centre of the growing cube stays at the origin height; part of its volume extends below the floor.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var travel: MeshInstance3D
var grow: MeshInstance3D
var turn: MeshInstance3D
var far_banks: Array[MeshInstance3D] = []
var far_gap := 0.0
var animate := true
var pose := 0.0
var duration := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and far_gap >= 0.0)
    for x in [-4.0, 0.0, 4.0]:
        box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, -1.5))
        far_banks.append(box(Vector3(1.2, 0.4, 1), Vector3(x, 0.8, 1.5 + far_gap)))
    travel = box(Vector3(1.2, 0.2, 0.8), Vector3(-4, 0.9, -1.4))
    grow = box(Vector3(1.2, 2, 2), Vector3.ZERO)
    turn = box(Vector3(2, 0.2, 0.6), Vector3(4, 0.9, 0))
    apply_pose(pose)

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    add_child(body)
    return body

func _process(delta: float) -> void:
    elapsed += delta
    if animate:
        pose = pingpong(elapsed / duration, 1.0)
    apply_pose(pose)

func apply_pose(value: float) -> void:
    var t := clampf(value, 0.0, 1.0)
    travel.position.z = lerpf(-1.4, 1.4, t)
    grow.scale = Vector3.ONE * lerpf(0.25, 1.0, t)
    turn.rotation_degrees.y = 90.0 * t
```

The `box` function repeats the construction you already know. Its two arguments choose dimensions and position. It returns the new instance so `travel`, `grow` and `turn` can refer to different bodies. The loop places the same pair of banks in each lane.

`apply_pose` gives the three operations the same fraction, `t`. Zero selects their first pose; one selects their last. `clampf` keeps the fraction within those bounds. `lerpf(a, b, t)` chooses a value between `a` and `b`: halfway gives their average.

## Hold the two ends

Set `animate` to `false` and `pose` to `0.0`. The travelling surface waits at the near bank. The small cube does not reach the bank tops. The long plank lies across X, away from the route.

Change `pose` to `1.0`. The first surface reaches the far bank without changing size or orientation. The cube has grown around its fixed centre: its top reaches bank height and its Z edges meet the banks. The plank has turned 90 degrees around Y, putting its long dimension along Z. Its centre and dimensions stay fixed.

One operation moves a surface between banks. The others make a span. They solve different spatial problems using the same three properties from Trans_Pre.

## Follow the intervening poses

Restore `animate` to `true`. `pingpong` moves the fraction from zero to one, then back. With `duration = 4.0`, each outward journey takes four seconds; the full return takes eight. This timing turns immediately at its endpoints. The installed crossings also have pauses and rider support.

## Move the place it must reach

For a held comparison, set `animate` to `false`, `pose` to `1.0` and `far_gap` to `0.5`. The far banks move half a metre farther along Z. The growing cube and turned plank keep their previous end poses. Each now leaves half a metre unbridged.

The transform still reaches its intended pose. Reaching the bank also depends on where the bank is.

Return `far_gap` to zero and choose `pose = 0.5`. Predict the travelling surface's position, the cube's size and the plank's angle before running it.


---

<!-- hall:Trans_Translation -->

# A level body on a sloping journey

**Learning elements**

- Displacement in a named coordinate frame
- Vector interpolation
- A destination and a route to it
- A condition selecting two parts of a journey

Watch the carrier that travels diagonally. Its route slopes; its top stays level. Translation changes position without requiring a turn. At the exit, compare the guided handle's bend with the freer handle's diagonal.

Continue with the travelling box from the previous lesson. Keep its mesh and position change; remove the other two studies and their banks. This time choose a destination and the route. The museum supplies the installed ride. Our reduced study displays its movement without rider physics.

## The complete study

Put an empty `TransformStudy` on clear museum floor, with zero rotation and unit scale, and attach this `lesson.gd`. The positions are local metres. `BoxMesh.size` gives the familiar cube a broad, low shape once; the journey then leaves that shape unchanged.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var cube := MeshInstance3D.new()
var start := Vector3(-2, 1, 0)
var finish := Vector3(2, 3, 0)
var duration := 4.0
var via_corner := false
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0)
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.2, 0.2, 1.2)
    cube.mesh = mesh
    add_child(cube)
    cube.position = start

func _process(delta: float) -> void:
    elapsed += delta
    var t := clampf(elapsed / duration, 0.0, 1.0)
    if via_corner:
        var corner := Vector3(start.x, finish.y, start.z)
        if t < 0.5:
            cube.position = start.lerp(corner, t * 2.0)
        else:
            cube.position = corner.lerp(finish, (t - 0.5) * 2.0)
    else:
        cube.position = start.lerp(finish, t)
```

`finish - start` is the displacement: here `(4, 2, 0)`, four metres along X and two upward. Lines introduced the length of such a vector. Its components describe one combined change, not an instruction to finish X before starting Y.

`start.lerp(finish, t)` interpolates all three components together. At `t = 0.5`, the cube is at `(0, 2, 0)`, halfway along the diagonal. Neither rotation nor scale is assigned during the journey. The carrier remains level.

The fraction reaches one after four seconds. Clamping holds the destination even as elapsed time continues. A direct assignment to `finish` would reach the same place immediately and omit the journey.

## Give the same displacement another route

Set `via_corner` to `true`. The first half of the time takes the cube to `corner`, directly above its start. The second half takes it to the same destination as before. The `if` chooses which segment currently supplies the position; multiplying each half's fraction by two stretches it back to the range zero to one.

At two seconds, the direct version is at `(0, 2, 0)`. The corner version is at `(-2, 3, 0)`. At four seconds they agree again. A shared destination does not require a shared journey.

This version gives each segment two seconds. The upward segment is two metres; the horizontal one is four, so their speeds differ. Constant speed along routes of different lengths would need time allocated by distance. We leave that calculation for a later movement study.

## Choose another destination

Keep `via_corner` true and change `finish` to `Vector3(2, 3, 2)`. Predict the new corner and final position. The first leg stays vertical; the second now crosses both X and Z. The body still does not turn to face its travel.

In Trace, an ordered list kept positions after movement. Here, `start`, `corner` and `finish` name positions for a movement to follow. Put their values in that order on paper. A longer route could keep them in an array, with an index choosing the next destination. Our two branches still choose the segments here; the list would be a different way to describe the route.

The next hall makes that turn a deliberate choice, with an axis and a centre of its own.


---

<!-- hall:Trans_Rotation -->

# Give the turn a centre

**Learning elements**

- Axis, angle and pivot
- Degrees and radians
- A child offset from a rotating parent
- A face mark that makes orientation visible

A quarter-turn can restore a cube's square outline without returning the same face. Follow the mark on the installed cube. Then watch the end of a turning blade: a fixed centre does not mean the whole body stays in one place.

Keep the box construction and elapsed clock. Remove the translation route. Put the cube under a new `pivot`, and make the pivot turn. The small dark mark belongs to the cube so it follows the same transform.

## The complete study

Attach `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` on clear museum floor. Leave room around it for a two-metre offset. The museum supplies the room and viewer; this script creates the pivot, cube and mark.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var pivot := Node3D.new()
var cube := MeshInstance3D.new()
var mark := MeshInstance3D.new()
var axis := Vector3.UP
var offset := Vector3.ZERO
var speed := 45.0
var elapsed := 0.0

func _ready() -> void:
    assert(axis.length() > 0.0)
    add_child(pivot)
    pivot.position = Vector3(0, 1.2, 0)
    cube.mesh = BoxMesh.new()
    pivot.add_child(cube)
    cube.position = offset

    var mark_mesh := BoxMesh.new()
    mark_mesh.size = Vector3(0.3, 0.12, 0.02)
    mark.mesh = mark_mesh
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    mark.material_override = ink
    cube.add_child(mark)
    mark.position = Vector3(0.18, 0.2, 0.51)

func _process(delta: float) -> void:
    elapsed += delta
    var angle := deg_to_rad(speed * elapsed)
    pivot.basis = Basis(axis.normalized(), angle)
```

`axis` chooses the direction of the rotation axis in the study's frame. `Vector3.UP` means Y. `normalized()` keeps that direction and gives it length one. `Basis(axis, angle)` constructs the orientation for a turn about that axis. It expects radians, so `deg_to_rad` converts the degrees produced by `speed * elapsed`.

At 45 degrees per second, two seconds gives a quarter-turn and eight gives a full turn. We assign the orientation from elapsed time, rather than repeatedly adding the accumulated angle.

## Move the cube away from the pivot

With `offset = Vector3.ZERO`, the pivot passes through the cube's centre. Its centre stays fixed while its corners move.

Change `offset` to `Vector3(2, 0, 0)`. The cube remains two metres along the pivot's **local** X axis. As the parent turns, that local direction turns in the museum. The cube's centre now travels around the pivot while its orientation turns with it. The mark remains attached to the same face.

The child's local position has stayed fixed; its world position has changed. This returns to Coordinates with a moving reference frame. Internal distances stay the same in both examples, but the offset version needs more surrounding space.

## Choose the axis

Keep the two-metre offset and change `axis` to `Vector3.FORWARD`. In Godot this is negative Z. The centre now follows a vertical circle instead of a horizontal one. At two seconds, predict which side of the pivot it reaches. Part of the circle goes below the floor; raise the study if you want to see the complete orbit.

The museum's standing platforms use an additional rule to keep their riders upright. Our cube turns with its parent; it is not a rider mechanism. Reversing two rotations is another comparison in the hall, beyond this lesson's single axis.

Carry the pivot with you. In Scale, the location of the origin will also decide which part of a change stays put.


---

<!-- hall:Trans_Scale -->

# Enlarge the opening, keep the witness

**Learning elements**

- Uniform and unequal scale factors
- Scaling around an origin
- Parent and child transforms
- Local dimensions and world dimensions

In this hall, the furnished room grows while your body keeps its size. A small doorway becomes a possible passage. The bottle also relocates the visitor; that relocation is separate from scaling the room.

Keep Rotation's parent-child arrangement. Replace the rotating pivot with a fixed doorway parent containing three boxes. Remove the clock and face mark. Bring back the familiar black sphere as a size witness, outside the parent that will change. This simple doorway is a visual model; the installed room supplies physical passage.

## The complete study

Attach this `lesson.gd` to an empty, unrotated, unit-scale `TransformStudy` on museum floor. The doorway's origin is at the centre of its threshold. Its initial clear opening is 0.45 metres wide and 0.60 metres high. The sphere's diameter is 0.65 metres.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

var doorway := Node3D.new()
var point := MeshInstance3D.new()
var factors := Vector3.ONE

func _ready() -> void:
    assert(factors.x > 0.0 and factors.y > 0.0 and factors.z > 0.0)
    add_child(doorway)
    box(Vector3(0.12, 0.6, 0.2), Vector3(-0.285, 0.3, 0))
    box(Vector3(0.12, 0.6, 0.2), Vector3(0.285, 0.3, 0))
    box(Vector3(0.69, 0.12, 0.2), Vector3(0, 0.66, 0))
    doorway.scale = factors

    var sphere := SphereMesh.new()
    sphere.radius = 0.325
    sphere.height = 0.65
    point.mesh = sphere
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.06, 0.06, 0.06)
    ink.roughness = 0.18
    point.material_override = ink
    add_child(point)
    point.position = Vector3(1.8, 0.325, 0)

func box(size: Vector3, at: Vector3) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    body.position = at
    doorway.add_child(body)
```

The two posts and lintel are children of `doorway`. The sphere is a sibling of that parent. Setting the parent's `scale` reaches the three boxes and the distances between them. It does not reach the sphere.

With `factors = Vector3.ONE`, the point is wider than the opening. Change the existing line to `var factors := Vector3(4, 4, 4)` and run again. The clear opening is now 1.80 by 2.40 metres. Every doorway dimension and spacing has grown fourfold. The sphere is still 0.65 metres across.

Each box keeps its local position and mesh dimensions. Its world dimensions change through the parent. The posts' bottom edges stay at floor level because the scaling origin is there. An origin halfway up the door would produce a different relation to the floor.

## Change width without changing height

Set `factors` to `Vector3(4, 1, 1)`. The opening is now 1.80 metres wide but only 0.60 metres high. The sphere remains too tall. This scale changes proportions: X grows, Y and Z do not.

Uniform scale preserves proportions; it does not preserve every possible action around an object. In the installed room, compare the enlarged doorway with the museum frame that stayed outside the changing group.

## Make a deliberate opening

Try `Vector3(2, 2, 1)`. Predict the opening's width, height and depth before running it. The width becomes 0.90 metres and the height 1.20; depth stays unchanged. Explain why the sphere keeps both its position and diameter.

The next hall keeps this size factor but lets your distance choose it. You will change the surroundings by approaching them.


---

<!-- hall:Trans_Body -->

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


---

<!-- hall:Trans_Pit -->

# Make room with three operations

**Learning elements**

- Combining translation, rotation and scale
- One progress value driving several properties
- Overlap as a continuing condition
- Opening and returning over time
- Keeping a solid boundary with the visible shape

First watch the blocks that arrive, turn and grow regardless of your approach. Then meet the door at the end of the hall. Its leaves move aside, turn and shrink while the frame stays still. The same operations can take space or offer it.

Combine the sequence's parts: Scale's fixed frame, two familiar boxes, Pre's player-detecting area and a timed change. Body used continuous distance; this study asks whether anyone is within reach. This time the frame and leaves are solid. A closed leaf stops you; the transformed leaves leave a passage. The installed door's staggered movements and closing delay remain further variations.

## The complete study

Attach `lesson.gd` to an empty `TransformStudy` on clear museum floor, with zero rotation and unit scale. Stand at least three metres away before starting, then approach from either side. All dimensions below are local metres. The area extends two metres in front of and behind the doorway.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const LEAF_SIZE := Vector3(1.1, 2.5, 0.18)
var leaves: Array[AnimatableBody3D] = []
var visuals: Array[MeshInstance3D] = []
var shapes: Array[BoxShape3D] = []
var sensor := Area3D.new()
var duration := 3.0
var progress := 0.0
var slide := 1.15

func _ready() -> void:
    assert(duration > 0.0 and slide >= 0.0)
    box(Vector3(0.25, 2.6, 0.35), Vector3(-1.25, 1.3, 0))
    box(Vector3(0.25, 2.6, 0.35), Vector3(1.25, 1.3, 0))
    box(Vector3(2.75, 0.2, 0.35), Vector3(0, 2.7, 0))
    for side in [-1.0, 1.0]:
        box(LEAF_SIZE, Vector3(side * 0.55, 1.25, 0), true)

    sensor.collision_layer = 0
    sensor.collision_mask = 1
    sensor.set_collision_mask_value(20, true)
    add_child(sensor)
    var hitbox := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(5, 3, 4)
    hitbox.shape = shape
    hitbox.position.y = 1.5
    sensor.add_child(hitbox)

func box(size: Vector3, at: Vector3, is_leaf := false) -> void:
    var body := AnimatableBody3D.new()
    body.sync_to_physics = false
    body.position = at
    add_child(body)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    body.add_child(visual)
    var shape := BoxShape3D.new()
    shape.size = size
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    if is_leaf:
        leaves.append(body)
        visuals.append(visual)
        shapes.append(shape)

func _physics_process(delta: float) -> void:
    var target := 0.0
    for body in sensor.get_overlapping_bodies():
        if body.is_in_group("em_walker") or body.is_in_group("player_body"):
            target = 1.0
            break
    progress = move_toward(progress, target, delta / duration)
    apply_pose(progress)

func apply_pose(t: float) -> void:
    for i in leaves.size():
        var side := -1.0 if i == 0 else 1.0
        leaves[i].position = Vector3(side * (0.55 + slide * t), 1.25 + 0.9 * t, 0)
        leaves[i].rotation_degrees.z = side * 55.0 * t
        var factor := lerpf(1.0, 0.35, t)
        visuals[i].scale = Vector3.ONE * factor
        shapes[i].size = LEAF_SIZE * factor
```

The box function now builds each box around an `AnimatableBody3D`: a solid body whose movement our code controls. Inside it, a `MeshInstance3D` supplies the visible box and a `CollisionShape3D` holds a matching `BoxShape3D`. The frame uses the same construction but stays still. We set `sync_to_physics` false because our own `_physics_process` assigns the poses on physics ticks.

When `is_leaf` is true, the function keeps three references: the body in `leaves`, its mesh instance in `visuals`, and its collision shape in `shapes`. The same index identifies parts of the same leaf. Their centres begin equally far from the middle. The frame boxes are outside these lists, so the pose function leaves them alone.

Pre reacted once when a body entered. Here `get_overlapping_bodies()` reads who is still in the area on each physics tick. The loop recognises the same museum player groups. If one qualifies, the target becomes one and `break` ends the search. If no player qualifies, the target remains zero. An ordinary prop does not hold the opening. If two qualifying bodies enter, either one remaining is enough.

`move_toward` changes `progress` by at most `delta / duration` per physics tick and stops at its target. Three seconds takes it from fully closed to fully open. Leaving halfway reverses from the current pose; it does not jump to an endpoint. Physics ticks keep the overlap reading with the physics simulation, while `delta` still measures seconds.

## Follow each operation

The `side` value is −1 for the left leaf and +1 for the right. Multiplying by it gives opposite horizontal directions and opposite turns.

At `t = 0`, the two leaves meet. At `t = 1`, their centres have moved sideways and upward, each has turned 55 degrees in the doorway's face, and each is 35 percent of its starting size. Z is the rotation axis here; Y remains up. Both leaves keep their own centres as their turning and scaling origins.

The body's position and rotation carry both its mesh and collision. For size, we scale the visual and resize the box shape by the same factor, while the physics body keeps unit scale. That makes the visible gap agree with the solid boundary. Shrinking only the mesh would leave an invisible barrier.

Approach and wait as the leaves withdraw, then walk through the frame. The area keeps the door open while you remain nearby, including on the far side. After everyone leaves, this version begins closing immediately. Its frame has finite width: walking around it is also possible.

These operations share one fraction and happen together in our study. The installed mechanism staggers them and waits three seconds before closing. In either case, inspect intermediate poses: endpoints alone do not describe the available space throughout the movement.

## Author another opening

Change `duration` to `6.0`. The journey takes twice as long; its end pose stays the same. Then restore three seconds and change `slide` to `1.5`. The leaves travel farther sideways while keeping the same turn and final size. Predict the larger gap before approaching.

You have made a response from three known operations. Arrays can now repeat a body and give each instance its own place or variation. Keep this working opening as one composition; not every object in the next hall needs to inherit its sensor.


---

## For the independent reviewer

204 native checks passed; 12 deliberate faults rejected; 19 exercise variants executed. The feedback pass changed prose only; printed code still matches that native run.

These checks execute the exact printed code and exercise edits in Godot 4.6, including actual physics overlap with simulated player bodies. They do not establish human understanding or physical-headset comfort. Crossing support and rider transport remain in the installed museum artifacts. The final door study includes solid collision and a tested passage.

Please assess each hall as KEEP / CHANGE / MISSING. Is transformation still the subject? Are the new operations sufficiently explained? Does each lesson reuse earlier understanding and leave a useful capability? Identify the smallest correction to a specific passage. Do not turn the sequence into an exhaustive programming syllabus or require every illustrated artifact to become an exercise.
