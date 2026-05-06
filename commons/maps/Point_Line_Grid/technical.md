# The Grid Trace

## From Continuous to Discrete

In Point_Trace, you moved through space and your path became geometry. The trail accumulated — an unbroken record of where you'd been, stored as a LINE_STRIP of Vector3 positions. That continuity was the point. The trace remembered everything, including the hesitations.

This map introduces a constraint: the grid.

A grid doesn't record everything. It makes a decision about what counts as a position. Between grid nodes, movement is happening — but it doesn't exist yet, not as addressable data. The moment a position snaps to the nearest lattice point, it becomes legible to the system. Everything else is interpolation.

This is not a limitation. It's the mechanism by which space becomes computable.

---

## The Grid as Addressed Space

A grid is a coordinate system made visible. The `grid_lines` artifact renders it as what it is: a set of intersection points, regularly spaced, extending across the XZ plane. Two numbers define the entire structure:

```gdscript
@export var grid_size: int = 8        # cells per axis
@export var cell_spacing: float = 1.0  # meters between grid lines
```

How many cells. How far apart. The grid in this map is 8×14 cells with a central void — a physical space you can stand inside and measure your body against.

What does `cell_spacing = 1.0` mean experientially? Walk from one intersection to the next: that distance is a meter. The grid is a ruler built into the floor. It transforms continuous space into a naming system — every intersection has an integer address, and positions between intersections have no name the grid recognizes.

The rendering uses GDScript's `ImmediateMesh` to draw lines at runtime:

```gdscript
func setup_grid() -> void:
    var line_mesh := ImmediateMesh.new()
    var instance := MeshInstance3D.new()
    instance.mesh = line_mesh

    line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for i in range(-grid_size / 2, grid_size / 2 + 1):
        var x := i * cell_spacing
        # One line along Z, at this X position
        line_mesh.surface_add_vertex(Vector3(x, 0, -grid_size * cell_spacing / 2.0))
        line_mesh.surface_add_vertex(Vector3(x, 0,  grid_size * cell_spacing / 2.0))
    for j in range(-grid_size / 2, grid_size / 2 + 1):
        var z := j * cell_spacing
        # One line along X, at this Z position
        line_mesh.surface_add_vertex(Vector3(-grid_size * cell_spacing / 2.0, 0, z))
        line_mesh.surface_add_vertex(Vector3( grid_size * cell_spacing / 2.0, 0, z))
    line_mesh.surface_end()
```

`PRIMITIVE_LINES` draws each pair of vertices as an independent segment. No triangles, no filled surfaces — just directed edges. The grid is made of nothing but relationships between positions. It has no interior. That's what Point_Triangle will change.

---

## Recording Movement

`player_trace.gd` follows the XROrigin3D node and appends its position to an array whenever the player moves far enough. The structure is the same as Point_Trace introduced, but here it operates inside the grid, making the contrast visible:

```gdscript
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var trace_height_offset: float = 0.05  # floats the trail above ground

func _process(delta: float) -> void:
    var current_global = _xr_origin.global_position

    # Only record if movement exceeds the sampling threshold
    if current_global.distance_to(_last_global_position) < min_segment_distance:
        return

    _last_global_position = current_global
    var local_point = to_local(current_global)
    local_point.y += trace_height_offset
    _trail_points.append(local_point)

    # Drop the oldest point when memory is full
    if _trail_points.size() > trail_max_points:
        _trail_points.pop_front()

    _rebuild_trail()
```

`min_segment_distance = 0.01` means: only record a new point if you've moved at least 1cm. This is a sampling decision. The underlying movement is continuous — your body never stops being somewhere — but the trace samples it at intervals. Between recorded positions, you were there, but it wasn't written down.

`trail_max_points = 1024` imposes a second constraint: only the last 1024 positions are kept. The oldest points get popped from the front as new ones arrive. Memory is finite. The trace forgets.

`_rebuild_trail()` converts the array to a visible mesh each frame:

```gdscript
func _rebuild_trail() -> void:
    _trail_mesh.clear_surfaces()
    if _trail_points.size() < 2:
        return

    _trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for point in _trail_points:
        _trail_mesh.surface_add_vertex(point)
    _trail_mesh.surface_end()
```

`PRIMITIVE_LINE_STRIP` connects each vertex to the next — one continuous polyline through all recorded positions. The mesh is cleared and rebuilt every frame from the array. The geometry isn't persistent; the array is. This distinction matters: the visible line is derived from the data, not the other way around.

