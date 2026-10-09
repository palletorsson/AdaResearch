# Point_Line_Grid — from a retained position to an address

The dot in Point_Trace retained selected positions. This room gives positions integer addresses within a chosen grid and tests what we can do with them. Follow the four primary artifacts in [final.md](final.md); [technical.md](technical.md) provides the full source reference.

## 1. Metres and indices

Pick up `grab_sphere_point_snap`, move, release, and read its table. Its scene sets `grid_size = 0.05` metres. The source rounds world X, Y and Z independently. On one axis, the operation can be written as:

```gdscript
var index = roundi(pos.x / grid_size)
var placed_x = index * grid_size
```

At this spacing, X = 0.12 gives index 2 and retained X = 0.10. X = 0.13 gives index 3 and retained X = 0.15. The integer counts intervals from world zero; multiplying by the spacing converts that index back to metres.

Move within a rounding region, then cross its halfway boundary. Nearby input positions share an address. The table's two columns describe the retained output in different units; they do not compare raw and rounded measurements. A lattice address names a representative point. Do not confuse it with every possible scheme for numbering the areas enclosed by drawn lines.

On release, the handle moves by the correction needed to align the sampled marker, preserving the marker's offset from the handle. The retained table stays visible. This release can append a repeated address, so its row count is not a count of distinct places.

## 2. The chosen point and the ordered path

Walk with `player_trace`. Desktop uses the active walking body; VR uses headset world X/Z and rig-origin world Y. The source then enters the recorder's local frame:

```gdscript
var local_point = to_local(current_global)
local_point.y += trace_height_offset
local_point.x = roundf(local_point.x / seam_grid) * seam_grid
local_point.z = roundf(local_point.z / seam_grid) * seam_grid
```

The room sets `seam_grid` to one metre. A finer sampled reference accompanies the coarse path. Compare a small loop with a larger one, and in VR compare leaning with stepping. You are testing both the rounding and the choice of point being measured.

The recorder suppresses consecutive repeated rounded positions but can return to a previous address later. It retains an ordered list, including time/speed data in this recorder, and draws direct segments between accepted positions. It does not compute a route along grid edges. Counting recorded segments does not measure distance in metres: their lengths can differ, and they can be diagonal.

## 3. A copy is given another scale

Release a Trace dot or stick with at least two retained positions. `TraceData` duplicates that list. The whiteboard image and walking path are separate; neither is this input.

At `grid_lines`, find the released drawing. The display computes the source bounds' centre and a scale capped to keep the longest dimension within five metres:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Pink uses this transformation. Green snaps those displayed positions to 1/6 metre on each display axis. The source list is unchanged. Its coordinates in the panel therefore need not match the displayed locations. The technical reference distinguishes the source frame, display pitch and the other grids in this room.

## 4. Use two indices to arrange a plan

The placed `plan_vitrine` contains `simulation_grid`. Its source makes five rows of five cell meshes. With the tile mesh and materials already prepared, this is the placement portion of the loop:

```gdscript
for z in range(SIDE):
    for x in range(SIDE):
        var mesh := MeshInstance3D.new()
        mesh.name = "Cell_%d_%d" % [x,z]
        mesh.mesh = tile
        mesh.material_override = light if (x+z)%2 == 0 else dark
        mesh.position = Vector3(x-2, -0.024, z-2)
        add_child(mesh)
```

`SIDE` is 5. Indices run from 0 through 4; subtracting 2 centres the plan. The small vertical offset places the tile surfaces just above the host floor to avoid flicker. These finite cell labels differ from the snapping tool's world-space lattice indices.

Find a cell by its two numbers, walk away and return. The divisions help describe placements without restricting walking to grid edges. A separately created five-by-five box collider supplies the continuous floor. The glass enclosure's panes have no colliders.

Carry this distinction into Point_Triangle_Context: naming or connecting positions does not automatically produce a visible face or a supporting surface.
