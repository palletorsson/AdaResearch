# Eight interactions through the museum

5 October 2026 · Five revised tutorials

Eight interaction topics are now taught through five existing halls. Each lesson selects a small operation, names the supplied machinery and carries a usable distinction onward. The complete revised tutorial text follows each hall image.

This pass changes tutorial.md and its teaching metadata. It leaves final.md and museum runtime code intact. The images are earlier captures from inside the Endless Museum, with dates and provenance; they are not new playtests. Student code edits are exercises described in the lessons, not changes applied to the museum. Source reading supports the explanations; hands-on learning and headset comfort still need a trial.

## The eight topics

| Topic | Hall | Teaching choice |
|---|---|---|
| Pickup / release | Point_Coordinates | Separate the body from its connection to the hand; release restores this sphere's frozen state. |
| Grip alignment | Point_Trace | Move the grip relative to the nib, keeping the recorded tip explicit. |
| Named actions | Color_Paint | Follow trigger_click press/release and trigger pressure through the supplied input route. |
| Interaction states | Trans_Introduction | Introduce target/current state; Paint returns to held, active and receiving states. |
| Targeting | Color_Paint | Follow the nozzle ray, first eligible collision, receiving surface and range checks. |
| Snapping | Point_Line_Grid | Round fitted display coordinates in XYZ while preserving the source drawing. |
| Feedback | Trans_Introduction | Read actual bank motion; Paint distinguishes valve feedback from successful deposition. |
| Surface painting | Color_Paint | Convert a world hit into surface UV and call the existing shared drawing operation. |

## 1. Point_Coordinates — Carry a position

**Before:** The lesson already followed the black sphere and compared local with world coordinates. Release was mentioned without explaining what happens to the body.

**Changed:** Keep that focus. Explain that releasing ends the hold and restores this point's frozen state. The sphere stays in the room; its own held-state guide disappears.

**Try:** Disable pickup, restore it, choose another starting position, then carry and release the point while naming each coordinate frame.

**Carries forward:** A held body and a position can be connected without treating the hand, mesh, collider and coordinate frame as one thing.

![The black held point is in the foreground. Its coordinate frame and LOCAL readout remain in the room.](figures/coordinates.png)

The black held point is in the foreground. Its coordinate frame and LOCAL readout remain in the room. Archive: 2026-10-03.

### New tutorial text

### Point Coordinates — carry a position

**Learning elements**

- Pickable
- 3D coordinate system
- Local and world position

Take the black sphere at the entrance. Its label stays behind. The point follows your hand.

Point One separated a position, a surface and a physical boundary. Here we learn what makes that body grabbable, then read its position in local and global coordinates.

Work with the existing sphere and coordinate frame in the Endless Museum. The player and XR controls are already configured. The excerpts below come from the artifact's scripts; make the small edits in your working copy.

## What makes it grabbable?

Open `commons/primitives/point/interactive_point_origin.gd`. Near the top is:

```gdscript
extends XRToolsPickable
```

`extends` gives this script the behaviour of an existing class. `XRToolsPickable` is a physics body with pickup behaviour. Our point keeps that behaviour and adds its own appearance and feedback.

The sphere's mesh makes it visible. Its collision shape gives it a physical boundary. The pickable behaviour lets the prepared grab system take hold of the body. A mesh or collider alone does not supply that interaction.

Take the sphere, move it and release it. The mesh and collider belong to the held body, so they move together. The station's label belongs elsewhere and stays behind.

Release ends the connection to the hand. This point's scene starts with `freeze = true`, and the pickable's release mode restores that original setting. It stays where you leave it; letting go does not necessarily mean falling. In `interactive_point_origin.gd`, `_on_picked_up()` sets `_is_held = true`; `_on_dropped()` sets it to `false` and hides the point's own position label and guide. The body remains in the room. The supplied grab system moves the body; these handlers respond to the beginning and end of that hold.

Open `commons/primitives/point/point_condition.gd`. In the `held` branch, find `held.position = CENTRE`. Immediately below it, add:

```gdscript
held.set("enabled", false)
```