---

## Quantization: The Snap

Now introduce the grid's active role. The `grab_sphere_point_snap` artifact makes quantization tangible: grab a sphere, move it through space, and its trail snaps to grid intersections instead of following your hand exactly.

The core operation is one function:

```gdscript
func snap_position_to_grid(pos: Vector3) -> Vector3:
    if not snap_to_grid:
        return pos
    return Vector3(
        round(pos.x / grid_size) * grid_size,
        round(pos.y / grid_size) * grid_size,
        round(pos.z / grid_size) * grid_size
    )
```

`round(pos.x / grid_size) * grid_size` — divide by the grid size to get fractional cell coordinates, round to the nearest integer cell, multiply back to world coordinates. Three arithmetic operations convert a continuous position to the nearest lattice point.

This operation is called quantization. It appears everywhere in computing: pixel coordinates in rasterization, sample positions in audio, voxels in volumetric data, tiles in game maps. The principle is always the same — divide continuous space into discrete units, assign each region to a representative point.

The artifact records snapped positions, not raw positions:

```gdscript
func _process(delta: float) -> void:
    var current_global = _draw_sphere.global_position

    # Snap before any comparison or recording
    var snapped_global = snap_position_to_grid(current_global)

    if snapped_global.distance_to(_last_global_position) < min_segment_distance:
        return

    _total_trail_length += snapped_global.distance_to(_last_global_position)
    _last_global_position = snapped_global
    _trail_points.append(snapped_global)
    _rebuild_trail()
```

Your hand moves continuously through space. The trail only records a new point when it crosses into a new grid cell. The hand knows no grid. The trace only knows the grid.

When the sphere is released, it snaps physically to the nearest node:

```gdscript
func _on_grab_point_dropped(_pickable) -> void:
    if snap_on_drop and _grab_point:
        var snapped_pos = snap_position_to_grid(_grab_point.global_position)
        _grab_point.global_position = snapped_pos
```

`snap_on_drop = true` means the sphere's visual position corrects itself at release. During the drag, the sphere and the trail can diverge — the sphere follows your hand, the trail follows the grid. The moment you let go, the sphere jumps to the nearest node. You feel the correction as a small haptic discontinuity in space.

The data table that appears during interaction exposes the gap between raw and snapped:

```gdscript
# Show raw position and its grid address side-by-side
var table_text = "  POINT (raw)      │  SNAP (grid)\n"
for i in range(start_idx, _trail_points.size()):
    var pt = _trail_points[i]
    var snapped = snap_position_to_grid(pt)
    var grid = snapped / grid_size
    table_text += "(%.1f,%.1f,%.1f) │ (%d,%d,%d)\n" % [
        pt.x, pt.y, pt.z,
        int(grid.x), int(grid.y), int(grid.z)
    ]
```

Two columns: the measured position, and the integer grid address. `(2.37, 0.0, -1.83)` becomes cell `(2, 0, -2)`. The decimal is erased. Where you precisely were is replaced by the name of the cell you were in. Information is discarded. That's what addressing requires.

---

## The Dark Sphere as Invariant Reference

This map includes a `dark_sphere` artifact: a slowly rotating, pulsing dark orb that provides no direct instruction. No interaction, no data display, no snapping behavior.

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta

    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta           # slow drift: 0.15 rad/s
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05  # subtle wobble

    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

`rotation_speed = 0.15` — a slow drift. `pulse_speed = 1.2` — emission that cycles roughly once per second between `0.05` and `0.35` energy. The sphere changes, but barely.

Its function is perceptual. When you're tracing movement across the grid, watching snap points accumulate, the dark sphere occupies peripheral vision as something stable. Because it changes very little, surrounding changes become legible against it. Contrast requires a reference. The sphere doesn't teach the lesson — it holds the space steady so the teaching can happen.

This is a principle of spatial design independent of VR: invariant anchors make variation legible. In an environment where everything moves or responds, choosing what stays still shapes what gets noticed.

---

## What the Grid Does to a Path

Two traces now exist simultaneously in this space: `player_trace`, which records continuous movement sampled at `min_segment_distance`, and `grab_sphere_point_snap`, which records the same kind of movement quantized to grid nodes.

Walk a diagonal line across the grid while dragging the snap sphere along the same path. The player trace follows the diagonal. The snap trace draws a staircase — the Manhattan path through grid cells that approximates your diagonal.

