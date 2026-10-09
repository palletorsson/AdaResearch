# Point Grid — give the record addresses

**Learning elements**

- Reusing a retained list
- Display coordinates
- Snapping in X, Y and Z
- Source and derived positions

Release a drawing pen in Trace, then enter Grid in the same running Endless Museum session. Find your bend above the ruled field. Pink displays the recorded shape; green gives it another spacing. The nearby panel says **THIS SESSION** and lists the source world positions.

Trace taught us to append positions, read an index and traverse neighbours. Here we reuse that list. The museum supplies its session transfer, display fitting, meshes and page controls. The snapping sphere and walking trail have their own records; this lesson follows the released pen drawing.

## Receive a copy

`commons/globals/trace_data.gd`, `add_trace()`, accepts at least two positions and stores a snapshot:

**Museum code excerpt**

```gdscript
var new_trace = points.duplicate()
saved_traces.append(new_trace)
```

Each release adds a snapshot of the pen's retained list. Because the pen continues across pickups, a later release can include positions from earlier drawing. `TraceData` survives room changes in this game process. Stopping the game loses this session store.

Open `commons/primitives/line/grid_lines.gd`. `_ready()` reads existing snapshots and listens for later releases. `_create_trace_mesh()` receives one list as `points`. Its loop reads values without assigning new positions into that source array.

## Fit before rounding

The source positions are world coordinates from Trace. `_display_frame()` finds their bounding-box centre and a display scale: normally fivefold, reduced when needed to fit the largest dimension within five metres.

**Museum code excerpt** — the pink rendering loop in `_create_trace_mesh()`:

```gdscript
for p in points:
    mesh.surface_add_vertex((p - center) * final_scale)
```

Subtracting `center` moves the drawing's centre to local zero. Multiplying by `final_scale` changes its size. Both pink and green use this same fit, then both are lifted above the field. The original entries stay in world coordinates. Pink is already a display transformation of the source, rather than a second record of your hand.

The green version starts with that fitted position:

**Museum code excerpt** — inside `_create_shadow_trace()`:

```gdscript
var scaled = (p - center) * scale_factor
var snap_step = cell_spacing / float(max(1, shadow_snap_subdivisions))
var snapped = scaled.snapped(Vector3.ONE * snap_step)
```

The scene sets six subdivisions of each one-metre interval, giving a pitch of one sixth of a metre **in display space**. `Vector3.ONE` applies that pitch to X, Y and Z. The floor ruling is flat; the operation is three-dimensional.

**Reduced code excerpt** — an integer-address illustration for values away from exact halfway boundaries, not replacement code:

```gdscript
var address := Vector3i(
    roundi(scaled.x / snap_step),
    roundi(scaled.y / snap_step),
    roundi(scaled.z / snap_step)
)
var placed := Vector3(address) * snap_step
```

Divide to count intervals, round to whole-number counts, then multiply to place the result. At a pitch of one third of a metre, displayed X = 0.15 rounds to address 0, while 0.18 rounds to address 1.

An array index tells us *which retained sample*. An address tells us *which place on this display lattice*. Several samples may acquire the same address. The museum's green builder filters consecutive results using a squared-distance threshold of 0.001; at the pitches used here, equal neighbours are removed and distinct neighbours pass. A later return to an earlier address remains possible. Fewer than two surviving positions produce no green line.

## Change one interval

Use PREVIOUS or NEXT on the panel to hold a page of source positions. Choose a bend in pink and note which green corners coincide. AUTO resumes paging; these controls leave the record intact.

**Student edit** — in `grid_lines.gd`, add this line at the start of `_ready()`, before `setup_grid()`:

```gdscript
shadow_snap_subdivisions = 3
```

This overrides the scene's value of six. It changes the green pitch to one third of a display metre and keeps the panel's pitch calculation consistent. Merely changing the script's exported default would leave the scene override in force.

Save the edit before running the museum. Make and release a new drawing in Trace, then enter Grid in that same session. Compare its pink bend with the coarser green result; the source rows still describe the retained drawing. Predict which nearby displayed positions will share an address using the one-third-metre example above. A restart loses the earlier session's drawing, so different runs are not a comparison of the same source. Remove the added line to restore six subdivisions for the next run.

The green line joins accepted neighbours directly, so a segment can be diagonal. Finer addresses cannot recover movement Trace never kept. You can now transform a retained drawing while preserving its source. Triangle will give a few chosen positions a new relation: a closed boundary and then a face.