`held` refers to the existing pickable instance. `set()` changes a named property; `false` switches its pickup permission off. Restart your working copy and try taking the sphere. Its surface and collision shape remain, but the XR grab system refuses the pickup.

Remove the added line and restart. The sphere can be held again. You changed its availability to the hand without rebuilding its shape.

## Local to what?

In the same branch, the original assignment is:

```gdscript
held.position = CENTRE
```

`CENTRE` is `Vector3(0, 1.12, 0)`. A node's `position` is local to its parent. Here that parent is the point's station: the sphere starts at X = 0, Y = 1.12, Z = 0 in the station's frame.

Replace the assignment with:

```gdscript
held.position = CENTRE + Vector3(0, 0.5, 0)
```

The corresponding components add together. Only Y changes, from `1.12` to `1.62`. Predict where the sphere will appear, then restart. It begins higher along the station's Y direction; the label stays put.

Restore `held.position = CENTRE`.

## One point, two addresses

Carry the sphere towards the coloured frame in the basin. Pink marks X, grey marks Y and black marks Z. Move along one direction, then another, watching the LOCAL card. Moving from the origin along the labelled Z arm increases local Z.

Compare LOCAL with WORLD while holding the sphere still. The same point can have different coordinates because the readings use different frames.

Open `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd`. These two lines occur at separate places in `_process()`:

```gdscript
var world_p: Vector3 = pt.global_position
```

```gdscript
var lp: Vector3 = to_local(pt.global_position)
```

`pt` refers to the sphere we are holding. `global_position` gives its position in the scene's world frame. The first line keeps that value in `world_p`.

The second line converts that world position into the coordinate frame running this script: the coloured frame. `lp` holds the result. `: Vector3` states that each variable contains three components.

The conversion accounts for the frame's position, orientation and scale. Here the frame has a scale of `1.5`, so one local unit spans 1.5 world units. Converting between these frames involves more than choosing another zero.

The sphere's parent and the coloured frame are different nodes. Reading `pt.position` would give coordinates relative to its parent. `to_local(pt.global_position)` deliberately asks for coordinates relative to the coloured frame, wherever the sphere is parented.

Point Zero introduced `_process()`. Here it keeps reading while the grab system moves the body. Holding and reporting are separate jobs connected by the same point.

## Beyond the drawn frame

Carry the sphere beyond an arrow's end. The drawing stops, but its coordinate system still describes positions beyond it. Watch the guides and readings continue to follow your hand.

Choose another starting position in the station. Predict which component will change, try it, then carry the sphere to the frame. Release it and move your empty hand: which object stops following? Explain what WORLD and LOCAL each measure from. You can now change where a body begins, control whether it can be grabbed, and name the frame used to read its position.

In Point Lines, we will keep two positions and examine what joins them. Distance calculation begins there.


[Before](before/Point_Coordinates.md) · [Exact changes](diffs/Point_Coordinates.diff) · [Current tutorial](../../../../commons/maps/Point_Coordinates/tutorial.md)


## 2. Point_Trace — A grip, a tip, a retained line

**Before:** The earlier lesson taught a portable starter and a different persistence arrangement. The museum pen's grip and shaped, cumulative record were not the teaching host.

**Changed:** Follow the existing red pen: movement gate, shaped world position, ordered list and neighbour traversal. Distinguish WritingGrip from WritingTip; release copies the retained record into session storage.

**Try:** Move the grip three centimetres towards the nib, compare the held reach with each hand, then restore it. Draw and release a bend for Grid.

**Carries forward:** A relation between hand and tool, and the student's cumulative ordered drawing. The list is bounded and lasts for this game session.

