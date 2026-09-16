# Point Line Grid — positions, frames and replay

Point_Trace distinguished the dot's position list from the whiteboard's painted image. Here, several artifacts apply rounding in different coordinate frames. Point_Triangle_Context follows by asking what a closed boundary needs before it can become a face.

The first passage follows `grab_sphere_point_snap`, `player_trace`, `grid_lines` and the placed `plan_vitrine`. The room's other three artifact types remain secondary. This reference expands the shorter program in [tutorial.md](tutorial.md).

## Begin with the held point

`grab_sphere_point_snap` uses a 0.05 m grid in world X, Y and Z. Its central operation is:

```gdscript
return Vector3(
    round(pos.x / grid_size) * grid_size,
    round(pos.y / grid_size) * grid_size,
    round(pos.z / grid_size) * grid_size
)
```

Divide by the spacing, round, multiply back. With 0.05 m spacing, 0.12 m rounds to 0.10 m and 0.13 m rounds to 0.15 m. The two outcomes are one lattice interval apart. The inputs can lie arbitrarily close on opposite sides of the halfway boundary.

Move the held tool slowly and compare its marker with the trace. Its ground table reports retained positions in metres and signed lattice indices: a retained X of 0.15 m has index 3. These are two descriptions of the retained sample. There is no second column containing the original unrounded input.

On release the tool moves its handle by the correction required to place the visible sampled tip on the grid:

```gdscript
var tip_position: Vector3 = _draw_sphere.global_position
var snapped_pos: Vector3 = snap_position_to_grid(tip_position)
_grab_point.global_position += snapped_pos - tip_position
```

The local offset of the marker is preserved. The released tip is appended to the retained array and the table remains available. The callback can therefore append the release position even if that position was already the last recorded point. A row count is a count of stored entries, not necessarily of unique addresses.

## Choose which point in the visitor to record

`player_trace` follows the active museum walking body on desktop. In VR, `_tracked_position()` combines headset-camera world X/Z with rig-origin world Y. Physical movement inside a stationary rig enters the record; a horizontal lean can enter too. Vertical head movement alone does not change this chosen floor position.

The installed token enables `seam_grid:1.0` and `show_discarded:1`. The finer reference is sampled from the same selected position. It is still a sampled record. The coarser path uses:

```gdscript
var local_point = to_local(current_global)
local_point.y += trace_height_offset
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

Only local X and Z are rounded. The display offset is 0.05 m. After the movement gate, consecutive duplicate rounded positions are suppressed. The path retains up to 1024 positions with sample times and speeds; the finer reference has its own limit of four times that count. Fading is off in this placement.

Walk within one rounding region, then cross its edge. Compare how much the reference changes with how much the coarse position changes. The rounding regions extend halfway between lattice nodes. They are not necessarily the squares enclosed by a separately drawn set of grid lines.

An ordered path can return to an earlier address. It is not a set containing each visited cell once. Both path meshes connect their accepted points directly; diagonal segments are allowed. Neither computes an axis-by-axis route or guarantees that the connecting segment follows walkable ground.

## What arrives at grid_lines

Releasing `draw_dot` or `draw_stick` sends its retained world-position list through `TraceData.add_trace()`. The store accepts lists with at least two points and duplicates them. `grid_lines` loads existing snapshots when it enters the scene and receives later ones through `trace_added`.

The store is an autoload in this running game. It survives changes of room but supplies no disk save here. It stores positions without the originating pen's colour, identity or timestamps. The separate whiteboard painting and `player_trace` do not publish their records to this store.

`grid_lines.tscn` supplies six lines in each direction. The script positions them one metre apart, from -2.5 to +2.5 in local X/Z, making five-by-five cells. This finite drawing neither limits the coordinate system nor defines the walking recorder's origin. Since five cells place zero between two rulings, no ruling is coloured as a zero axis in this scene.

For each released trace, `_display_frame()` finds its bounding-box centre and chooses a scale: fivefold enlargement, reduced if necessary to keep its largest dimension within five display metres. The pink mesh uses:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

The green mesh rounds the transformed positions:

```gdscript
var snap_step = cell_spacing / float(max(1, shadow_snap_subdivisions))
var snapped = scaled.snapped(Vector3.ONE * snap_step)
```

The scene sets six subdivisions, so `snap_step` is 1/6 m in display space, in all three axes. Consecutive results must also pass the existing squared-distance threshold of 0.001 before entering the green mesh. With this pitch, identical snapped positions fail and distinct neighbours pass. Green is displayed only when at least two positions survive. Rotation is disabled by this map's token; the lattice itself never rotates.

The cased panel names source count and length, enlargement and display pitch. Rows show the latest source's world coordinates to three decimal places, ten per page, advancing every two seconds. The summary covers the latest ten releases; the scene can still contain older replay meshes. Displayed length and source length should not be confused. The original source array is unchanged by either rendering transform.

## The numbered plan

The placed `plan_vitrine` wraps `commons/artifacts/simulation_grid/simulation_grid.tscn`. Its script creates 25 cell meshes with indices X/Z = 0 through 4. Their local centres use `Vector3(x-2, -0.024, z-2)`: the plan's cell `(2,2)` is horizontally centred at local zero. A one-metre change in either index moves a cell by one metre.

These indices name finite cells in this particular plan. The held tool's signed lattice indices count from world zero. Neither numbering scheme defines the walking recorder's local origin. Keep the frame and the kind of thing being indexed explicit when comparing them.

Each visual tile measures 0.988 by 0.988 m horizontally, with 0.06 m thickness and a top 0.006 m above local zero. A separate `PlanFloor` static body has one 5 by 0.06 by 5 m box collider centred at Y = -0.03, giving a continuous top at zero. The tile gaps do not become gaps in that collider. The vitrine's glass panes have no colliders. Its additional controller-mounted drawing behavior is outside the primary floor-plan exercise and awaits headset validation.

## The basin and the next boundary

The current museum map requests a one-metre-deep basin with a glass lid. The museum builder supplies the walkable glass; `grid_lines` supplies line geometry without a floor collider. The readout stands beside the right rim, 1.2 m above deck height when stamped at that basin depth.

Positions can be named beyond the drawn lattice. Whether someone can stand there needs collision geometry and a route; coordinates alone do not answer it. The next room makes a related distinction between an edge loop and a filled triangle.

Possible later controls include changing the walking grid's spacing or moving its origin while keeping the same source positions. They are proposals, not installed controls. The current experiment already lets the visitor change the gesture's purpose: use a coarse region to hold a stable address, or use crossings to compose a rhythm.


## Encounter reference, 15 September 2026

[Companion notes for the current book passage](encounter-reference.md) retain instrument settings, recording distinctions and code excerpts moved out of the main reading.

Source entry points: `commons/primitives/point/grab_sphere_point_snap.gd` and its scene; `commons/primitives/point/player_trace.gd`; `commons/globals/trace_data.gd`; `commons/primitives/line/grid_lines.gd` and its scene; `commons/artifacts/plan_vitrine/plan_vitrine.gd`; `commons/artifacts/simulation_grid/simulation_grid.gd`.
