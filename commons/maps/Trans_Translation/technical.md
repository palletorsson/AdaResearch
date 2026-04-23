# Translation Basics

## From Introduction to Infrastructure

Trans_Introduction staged three operations side by side: one cube moved, one rotated, one scaled. The lesson was contrast — seeing all three transformations simultaneously made each legible by what the others weren't. Translation didn't rotate. Rotation didn't translate. Scale changed the shape of things while the others left shape alone.

This map drops the contrast. Everything here is translation. Walkways cross voids. Transport cubes run back and forth. Pickup cubes bob and wait to be collected. The player trace draws the path you've already walked. The map is a navigation problem, and the solution is pure displacement — changing position without changing anything else.

Translation is the identity-preserving transformation. Shape stays. Orientation stays. Only position changes.

---

## The Operation

In 3D space, translation means adding a displacement vector to a current position:

```gdscript
# Translation is vector addition applied to position
node.position += Vector3(dx, dy, dz)
```

In Godot 4, `Node3D.position` is a `Vector3` in local space; `Node3D.global_position` is world space. When you write `node.position += Vector3(0, 1, 0)`, you translate one meter upward. The node's rotation — stored separately in `rotation` or `quaternion` — is untouched. Scale is untouched. Mesh is untouched.

The formal description uses a 4×4 homogeneous matrix:

```gdscript
# The translation matrix, shown as a Transform3D basis + origin
# transform.origin holds the translation vector
# transform.basis holds rotation and scale — unchanged by translation alone
var t := Transform3D.IDENTITY
t.origin = Vector3(2.0, 0.0, 3.0)  # translate 2 units X, 3 units Z
node.global_transform = t
```

Godot exposes this through `Transform3D`: `transform.basis` encodes rotation and scale; `transform.origin` encodes translation. A pure translation changes only `origin`. You can verify this by watching the translation cubes oscillate — their `basis` is constant throughout.

What matters at this stage: three independent numbers, three independent axes. Moving along X doesn't change Y or Z. Moving along Z doesn't change X. Axes are orthogonal. This independence is the core fact that Trans_AxisDecomposition will make explicit by constraining your control to one axis at a time — but you'll feel it here first.

---

## Axis-Constrained Cubes: One Coordinate at a Time

Two artifacts in this map demonstrate axis isolation directly: `y_translation_cube` and `z_translation_cube`. Both run `axis_translation_cube.gd`. The axis they translate along is their only variable; everything else about the cube — shape, orientation, size — is invariant.

The configurable interface makes the constraint literal. These exports are the complete parameter surface of the artifact:

```gdscript
# axis_translation_cube.gd — configurable exports (from artifact metadata)
@export var axis: Axis                                          # X, Y, or Z
@export_range(0.01, 1.0, 0.01) var cube_size: float           # side length in meters
@export_range(0.05, 2.0, 0.05) var travel_distance: float     # max distance from center
@export_range(0.01, 5.0, 0.01) var travel_speed: float        # units per second
@export_range(0.0, 10.0, 0.1) var wait_time: float            # pause at each extreme
@export var cube_color: Color
@export var show_rail: bool     # visual axis rail
@export var show_trail: bool    # ghost trail of previous positions
```

The `axis` enum selects which coordinate changes. Setting `axis = Axis.Y` means only Y moves — the cube oscillates vertically between `-travel_distance` and `+travel_distance` from its resting position. The movement state machine runs in `_update_state(delta)`, which drives the oscillation; `_update_cube_position()` applies the result. The internal implementation of those functions is not exposed in this map's artifact documentation. What's visible and verifiable: the constraint is a choice of one enum value, and everything the cube does follows from that choice.

The `show_trail` flag is pedagogically essential. When enabled, `_create_trail_ghosts()` builds a series of semi-transparent copies at previous positions, making displacement visible as geometry. The ghost trail is a spatial record of where the cube has been. It makes the axis constraint tangible: the ghosts stack only along the allowed axis, never spreading perpendicular to it. Switch to `show_rail` and you see the travel range rendered as a line — a vector diagram showing direction and bounded extent.

A key detail: the Y cube and Z cube occupy the same conceptual category but different perceptual experiences. Vertical movement (Y) reads as lift and fall. Depth movement (Z) reads as approach and recession. The operation is identical; the phenomenology differs. The coordinate system doesn't know or care about this distinction. You do.

---

## Player Trace: Body as Accumulator

The `player_trace` artifact does something different from the translation cubes. They demonstrate translation as an object property. The trace demonstrates it as a bodily act — navigation as geometry.

`player_trace.gd` tracks the XROrigin3D `global_position` each frame and appends new points to a line mesh whenever movement exceeds a minimum threshold. The result is a continuous geometric record of navigation.