![The museum's pens and plinth readouts. The lesson follows the red pen and its retained positions; the other exhibits remain part of the encounter.](figures/trace.png)

The museum's pens and plinth readouts. The lesson follows the red pen and its retained positions; the other exhibits remain part of the encounter. Archive: 2026-09-29.

### New tutorial text

### Point Trace — keep the way through

**Learning elements**

- Ordered position lists
- Sampling conditions
- Indices and neighbour loops
- Pen grip and writing tip

In the Endless Museum's Trace hall, take the red pen from its plinth. Draw a bend, pause, then return towards its beginning. Release the pen. The line remains. Read the retained count and the last ten positions on its plinth.

Lines gave us a segment between two positions. Here we keep positions in order and connect each one to its neighbour. The museum supplies the player, pickup system, pen, renderer and session storage. Work in the existing project; this lesson follows the pen's record.

## Keep accepted positions

Open `commons/primitives/point/draw_dot.gd`. Its list is declared near the top:

**Museum code excerpt**

```gdscript
var _trail_points: Array[Vector3] = []
```

An `Array` is an ordered list. Each entry holds a `Vector3`: three coordinates describing one position. The list has one index, even though each position has three components.

In `_process()`, `_draw_sphere` refers to this pen's `WritingTip`. The recorder reads its world position. While held, recording waits for the grip to arrive; the pickup approach does not become a line. The movement gate then decides whether to consider another reading. The placed pens use a five-millimetre threshold.

**Reduced code excerpt** — the central recording steps in `_process()`, with guards and display work omitted:

```gdscript
var current_global = _draw_sphere.global_position
var dist = current_global.distance_to(_last_global_position)
if dist < min_segment_distance:
    return
_last_global_position = current_global
var rec: Vector3 = _shape_sample(current_global)
_trail_points.append(rec)
```

`append()` adds a value at the end. `_shape_sample()` gives the red pen's positions a ten-millimetre spacing in free space; the green and blue pens use forty and eighty millimetres. The full function also rejects a shaped position equal to the previous retained one. The movement threshold and the shaping grid make different decisions. The comparison position updates when the movement gate passes, even if shaping later rejects that reading.

Keep this experiment away from the whiteboard, where samples can instead be projected onto its face. Pause with a steady hand: time alone adds no entry.

## Follow the order

`_trail_points[0]` reads the first retained position. `_trail_points[1]` reads the second. The plinth numbers these as rows 1 and 2; code indices start at zero.

In `_rebuild_trail()`, the non-fading branch sends the values to a line strip:

**Museum code excerpt**

```gdscript
for point in _trail_points:
    _trail_mesh.surface_add_vertex(point)
```

The renderer connects consecutive vertices. With four entries, it joins 0–1, 1–2 and 2–3. To inspect these pairs explicitly, the existing walking recorder uses this loop in `commons/primitives/point/player_trace.gd`, `get_trail_length()`:

**Museum code excerpt**

```gdscript
for i in range(1, _trail_points.size()):
    length += _trail_points[i].distance_to(_trail_points[i - 1])
```

`range()` stops before the size. Beginning at 1 makes `i - 1` the preceding valid index. This loop visits a retained list; `_process()` revisits the moving pen over time.

Trace your bend in its drawing order. Returning to an earlier place can add another entry there. Release and pick up again: the pen continues its retained list rather than starting a new stroke. Its capacity is 4096 positions; adding beyond that removes the oldest entry.

## Seat the pen in your hand

Open `commons/primitives/point/drawing_pen.gd`, `build_body()`. `WritingGrip` determines the pen's held alignment. `WritingTip` is a separate marker at local Z = −0.155 metres; that is the position we record. Local −Z points towards the nib.

**Student edit** — insert one line after `grip.name = "WritingGrip"`, before `pen.add_child(grip)`:

```gdscript
grip.position.z = -0.03
```

Re-run Trace and pick up the pen with each hand. The grip is now three centimetres towards the nib, shortening the tip's reach from the pickup frame. Turn your wrist and draw another bend. Does the visible nib still meet the start you intended? Compare with the original, then remove the line. This shared helper also builds the board's simple pens.

You have adjusted the held tool while following the same ordered record. Release a drawing with at least two positions before entering Grid. Release copies the whole retained list into `TraceData` for this running session; it does not save a file. Grid will give that record another arrangement without changing its source positions.


[Before](before/Point_Trace.md) · [Exact changes](diffs/Point_Trace.diff) · [Current tutorial](../../../../commons/maps/Point_Trace/tutorial.md)


## 3. Point_Line_Grid — One record, another spacing

**Before:** The starter-based account rounded source coordinates before display fitting and described persistence across runs.

**Changed:** Use the actual museum handoff: preserve the released world-position list, fit it for the display, then snap XYZ display positions. An index names a sample; a spatial address names a place.

**Try:** Set three display subdivisions before starting a new run. Draw and release a fresh trace; compare its fitted pink and snapped green versions beside the unchanged source rows.

**Carries forward:** Source and derived data remain separate. Snapping here is coordinate quantization, not an XR docking zone; finer pitch cannot recover unrecorded movement.

![The ruled basin, pink and green trace display, and source readout inside the museum. This older capture includes an earlier plinth design.](figures/grid.png)

The ruled basin, pink and green trace display, and source readout inside the museum. This older capture includes an earlier plinth design. Archive: 2026-09-21.

![The panel separates source world positions from the centred, scaled display and its 0.1667 m snap pitch. This is an archived demonstration record.](figures/grid-reading.png)

The panel separates source world positions from the centred, scaled display and its 0.1667 m snap pitch. This is an archived demonstration record. Archive: 2026-09-21.

### New tutorial text

### Point Grid — give the record addresses

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


[Before](before/Point_Line_Grid.md) · [Exact changes](diffs/Point_Line_Grid.diff) · [Current tutorial](../../../../commons/maps/Point_Line_Grid/tutorial.md)


## 4. Trans_Introduction — Ask the bank to move

**Before:** The intended event/reset focus was not yet anchored to the installed MOVE THE BANK controls.

**Changed:** Trace the slider and RESET signals into one shared setter. Separate requested from current displacement; explain the physics update and feedback of actual motion.

**Try:** Double SPEED and predict a full journey of about two seconds instead of four. RESET returns gradually to the same home position. Restore the original value.

**Carries forward:** A request can change immediately while the body takes time to fulfil it. A readout must say which state it reports.

![MOVE THE BANK and its readout beside the crossing, captured in the Endless Museum. The triangulated floor belongs to this hall's existing scene.](figures/bank.png)

MOVE THE BANK and its readout beside the crossing, captured in the Endless Museum. The triangulated floor belongs to this hall's existing scene. Archive: 2026-09-28.

### New tutorial text

### Transformation Introduction

**Learning elements**

- Signals and event handlers
- One function for shared behaviour
- Target and current state
- Gradual reset
- Readout feedback

Trans_Pre used elapsed time to change a cube's pose. Here, an action chooses where a surface should go. Work with the existing MOVE THE BANK panel beside the rotation crossing. Its BANK slider and RESET button control the far landing.

First watch the three supplied crossings: a transport cube moves, a growing cube reaches floor height, and a plank turns to meet the banks. Their automatic motion supplies the encounter. This lesson follows the landing's controls, from an event to a visible change.

Move BANK toward its maximum, then release it. Watch the landing continue toward the requested position. Press RESET before it arrives. The slider returns immediately; the landing changes direction and travels home. Use the fixed side aisle to compare the bank edge and readout while the plank keeps turning.

The excerpts below come from `commons/artifacts/adjustable_landing/adjustable_landing.gd`. They explain the installed artifact; its geometry, controls and object references are already supplied.

## The panel announces an event

In `_ready()`, `RackTemplates.gd` creates the panel. The script finds its slider as `Param_0` and the RESET button's `InteractableAreaButton` as `reset`, then connects their signals:

```gdscript
slider.slider_moved.connect(_on_slider)
reset.button_pressed.connect(func(_button): reset_landing())
```

A signal announces that something happened. Connecting it names the code to run when that event occurs. Moving the slider calls `_on_slider`; pressing the panel button calls `reset_landing` through the short anonymous function. The button signal includes a button argument, which this function accepts but does not use.

## Both paths reach one function

```gdscript
func _on_slider(_value: Variant) -> void:
    if not _syncing:
        set_bank_fraction(float(slider.get_normalized_value()))

func reset_landing() -> void:
    set_bank_fraction(0.0)
```

The slider wrapper converts its physical position to a fraction from zero to one. `_on_slider` reads that fraction rather than using the signal's raw value. RESET requests the same operation with zero as its argument. Both events therefore share the named function `set_bank_fraction`:

```gdscript
func set_bank_fraction(fraction: float) -> void:
    target_displacement = clampf(fraction,0.0,1.0) * TRAVEL
    if is_instance_valid(slider) and not _syncing:
        _syncing = true
        slider.set_normalized_value(target_displacement/TRAVEL)
        _syncing = false
```

`TRAVEL` is one metre. Clamping bounds the request, so a fraction of `0.5` requests half a metre. The function also puts the slider at the requested fraction, which matters when RESET calls it. `_syncing` prevents a slider event during that update from repeating the request.

## Separate the request from the motion

`target_displacement` stores the requested offset. `displacement` stores the current offset. The physics callback brings the current value toward the target:

```gdscript
func _physics_process(delta: float) -> void:
    displacement = move_toward(displacement,target_displacement,SPEED * delta)
    landing.position = HOME + Vector3.BACK * displacement
    _update_readout()
```

`SPEED` is `0.25` metres per second; `delta` is the time since the previous physics tick. Multiplying them gives this tick's maximum movement. `Vector3.BACK` means local positive Z. Adding that offset to `HOME` moves the landing along its existing route.

RESET changes the target to zero. It never assigns zero directly to the current displacement, so returning home remains gradual. Once the target is reached, `move_toward` leaves the bank there.

## Read what has happened

`_update_readout()` formats the current `displacement` as `BANK +… m`. It reports “edges meet” at zero and otherwise gives the gap for the plank's aligned pose. Immediately after RESET, the slider can show zero while this readout still shows a positive distance. Those displays describe the request and the moving bank respectively. The gap label describes the surfaces; crossing also depends on the player's body and movement.

## Try one source parameter

For a local experiment, change only `const SPEED := 0.25` to `const SPEED := 0.50` in the landing script, then rerun the existing scene. Predict the result before moving BANK fully from home: one metre should take about two seconds instead of four. RESET from the far endpoint should take the same reduced time. The endpoints and final gap stay the same. Compare the readout during travel, then restore `0.25`.

Trans_Translation extends this distinction between a destination and the journey to it through carrier routes. Carry forward the question established here: which function changes the request, and which callback performs the movement?


[Before](before/Trans_Introduction.md) · [Exact changes](diffs/Trans_Introduction.diff) · [Current tutorial](../../../../commons/maps/Trans_Introduction/tutorial.md)


## 5. Color_Paint — Aim, activate, leave a mark

**Before:** The automatic UV path led the lesson. The hand's route from pickup through activation to a valid receiving surface was secondary.

**Changed:** Start with the manual can. Distinguish trigger_click events from trigger pressure, held from active, and mist from a successful hit. Convert world hit to local surface UV and return to the shared draw_spray method.

**Try:** Halve manual spray reach. From beyond and within that range, predict when mist becomes a canvas deposit; restore the original reach.

**Carries forward:** A reusable input-to-receiver chain. Manual and automatic callers share an operation, while the image they alter is not a recoverable list of gestures.

![The manual cans, their tray and shared canvas in the museum. Mist, deposits and accumulated colour are different stages of the interaction.](figures/paint.png)

The manual cans, their tray and shared canvas in the museum. Mist, deposits and accumulated colour are different stages of the interaction. Archive: 2026-09-28.

### New tutorial text

### Aim, activate, leave a mark

**Learning elements**

- Named actions and interaction states
- Ray targets
- Surface coordinates
- Shared drawing methods
- Interaction feedback

Pick up a colour from the tray. Aim at the canvas without pressing the trigger: your hand moves the can, but leaves no mark. Hold the trigger, make a short pass, then release it while keeping the can in your hand. Finally, let go of the can; it returns to its dock. On desktop, right-click carries or returns a can; holding the left mouse button sprays.

Coordinates taught you to carry an object; Trace made repeated positions visible. Here the moving nozzle must reach a receiving surface with its ray. The local/world transforms and function calls you already know connect the nozzle to that surface.

The museum supplies the can, controller rig, collision shapes, particles and canvas renderer. Open `commons/context/drawingboard/spray_can.gd` to follow the interaction. Its `nozzle` variable references a child created in `_ready()`; its inherited `_current_controller` references the controller holding this can. The excerpts below belong to those existing objects.

**Separate carrying from activation**

The OpenXR action map, `openxr_action_map.tres`, names two inputs: `trigger_click` reports a pressed/released state; `trigger` supplies a scalar value. The pickup function routes `trigger_click` to the held object's `action()` or `action_release()`. These emit the pickable signals connected by the can's `_ready()`.

The press handler sets `_pressed = true`. The release handler clears it and calls `_stop_spray()`. The desktop pointer calls the same action methods from mouse events; its input route is separate from the OpenXR bindings.

This is the opening of the can's existing physics update:

```gdscript
func _physics_process(delta: float) -> void:
    if not (is_picked_up() or _desktop_held) or not _pressed:
        _stop_spray(); return
    var pressure := 1.0
    if is_instance_valid(_current_controller):
        pressure = clampf(_current_controller.get_float("trigger"), 0.0, 1.0)
    if pressure <= 0.02:
        _stop_spray(); return
```

Read the condition aloud: the can must be held **and** its action pressed. `return` ends this update when either condition fails. Pressing starts permission to spray; repeated physics updates keep depositing while the conditions hold. Release stops that repetition. Dropping also clears the action.

The tracked trigger's scalar is polled on each update to adjust pressure. Desktop uses `1.0`. Treat this as one additional input value for now; the state sequence remains docked → held → active → held.

**Find a receiver**

Keep spraying and turn the nozzle beside the canvas. Mist and hiss continue, but your marks stop. `is_spraying` describes the open valve; `is_painting` describes a successful canvas sample. Feedback can confirm different parts of an interaction.

The nozzle's world position supplies `origin`; its rotated local negative Z axis supplies the normalized `direction`. `_sample_nozzle()` begins with this ray query:

```gdscript
var query := PhysicsRayQueryParameters3D.create(
    origin, origin + direction * max_distance, 1, [get_rid()])
query.collide_with_areas = true
var collision := get_world_3d().direct_space_state.intersect_ray(query)
```

The endpoint uses the direction-and-distance calculation from Lines. The `1` selects collision layer 1; the exclusion list contains this can's physics identifier. Areas participate because the canvas receiver is an `Area3D`.

The first eligible hit must belong to `drawing_area` and contain a `PaperDrawSurface` with `draw_spray()`. A nearer collider on that layer blocks the canvas. The code then intersects the visible canvas plane, checks its front-facing angle and rejects points beyond its edges or range. Seeing the canvas does not guarantee that this ray reaches it.

**Convert the hit**

The receiver uses `paper_draw_surface.gd` in the same directory. Its `get_uv_from_world_pos()` first removes the surface's world transform, then measures across its rectangular mesh. This reduced equivalent shows the conversion for the supplied `PlaneMesh`:

```gdscript
var local_hit := surface.to_local(world_hit)
var size := (surface.mesh as PlaneMesh).size
var uv := Vector2(
    local_hit.x / size.x + 0.5,
    local_hit.z / size.y + 0.5)
```

Here `surface` is the accepted `PaperDrawSurface` and `world_hit` is the plane intersection. The mesh lies in its own XZ plane, even though it stands upright in the room. Its centre becomes `(0.5, 0.5)`; each coordinate spans zero to one. The four-by-two-and-a-half-metre mesh needs separate width and height. The renderer converts UV into texture pixels without snapping spray input to grid cells.

**Change one boundary**

Change the exported `max_distance` default in `spray_can.gd` from `3.0` to `1.5`, then reload the encounter. Spray from roughly two metres away, then approach within one metre. Predict which attempt leaves paint. Mist and hiss should continue in both; only the closer aim can reach. Restore `3.0` afterward. This changes manual cans' reach without changing their held/action states.

Now cross the automatic painter's line. It calls the same surface method, `draw_spray()`, with a calculated position; your can supplies a ray hit. Both modify one evolving image. Unlike Trace's ordered position list, this canvas does not keep recoverable gestures. Carry that distinction into Color_Walls: a surface can change what an operation becomes.


[Before](before/Color_Paint.md) · [Exact changes](diffs/Color_Paint.diff) · [Current tutorial](../../../../commons/maps/Color_Paint/tutorial.md)