```gdscript
# Continuous trace: records actual position at each sample
var local_point = to_local(current_global)
_trail_points.append(local_point)

# Snapped trace: records only the grid cell crossing
var snapped_global = snap_position_to_grid(current_global)
if snapped_global.distance_to(_last_global_position) > min_segment_distance:
    _trail_points.append(snapped_global)
```

The staircase and the diagonal represent the same physical movement. They differ because they answer different questions. The continuous trace asks: where was the body? The snapped trace asks: which cell was the body in?

As `cell_spacing` decreases toward zero, the staircase approximates the diagonal more closely. At `cell_spacing = 1.0` — one meter per cell — the deviation is large and visible. This degradation is called aliasing: the grid is a sampling frequency, and when the signal (your movement) changes faster than the sampling frequency, information is lost and artifacts appear. The staircase is an alias of the diagonal.

This map doesn't visualize aliasing directly — there is no side-by-side comparison — but you feel the gap when dragging the snap sphere. Your hand traces a smooth arc; the trail hops between nodes. The continuous and the discrete coexist in the same space. One of them writes the history.

---

## Coordinates as Politics

The grid makes space addressable. A position that can't be named by the grid doesn't exist, from the system's perspective. This is not neutral.

Every coordinate system has an origin. The origin — `(0, 0, 0)` in Godot 4 — is the center of the reference frame. All positions are measured relative to it. Change the origin, change all the coordinates. The positions in space don't move; the names change.

```gdscript
# player_trace.gd stores positions in local space
var local_point = to_local(current_global)
```

`to_local()` transforms a world-space position into the coordinate frame of the `player_trace` node itself. If you move the node — drag it to a different location in the scene — all recorded coordinates shift, not because you moved differently, but because the reference frame moved. The trace is always relative to something. Absolute coordinates don't exist in Godot 4; only positions relative to some node's transform, composed all the way up to the scene root.

Every node in the scene tree carries a `Transform3D`. `global_position` is a convenience: the result of composing every parent transform from root to leaf. The "world" is just another coordinate frame, distinguished by convention.

The grid makes this concrete. `cell_spacing = 1.0` and `grid_size = 8` defines a specific frame — one where the relevant positions are integer multiples of one meter, centered on wherever the `grid_lines` node is placed. Walk outside the grid's footprint and the floor is still there, but the addressing stops. The space continues; the frame ends.

The choice of what to center, what to call zero, and how finely to subdivide is always made by someone. Coordinate systems encode decisions — about what differences matter, what distances are worth naming, whose body fits inside the frame. The grid makes those decisions visible as geometry.

---

## Into the Triangle

Both Point_Trace and this map work with paths: sequences of positions connected by edges. A path has length. It has direction. What it doesn't have is area.

Three points arranged in a line don't close. Pull the third point off the axis, and something new appears: a bounded region. An interior. A surface with a front and a back.

The triangle is the first closed form. It's also the atomic unit of GPU rendering — everything rendered on screen, every mesh in this project, every face of every object, is decomposed into triangles before the hardware touches it. Point_Triangle begins where this map ends: not with where things are, but with what they enclose.

The grid prepared the ground for this. A grid of quantized positions is a lattice of candidate vertices. Triangulation is the problem of connecting lattice points to form surfaces. The snap function that made your trace staircase is the same operation that would pin a mesh's vertices to integer coordinates. The grid and the triangle aren't separate topics — they're the same question at different scales.

This map ends with position. The next map ends with area.

---

## Possible Artifacts

**dual_trace_comparator** — Places two simultaneous traces of the same movement: one continuous (from `player_trace`), one snapped (from `grab_sphere_point_snap`). A thin connecting line between corresponding points would visualize the quantization error — the distance between where you were and where the grid recorded you. Aliasing made visible rather than felt.

**grid_size_slider** — A Rams-style panel with a single `cell_spacing` slider. Adjusting it in real time would rebuild the grid and the snap function, letting the learner watch the staircase approximate a diagonal as quantization becomes finer. Currently both `grid_size` and `cell_spacing` are fixed at map load. This is the one parameter that changes the entire lesson's perceptual argument.

**coordinate_frame_shifter** — A grabbable origin marker. Moving it recomputes all displayed coordinates relative to the new position, making the relativity of coordinate frames tangible. The physical positions in space stay identical; the numbers change. No artifact currently demonstrates that coordinate values are reference-frame-dependent — which is the hardest conceptual move this map asks for.