```gdscript
# player_trace.gd — _process (actual source)
func _process(delta: float) -> void:
    if not _xr_origin:
        return

    _time_elapsed += delta
    var current_global = _xr_origin.global_position

    # Only record if moved enough — filters noise and standing still
    if current_global.distance_to(_last_global_position) < min_segment_distance:
        return

    _last_global_position = current_global
    var local_point = to_local(current_global)
    local_point.y += trace_height_offset  # keep trail above ground plane
    _trail_points.append(local_point)
    _trail_times.append(_time_elapsed)

    if _trail_points.size() > trail_max_points:
        _trail_points.pop_front()
        _trail_times.pop_front()

    if fade_trail_over_time:
        _fade_old_points()

    _rebuild_trail()
```

`min_segment_distance` is the resolution of the trace. Low values produce smooth curves; high values produce coarser segments, each representing a larger minimum displacement. It is the quantization threshold of the path record — below this distance, positions are indistinguishable.

The geometry is built fresh each frame in `_rebuild_trail()`:

```gdscript
# player_trace.gd — _rebuild_trail (actual source)
func _rebuild_trail() -> void:
    _trail_mesh.clear_surfaces()
    if _trail_points.size() < 2:
        return

    _trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for point in _trail_points:
        _trail_mesh.surface_add_vertex(point)
    _trail_mesh.surface_end()
```

`PRIMITIVE_LINE_STRIP` connects each vertex to the next in sequence. The result is your path through space as a single continuous polyline. `get_trail_length()` integrates total distance: the sum of all small displacement magnitudes, step by step. It is the path length — not the displacement from start to end (that would be the straight-line distance), but the total route taken.

When you stand at the exit and look back, the trace is your translated history written in the world. Every direction change is visible. Every hesitation — where the line overlaps — is readable. Walking leaves marks.

---

## Pick Up Cube: Translation as Consequence

The seven `pick_up_cube` artifacts scattered across the map turn translation into a task structure. Each cube sits at a fixed position. Getting to it requires navigation — translation of your body. Collecting it requires proximity. Your movement is what makes collection possible.

While waiting, the cubes animate in place. This animation is itself translation:

```gdscript
# pick_up_cube.gd — _process (actual source)
func _process(delta: float) -> void:
    if has_been_collected:
        return
    
    rotate_y(rotation_speed * delta)
    
    time_passed += delta
    var bob_offset = sin(time_passed * bob_speed) * bob_height
    global_position.y = original_y + bob_offset
```

Every frame, `global_position.y` is set to a new translated value: `original_y + bob_offset`. The X and Z coordinates are never touched. This is Y-axis translation generated by a sine wave rather than by player input — the same operation, a different driver. The cube oscillates between `original_y - bob_height` and `original_y + bob_height`. `original_y` is the invariant; the displacement relative to it is the variable.

Collection triggers on player proximity:

```gdscript
# pick_up_cube.gd — collect (actual source)
func collect() -> void:
    if has_been_collected:
        return

    has_been_collected = true
    GameManager.add_points(points_value, global_position)
    ...
    await get_tree().create_timer(0.1).timeout
    queue_free()
```

The `global_position` at the moment of collection is passed to `GameManager` — the position is the relevant state. `has_been_collected` is a one-shot flag: once set, all subsequent detection calls are no-ops. The first contact is the event; position at first contact is the data.

Seven cubes. Seven collections. Seven instances of player position overlapping cube position. The `pickup_gate#pickups:7` threshold counts these and opens the exit when all seven are reached. The pickup_gate has no standalone script entry in this map's artifact registry — it is a map-data primitive, declared in the level configuration string rather than implemented as a separate node.

---

## Bridges: Translation as Architecture

`bridge_path.gd` makes translation structural. A bridge across a void is a discrete series of translated positions — the same slab, repeated along an axis, each placed at the next step.

```gdscript
# bridge_path.gd — _generate_bridge (actual source)
func _generate_bridge() -> void:
    var direction := Vector3.ZERO
    match bridge_axis.to_lower():
        "x": direction = Vector3(1, 0, 0)
        "z": direction = Vector3(0, 0, 1)
        "-x": direction = Vector3(-1, 0, 0)
        "-z": direction = Vector3(0, 0, -1)
        _: direction = Vector3(1, 0, 0)

    for i in range(bridge_length):
        var segment := _create_segment(i)
        segment.position = direction * float(i) * cube_size + Vector3(0, 0.5, 0)
        add_child(segment)
        bridge_segments.append(segment)
```

`direction * float(i) * cube_size` is translation by index: a unit vector scaled by integer step and segment size. Each segment sits at position `origin + direction × i × size`. The formula is a discrete translation series — the same operation applied repeatedly with incrementing magnitude. The bridge is translation made walkable.

The map encodes bridges as parameter strings: `"br:z:3"` specifies a 3-segment bridge along Z. `BridgePath.parse_parameters("z:3")` decodes this to `{"axis": "z", "length": 3}`. The axis parameter IS the direction of displacement. Choosing Z means crossing depth rather than width. The bridge knows nothing about your intent — it only knows its axis and its length.

```gdscript
# bridge_path.gd — parse_parameters (actual source)
static func parse_parameters(param_string: String) -> Dictionary:
    var result = {"length": 4, "axis": "x"}

    if param_string.is_empty():
        return result

    var parts = param_string.split(":")
    if parts.size() >= 1:
        var axis_str = parts[0].strip_edges().to_lower()
        if axis_str in ["x", "z", "-x", "-z"]:
            result.axis = axis_str

    if parts.size() >= 2 and parts[1].is_valid_int():
        result.length = int(parts[1])

    return result
```

Notice the axis options: `"x"`, `"z"`, `"-x"`, `"-z"` — no Y. Bridges are horizontal. The bridge system implicitly encodes an assumption about what "crossing" means: you cross laterally or in depth, not vertically. Y-axis traversal is what the platform lifts do. The bridge and the platform divide the translation space between them by axis.

Each segment is built in `_create_segment(index)` as a thin `StaticBody3D` slab — `cube_size * 0.2` in height versus `cube_size * 0.98` in width and depth. The thinness is functional: it makes the slab walkable without obscuring the void below it. The bridge holds your weight. The void remains visible. Both facts are necessary for translation to mean anything.

---

## Transport Cube: Being Translated

The transport cubes offer a different phenomenology. When you stand on a platform and it moves, you are not the agent of translation — you are the object being translated. The coordinate changes. You didn't walk. You were carried.

`transport_cube.gd` configures through exports: `move_distance` (how far), `move_direction` (a `Vector3` specifying axis and orientation of travel), `move_speed` (units per second), `return_delay` (seconds to wait at the endpoint), and `start_delay` (seconds before initial movement begins). `start_transport()` initiates forward movement; `start_return()` sends the cube back. `set_transport_parameters(distance, direction)` lets external code reconfigure displacement without rebuilding the node.

The full implementation of `transport_cube.gd` is not included in this map's artifact documentation — the internal movement mechanics are not shown. What the export interface reveals: displacement is defined by a direction vector and a scalar distance, not by a target position. You specify the change, not the endpoint. This is the formal structure of translation: delta, not destination.

Being carried separates the experience of displacement from the experience of voluntary movement. Your legs aren't moving. Your position changes anyway. Translation doesn't register intention — it registers coordinate change. Whether you walked or were carried, the position is different. The pickup gate counts position overlaps, not steps taken.

---

## The Invariant Reference

At the sequence exit, near the teleporter, sits the `dark_sphere` — a semi-transparent, slowly rotating orb that pulses with low emission. It is not interactive. It does not teach a fact. It exists to be felt rather than read.

From its `spine_hints()`:

```gdscript
# dark_sphere.gd — spine_hints (actual source)
func spine_hints() -> Dictionary:
    return {
        "role":         "ambient",
        "footprint":    Vector2i(1, 1),
        "approach":     "any",
        "reading_dist": 0.0,   # no reading distance — you don't read this
        "height":       -0.5,
        "budget_ms":    0.2,
        "tags":         ["visual"],
    }
```

`reading_dist: 0.0` means the curriculum system doesn't position this artifact for reading. You don't approach it for information. It is the invariant reference — it doesn't change while everything around it does. The bridges are crossed. The cubes are collected. The trace is written. The sphere stays, pulses, rotates slowly. It is what transformation needs to be legible: something that doesn't transform.

The `dark_sphere.gd` `_process(delta)` drives a continuous, slow rotation wobble and a sinusoidal emission pulse — minimum state change, barely perceptible. It is present without asserting itself. Its absence would make the space feel empty.

Every transformation needs an invariant to measure against. This map's invariant is the dark sphere: a fixed reference against which the displacement of cubes, the extension of bridges, and the accumulation of the trace can be perceived as change rather than as noise.

---

## What Comes Next

Trans_AxisDecomposition will take the independence you've already sensed here — that Y doesn't affect X, that Z doesn't affect Y — and make it explicit and controllable. You will decompose a target position into its three components and navigate each axis separately. The commutativity you didn't notice here (translating X then Z arrives at the same place as Z then X) will be stated as a formal property of the group.

Before that: the trace you walked is behind you. The seven cubes are collected. The position that was there is now here. Nothing else changed — not the cube's shape, not its orientation, not the bridge's geometry. Only the coordinates.

That is what translation means.

---

## Possible Artifacts

**position_readout** — A label or HUD element showing the player's current `global_position` as (X, Y, Z) values, updating live. `player_trace.gd` records the path but nothing in this map shows current coordinates numerically. The connection between "I moved" and "my X coordinate changed from 2.3 to 4.1" is not visible. A live readout would bridge walking and number, making the trace readable as a sequence of position states rather than only as geometry.

**displacement_arrow** — A 3D arrow from a cube's starting position to its current position, updated each frame. Neither `y_translation_cube` nor `z_translation_cube` currently renders this — the ghost trail shows position history but not the displacement vector as a named geometric object. An arrow from origin to current position would make `Δposition = current - start` tangible and legible during the oscillation.

**commutativity_demo** — Two pickup cubes, two routes: one route goes X then Z, the other goes Z then X. Both arrive at the same final position, shown by a highlighted landing zone. Translation composes commutatively; rotation does not. Making this visible before Trans_AxisDecomposition would prime the learner for why axis decomposition works — and sharpen the contrast when rotation arrives in a later map and the order suddenly matters.