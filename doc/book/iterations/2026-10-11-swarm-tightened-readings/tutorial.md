# Swarm Intelligence — complete tutorial

Seven halls in the existing spine order. Revised 11 October 2026. The prepared Endless Museum is the setting.

Each lesson carries the same PointBody class and declares what changes in its model. Installed hand controls are described before the reconstruction. The complete printed code and its named dependencies remain intact. All code panels are open for reading and printing.


---

<a id="SwarmIntelligence_PhysarumColony"></a>

## Physarum

# Physarum — a trace outside the point

## Learning elements

- Three local samples: left, ahead, right.
- Steering toward the strongest sample; an explicit tie rule.
- A shared field that outlives a moving point.
- Deposit and retention as opposing parts of feedback.
- A repeated start for a fair comparison.

## Start here in the museum

In the existing Endless Museum, follow a bright connection in **PhysarumColony**. Watch it after the anchor arrangement changes. The dots move on; a trace can remain. The exhibit combines sensing, movement, deposition, diffusion, decay and emitting anchors. Our small study isolates one relation: **a point reads what earlier movement left in the ground, then adds to it**.

We continue with PointBody, the small frozen, grabbable sphere carried through the earlier hand studies. We do not remake its mesh or pickup behaviour. Arrays, loops, local coordinates and separate update phases are already available. Here the new object is the shared trace. It belongs to the field, not to an individual point.

## One point, different models

PointBody keeps its shape and pickup behaviour across these seven halls. Its model changes. Physarum leaves a trace; Flow Fields supplies directions; Boids reads neighbours; ABM adds a carrying state; Ant Colony separates two trails; Particle Swarm remembers scored positions; Population Support records arrivals and losses. These are different sources of information. We will name what is kept and what is replaced, rather than silently accumulate every behaviour in one agent.

At the live colony's drawing surface, take the black point. Hold its action trigger and move it above the surface; a cyan cursor marks where your hand adds trail. Keep the point's centre 8–70 cm above the surface. Release the trigger to stop writing. PAUSE stops the colony while your hand can still draw; resume to watch the agents read the mark. The wall, table and small surface show the same simulation. A dropped point returns after three seconds.

**Lesson focus:** leave a mark, move away, and see another point respond. The continuous brush is a supplied museum control. The complete six-point study below teaches the underlying read–fade–deposit operation with one deposit per trigger press. It has no diffusion or emitting anchors. Rebuild that focused study; use the live colony to compare what those extra mechanisms change.

## Where the code runs

Work in the prepared Ada project, with XR Tools and the museum's player, camera and light already installed. Create a folder for this lesson and put the three scripts below in it. Attach `study.gd` to a new, unscaled Node3D at floor level in a clear museum study bay, facing the visitor along local +Z. Allow a 2.7 m square and an approach to its three buttons. This is a student study beside the existing exhibit. It does not replace the colony.

`point_body.gd` is carried unchanged from the previous hand studies; its complete source appears at the end for reconstruction. The only other supplied component is `res://commons/interactables/push_button.tscn`, the museum's physical button. We instantiate it explicitly and connect its `pressed` signal. There are no unnamed scene objects to find. An empty scene running only this Node3D still needs the Day Zero environment and player to be visible and interactive.

## Keep one record outside the body

The model uses a 16 × 16 field. Each cell holds a number from 0 to 8. The flat array address is `x + y * WIDTH`, returning to Grid. Agent positions are continuous two-dimensional coordinates measured in **cells**; the display turns one cell into 0.16 metres. Increasing field y points along the study's local −Z. Each agent carries a position and heading, with no destination or map of a route.

At each tick, sample 1.5 cells away at left, ahead and right. Turn 45 degrees only when one side is strictly stronger than both other readings. On a tie, keep the heading. Move 0.45 cells, wrapping at the square's edges. This periodic boundary is an explicit simplification; the large exhibit turns agents back near its boundary.

All six agents read the old field. After their moves, multiply every cell by `retention`, then add 1 at each new position, capped at 8. A retention of 0.92 means **keep 92 percent each tick**, not lose 92 percent. Separating reading from writing prevents a later agent from receiving an earlier agent's new deposit during the same tick. We reuse the update discipline from Cellular Automata.

Save as `trail.gd`:

<!-- student-code:trail.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const SENSOR_DISTANCE := 1.5
const TURN := PI / 4.0
var retention := 0.92
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var headings: Array[float] = []
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	values.resize(WIDTH * WIDTH)
	values.fill(0.0)
	positions.assign([Vector2(4,8), Vector2(12,8), Vector2(8,4),
		Vector2(8,12), Vector2(4,4), Vector2(12,12)])
	headings.assign([0.0, PI, PI/2.0, -PI/2.0, PI/4.0, -3.0*PI/4.0])
	steps = 0

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, WIDTH), fposmod(p.y, WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y * WIDTH

func sensor_position(agent: int, offset: float) -> Vector2:
	return wrap_position(positions[agent] + Vector2.from_angle(headings[agent] + offset) * SENSOR_DISTANCE)

func sense(agent: int, offset: float) -> float:
	return values[index_at(sensor_position(agent, offset))]

func deposit(p: Vector2) -> void:
	var cell := index_at(p)
	values[cell] = minf(8.0, values[cell] + 1.0)

func step() -> void:
	# Everyone reads the old field before anyone changes it.
	for i in range(positions.size()):
		var left := sense(i, TURN)
		var ahead := sense(i, 0.0)
		var right := sense(i, -TURN)
		if left > ahead and left > right:
			headings[i] += TURN
		elif right > ahead and right > left:
			headings[i] -= TURN
		# Equal readings keep the current heading.
		positions[i] = wrap_position(positions[i] + Vector2.from_angle(headings[i]) * 0.45)
	for cell in range(values.size()):
		values[cell] *= retention
	for p in positions:
		deposit(p)
	steps += 1
```

`sense()` reads without changing the record. `deposit()` changes one cell. `step()` connects them. The heading update changes this agent's direction, but does not change any field sample another agent can read in that tick. There is no diffusion in this small study, no food and no anchor emission. Ties do not add random wandering. These omissions keep the first comparison legible; they are not claims that the study reproduces the whole exhibit or an organism.

## Let the same points show it

The host creates six instances of the carried point and a tiled display. Tiles show field strength; the cyan, white and pink marks show **point 0's** sensor positions. Its three readings appear above the table. The point remains a kinematic teaching object: this is a rule for its position, not a physical force simulation.

The simulation advances one model tick every 0.15 seconds. Holding any point pauses the whole model, so you can examine a sample. Move a point over the table and press its trigger to deposit a mark. Release it to return to the plane and continue. Motion alone while held does not paint. A placement beyond an edge wraps into the periodic field. The three nearby buttons run/pause, switch retention and reset; desktop keys are **1**, **2** and **R**. The usual desktop point interaction remains supplied by the museum.

Save as `study.gd`:

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Trail = preload("trail.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
const TICK := 0.15
var trail = Trail.new()
var points: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x - 8.0) * CELL, HEIGHT, -(p.y - 8.0) * CELL)

func record(p: Vector3) -> Vector2:
	return trail.wrap_position(Vector2(p.x / CELL + 8.0, -p.z / CELL + 8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 26) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := tile(Vector3(2.7,0.08,2.7), Color("242832"))
	base.position.y = HEIGHT - 0.13
	for y in range(Trail.WIDTH):
		for x in range(Trail.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94), Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5)) - Vector3.UP*0.075
			tiles.append(cell)
	for i in range(trail.positions.size()):
		var point = PointBody.new()
		add_child(point)
		point.action_pressed.connect(func(_source): stamp(i))
		points.append(point)
	for colour in [Color("67c8df"), Color("ffffff"), Color("dc92ae")]:
		sensors.append(tile(Vector3(0.04,0.02,0.04), colour))
	caption = label("", Vector3(0,1.9,-1.35), 30)
	label("TRACE OUTSIDE THE POINT", Vector3(0,2.3,-1.35), 34)
	label("L / cyan      F / white      R / pink", Vector3(0,1.58,-1.35))
	var actions := [toggle_play, change_retention, restart]
	var words := ["RUN / PAUSE", "RETENTION", "RESET"]
	for i in range(3):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run", "Retention", "Reset"][i]
		button.position = Vector3((i-1)*0.65,0.85,1.6)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(words[i], button.position+Vector3(0,0.17,0), 22)
	paint()

func stamp(i: int) -> void:
	trail.positions[i] = record(to_local(points[i].global_position))
	trail.deposit(trail.positions[i])
	paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_retention() -> void:
	trail.retention = 0.55 if trail.retention > 0.8 else 0.92
	restart()

func restart() -> void:
	trail.reset()
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			trail.positions[i] = record(to_local(points[i].global_position))
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed >= TICK:
			trail.step()
			elapsed -= TICK
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"), trail.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held():
			points[i].position = place(trail.positions[i])
	var offsets := [Trail.TURN, 0.0, -Trail.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(trail.sensor_position(0,offsets[i])) - Vector3.UP*0.03
	caption.text = "Point 0: L %.2f   F %.2f   R %.2f\nTick %d  /  keep %.0f%%  /  %s" % [
		trail.sense(0,Trail.TURN), trail.sense(0,0), trail.sense(0,-Trail.TURN),
		trail.steps, trail.retention*100.0, "RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_retention()
		elif event.keycode == KEY_R: restart()
```

`place()` and `record()` translate between the model's cell coordinates and the study's local metre coordinates. `to_local()` matters when a held point is parented to the controller. A translated or rotated study therefore still records the same local position. Keep its scale at one.

The retention button resets the field and all agent positions to the same start while keeping the chosen retention. It preserves whether the simulation was running. Compare at the same tick count. A frame stall is capped at half a second to avoid a long catch-up; this display is not a wall-clock scientific simulation.

## Reconstruct the carried point

This is the existing `point_body.gd`, included in full so the dependency is available. Its sphere, material and frozen release are unchanged. The study attaches new behaviour to its `action_pressed` signal.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## Make a prediction that can fail

Pause, then Reset to clear earlier marks. Follow point 0's three small sensor marks. Pick up another point, put it over the cyan mark and trigger once; move that point away without triggering again. The left reading should still be 1: the mark belongs to the field. Release and run. Point 0 should turn toward that mark on the next tick. Pause and Reset again before depositing at the pink mark to compare the opposite turn from the same empty field. Equal left and right readings leave its heading unchanged.

Then reset and run to tick 40 with retention 0.92. Reset again at 0.55 and compare at tick 40. These are the same initial points, not two unrelated random samples. The lower retention weakens an unvisited mark sooner; once choices diverge, you should not expect the two final trajectories to match.

For an independent change, move one starting position in `reset()`. Predict which three cells it will sample first. Check those cell values, rather than judging the picture alone. You should be able to explain how an agent responds to an absent neighbour's trace without sending that neighbour a message.

## Return to the exhibit

Follow one bright connection in PhysarumColony after its anchors change. Identify a trace that remains after the dots have moved away. That persistence is the relation you rebuilt. The exhibit also spreads traces and emits them from anchors; our study does neither. Use the small model to explain how a mark can outlast a point, without treating its exact routes or timing as a prediction of the larger colony.

## Carry onward

Keep the same point, its position and the field lookup. In FlowFields we will supply **directions** at field addresses. The agents will read that field without writing it. Similar collective movement can therefore have a different cause.

The model is a small teaching reduction of sensor–motor trail feedback, informed by Jeff Jones's [research on simple agents and emergent transport networks](https://arxiv.org/abs/1503.06579). It does not demonstrate a shortest-path guarantee. [The Nature of Code's autonomous agents](https://natureofcode.com/autonomous-agents/) is a useful companion for the later transition from a carried moving body to steering and flocking.


---

<a id="SwarmIntelligence_FlowFields"></a>

## Flow Fields

# FlowFields — directions already here

## Learning elements

- A vector stored at a grid address.
- Desired velocity and current velocity.
- A bounded steering acceleration.
- Reading a field without writing into it.
- Zero direction as an explicit behaviour choice.

## Start here in the museum

In the Endless Museum, find a moving body in **FlowFieldMain** and read the nearby direction mark. Predict its turn. The exhibit moves through route fields, wind and noise. Its live table contains the existing simulation; the small study below gives us a few points whose changes we can inspect.

Bring `point_body.gd` from Physarum unchanged. Bring the flat grid address and the conversion between cells and local metres. Replace the scalar trace with a **direction vector**. The point now carries velocity instead of a heading. It reads one cell, adjusts its movement and leaves that cell unchanged. No neighbour has to send it a message.

Take the black point at the live table's front-right dock. In DRAW mode, hold its action trigger and move it 8–65 cm above the small surface. Your movement writes a direction: gold arrows mark edited cells, cyan arrows retain the starting direction. Staying still writes nothing. Release the trigger and the directions remain. Dropping the point returns it after three seconds.

The nearby controls pause the agents, reset directions, or switch TOUR / DRAW. RESET DIRECTIONS restores a rightward field while keeping the bodies; returning from TOUR to DRAW clears your edits. Pause, draw a turn, then resume and follow one agent across it. **Lesson focus:** you supply a direction that passing agents read without changing. The complete study below isolates this relation with six points and single-cell trigger edits. The walk-in crowd and ant displays are further comparisons.

## Where the code runs

Continue in the prepared Ada project. The museum supplies the player, camera, light and installed XR Tools. Put `field.gd`, `study.gd` and the carried `point_body.gd` in one folder. Attach `study.gd` to a new unscaled Node3D at floor level in a clear study bay, facing the visitor along local +Z. Allow 2.7 metres square and an approach to the buttons. The complete carried file appears below for reconstruction; there is no new sphere or pickup lesson here.

The host also instantiates the supplied `res://commons/interactables/push_button.tscn` and connects its `pressed` signal. Everything else is created in these scripts. An empty project without that prepared environment is not the context of this lesson.

## A direction is not yet a movement

The 16 × 16 array stores `Vector2` values. The address remains `x + y * WIDTH`. Most cells contain `(1,0)`, pointing along local +X. The central patch contains `(0,1)`, pointing along local −Z. The display conversion is the same as Physarum: one cell is 0.16 metres; increasing model y goes away from the front of the table.

Normalise the sampled vector and multiply by `SPEED` to get the **desired velocity**, in cells per second. Subtract the point's current velocity. A point already moving as requested has no correction to make. One moving across the requested direction needs to turn.

Divide that difference by `RESPONSE`, measured in seconds, to get an acceleration in cells per second squared. Limit its magnitude to `MAX_ACCEL`. Each 0.05-second step adds acceleration × time to velocity, then velocity × time to position. This is our familiar velocity integration from Forces, now directed by a sampled field. It is a kinematic steering model, not a mass-dependent rigid-body force.

Save as `field.gd`:

<!-- student-code:field.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const DT := 0.05
var vectors := PackedVector2Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var patch_mode := 0
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	vectors.resize(WIDTH * WIDTH)
	vectors.fill(Vector2.RIGHT)
	positions.assign([Vector2(4,8), Vector2(12,8), Vector2(8,4),
		Vector2(8,12), Vector2(4,4), Vector2(12,12)])
	velocities.resize(positions.size())
	velocities.fill(Vector2.ZERO)
	patch_mode = 0
	steps = 0
	set_patch()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, WIDTH), fposmod(p.y, WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y * WIDTH

func sample(p: Vector2) -> Vector2:
	return vectors[index_at(p)]

func set_patch() -> void:
	var directions := [Vector2(0,1), Vector2.ZERO, Vector2.RIGHT]
	for y in range(4,12):
		for x in range(8,12):
			vectors[x + y * WIDTH] = directions[patch_mode]

func edit_cell(p: Vector2) -> void:
	var address := index_at(p)
	var old := vectors[address]
	vectors[address] = Vector2(0,1) if old == Vector2.RIGHT else (
		Vector2.ZERO if old == Vector2(0,1) else Vector2.RIGHT)

func desired_at(p: Vector2) -> Vector2:
	return sample(p).normalized() * SPEED

func acceleration(i: int) -> Vector2:
	return ((desired_at(positions[i]) - velocities[i]) / RESPONSE).limit_length(MAX_ACCEL)

func step() -> void:
	# The field is read-only during motion. Nobody deposits a trace.
	for i in range(positions.size()):
		velocities[i] = (velocities[i] + acceleration(i) * DT).limit_length(SPEED)
		positions[i] = wrap_position(positions[i] + velocities[i] * DT)
	steps += 1
```

Read `acceleration()` and `step()` first. The other functions prepare the field, convert an address or support an edit. `set_patch()` changes only the central rectangle. `edit_cell()` changes only one address. **Neither is called by the moving agents.** Movement cannot deposit, erase or learn a field.

For the default point 0, the first desired velocity is `(3,0)` and the current velocity is `(0,0)`. Their difference divided by 0.5 is `(6,0)`. After one 0.05-second step, velocity is `(0.3,0)` and position moves 0.015 cells. It approaches the requested speed over successive steps; it does not jump to it. On entering the turning patch, some eastward velocity remains while the northward component grows.

A zero vector produces zero desired velocity. Subtracting a nonzero current velocity then produces **braking**, limited in the same way. Zero does not mean “continue unchanged” in this model. The larger exhibit instead adds random wandering at zero vectors. Both are programmed decisions; an empty direction alone does not decide what a body should do.

We keep Physarum's periodic boundary: leaving one edge returns at the opposite edge. These edge crossings are wraps, not physical turns. The production exhibit uses a return rule near its boundary. We also omit collision avoidance, obstacle costs and route construction. Shared directions are the subject here; BFS, Dijkstra and A-star belong to Graph Theory later in the museum.

## Let the carried points show the difference

Six instances of the same PointBody move above the field. Point 0 is pink so you can follow its readout. The arrows are thin cylinders with cone tips. Dark cells without an arrow contain zero. Nothing is hidden behind a scene reference to a mesh.

**Run/pause** starts or stops the model. **Turn / stop / east** cycles the central patch through `(0,1)`, `(0,0)` and `(1,0)` without resetting positions or velocities. **Reset** restores the initial field, positions and zero velocities, clears all hand edits and pauses. Desktop keys are **1**, **2** and **R**.

Hold any point to pause the whole model. Move it to an address and press the trigger to cycle that cell from east to north to zero to east. This is **your edit to the supplied field**, not an agent leaving a trail. Release the point to return it to the field plane. A held point's velocity is cleared; the other velocities are retained. If the model was running, it resumes when all points are released. The first cell it reads is the one you chose.

Save as `study.gd`:

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
var field = Field.new()
var points: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var arrows: Array[Node3D] = []
var caption: Label3D
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL, HEIGHT, -(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return field.wrap_position(Vector2(p.x/CELL+8.0, -p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func arrow(at: Vector3) -> Node3D:
	var body := Node3D.new()
	add_child(body)
	body.position = at
	for tip in [false,true]:
		var visual := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.height = 0.03 if tip else 0.08
		mesh.bottom_radius = 0.02 if tip else 0.006
		mesh.top_radius = 0.0 if tip else 0.006
		mesh.radial_segments = 8
		visual.mesh = mesh
		visual.material_override = finish(Color("c5e5e9"))
		visual.position.y = 0.055 if tip else 0.0
		body.add_child(visual)
	return body

func label(words: String, at: Vector3, size: int = 26) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := tile(Vector3(2.7,0.08,2.7), Color("242832"))
	base.position.y = HEIGHT-0.13
	for y in range(Field.WIDTH):
		for x in range(Field.WIDTH):
			var at := place(Vector2(x+0.5,y+0.5)) - Vector3.UP*0.075
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94), Color("283c46"))
			cell.position = at
			tiles.append(cell)
			arrows.append(arrow(at+Vector3.UP*0.025))
	for i in range(field.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): edit_under(i))
		points.append(point)
	caption = label("", Vector3(0,1.9,-1.35), 28)
	label("DIRECTIONS ALREADY HERE", Vector3(0,2.3,-1.35), 34)
	label("Pink: point 0 / arrows: supplied direction", Vector3(0,1.55,-1.35), 22)
	var actions := [toggle_play, change_patch, restart]
	var words := ["RUN / PAUSE", "TURN / STOP / EAST", "RESET"]
	for i in range(3):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run", "Patch", "Reset"][i]
		button.position = Vector3((i-1)*0.8,0.85,1.6)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(words[i],button.position+Vector3(0,0.17,0),18)
	paint()

func edit_under(i: int) -> void:
	if not points[i].held(): return
	field.positions[i] = record(to_local(points[i].global_position))
	field.edit_cell(field.positions[i])
	paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_patch() -> void:
	field.patch_mode = (field.patch_mode+1) % 3
	field.set_patch()
	paint()

func restart() -> void:
	field.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			field.positions[i] = record(to_local(points[i].global_position))
			field.velocities[i] = Vector2.ZERO
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Field.DT:
			field.step()
			elapsed = maxf(0.0,elapsed-Field.DT)
	paint()

func paint() -> void:
	for i in range(arrows.size()):
		var v:Vector2 = field.vectors[i]
		arrows[i].visible = not v.is_zero_approx()
		if arrows[i].visible:
			arrows[i].quaternion = Quaternion(Vector3.UP,Vector3(v.x,0,-v.y).normalized())
		tiles[i].material_override.albedo_color = Color("404048") if v.is_zero_approx() else (
			Color("416977") if v.y > 0 else Color("283c46"))
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(field.positions[i])
	var d:Vector2 = field.desired_at(field.positions[0])
	var v:Vector2 = field.velocities[0]
	var address:int = field.index_at(field.positions[0])
	caption.text = "Point 0 / cell %d\nDesired (%.1f, %.1f) / velocity (%.1f, %.1f) cells/s\nTick %d / %s" % [
		address,d.x,d.y,v.x,v.y,field.steps,"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_patch()
		elif event.keycode == KEY_R: restart()
```

`to_local()` records the held point correctly when XRTools temporarily parents it to the controller. The model remains in cell coordinates even if the study is moved or rotated in the museum. Keep the study's scale at one. Frame time is accumulated into fixed model steps; very long frames contribute at most half a second, so this display does not promise exact wall-clock timing after a stall.

The display helpers build the same sort of table, labels and controls as the previous study. The new visual work is the direction at each address and the paired readout: **what this position requests / what the point is doing**.

## The carried file

This is `point_body.gd`, unchanged from Physarum. Its existing signal now calls `edit_under()` instead of depositing a scalar trace. Its mesh and grab behaviour remain the same.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## Check what you have learned

Reset and follow the pink point. Before it enters the turning patch, predict which velocity component will decrease and which will increase. Read the numbers at the boundary. The turn takes time because velocity has a previous value and the correction is bounded.

Run again with the patch set to stop. A point entering it should slow down, not choose a random escape direction. For a clean comparison, reset before each run and change the patch while paused. The same start lets you distinguish a changed field from a changed starting position.

Hold a point over an eastward cell and trigger once. Release it, then put another point there. Both should read the new northward direction. The first visitor did not consume it. Let the simulation run: the arrows themselves should stay unchanged.

For an independent edit, change the patch's first direction in `set_patch()` from `(0,1)` to `(0,-1)`. Predict the initial acceleration of a point at rest in that patch. Run it and check the sign of its y velocity. Reversing the field should reverse the requested turn without rebuilding the point.

## Return to the exhibit

In the live FlowFieldMain table, watch two bodies cross the same direction mark during one scenario. Separate the direction they read from the turns their existing velocities permit. Their passage does not deposit a trail; the exhibit's scenario supplies the field. Its zero-direction wandering also differs from our study's braking. Explain that difference before comparing their paths.

## Carry onward

Keep PointBody, its velocity, and desired-minus-current steering. Boids will construct the desired movement from **nearby moving points**. The steering operation can stay while its source changes.

The [autonomous agents chapter of The Nature of Code](https://natureofcode.com/autonomous-agents/) provides a companion account of flow-field steering. Our response time, acceleration cap, zero-vector braking and periodic boundary are explicit choices for this museum study.


---

<a id="SwarmIntelligence_Boids_Algorithm"></a>

## Boids

# Boids — who is near?

## Learning elements

- Select neighbours by distance; exclude yourself.
- Calculate separation, alignment and cohesion.
- Weight and combine steering requests.
- Read one snapshot; commit the next state together.
- Distinguish no request from a request to stop.

## Start here in the museum

Begin at the flocking table with the black hand point and coloured arrows. Pick up the point on the left. Move it left to narrow the perception radius or right to widen it. The gold circles and links show which bodies enter the first boid's neighbourhood. Press the held trigger, or the nearby right button, to pause. Keep the bodies still and change the radius: the neighbours can change without anyone moving.

The hand point controls radius; it is not a member of this flock. Dropping it returns it after 1.5 seconds, keeping the radius and playback state. The original sliders remain available. RESET makes a fresh random scatter.

**Lesson focus:** choose who contributes, then inspect the resulting requests. The aquarium, balcony flock, fish and drone displays are comparisons. Bring PointBody and bounded steering from FlowFields. Replace the supplied direction grid with observations of nearby points.

## Reconstruct the small study

Save `flock.gd`, `study.gd` and the unchanged `point_body.gd` together. Attach `study.gd` to an unscaled Node3D at floor level in a clear 2.7 m square study bay, with access from local +Z. The prepared museum supplies player, camera, lights, XRTools and `res://commons/interactables/push_button.tscn`. These three scripts create the study's six points and display.

The installed table keeps its original thirty-body, sequential, frame-driven model. Its hand control changes that model's radius. Our reconstruction uses six points, fixed steps and one shared snapshot. Here you pick up an actual study point to change its position. These two experiments expose the same neighbourhood question through different controls and declared update rules.

## Choose who counts

`neighbours(i)` returns other point indices less than `radius` cells away. At radius 3.5, point 0 sees points 1 and 2. It excludes itself. The sixteen-cell plane and scale of 0.16 metres per cell return from FlowFields; movement stays on local XZ.

Positions wrap at the edges, but neighbour distances are measured directly across the drawn plane. Two points beside opposite edges may be excluded from each other's calculation. Periodic movement does not automatically create periodic neighbourhoods.

## Three requests

**Separation:** within two cells, sum offsets pointing away, divided by squared distance. Closer neighbours contribute more. Normalise the sum and multiply by `SPEED`. Exact overlap has no away direction, so skip that division; separation does not guarantee collision avoidance.

**Alignment:** average neighbour velocities. Use the actual average as desired velocity, retaining its speed. A zero average requests braking.

**Cohesion:** average offsets to neighbours, then normalise and multiply by `SPEED`. This points towards their local centre. A zero offset contributes no request.

Each uses FlowFields' `(desired - current) / RESPONSE`, capped at `MAX_ACCEL`. Weight the requests, add them and cap again. Separation starts at 1.5; alignment and cohesion at 1. Coloured arrows show weighted requests; white shows the capped combination. Requests can cancel, and a cap can conceal further increases in a weight.

No neighbours means zero acceleration: coast. An alignment average of zero means brake. Keep that distinction from FlowFields' explicit stop direction.

Save `flock.gd`:

<!-- student-code:flock.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const DT := 0.05
const CLOSE := 2.0
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var radius := 3.5
var weights := Vector3(1.5, 1.0, 1.0)
var mode := 0 # Separation, alignment, cohesion, all three.
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	positions.assign([Vector2(6,8), Vector2(7,8), Vector2(8,9),
		Vector2(11,7), Vector2(4,12), Vector2(12,12)])
	velocities.assign([Vector2(1,0), Vector2(0,2), Vector2(0,2),
		Vector2(-2,0), Vector2(1,-1), Vector2(-1,-1)])
	steps = 0

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH), fposmod(p.y,WIDTH))

func neighbours(i: int) -> Array[int]:
	var found: Array[int] = []
	for j in range(positions.size()):
		if j != i and positions[i].distance_to(positions[j]) < radius:
			found.append(j)
	return found

func steer_to(desired: Vector2, i: int) -> Vector2:
	return ((desired - velocities[i]) / RESPONSE).limit_length(MAX_ACCEL)

func requests(i: int) -> Array[Vector2]:
	var result: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var nearby := neighbours(i)
	if nearby.is_empty(): return result
	var away := Vector2.ZERO
	var velocity_sum := Vector2.ZERO
	var offset_sum := Vector2.ZERO
	for j in nearby:
		var offset := positions[j] - positions[i]
		var d2 := offset.length_squared()
		if d2 > 0.000001 and d2 < CLOSE*CLOSE:
			away -= offset / d2
		velocity_sum += velocities[j]
		offset_sum += offset
	if not away.is_zero_approx():
		result[0] = steer_to(away.normalized()*SPEED, i)
	result[1] = steer_to(velocity_sum/nearby.size(), i)
	var centre_offset := offset_sum/nearby.size()
	if not centre_offset.is_zero_approx():
		result[2] = steer_to(centre_offset.normalized()*SPEED, i)
	return result

func acceleration(i: int) -> Vector2:
	var parts := requests(i)
	var total := Vector2.ZERO
	for rule in range(3):
		if mode == 3 or mode == rule:
			total += parts[rule]*weights[rule]
	return total.limit_length(MAX_ACCEL)

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		var v := (velocities[i] + acceleration(i)*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i] + v*DT))
	positions = next_positions
	velocities = next_velocities
	steps += 1
```

Initially point 0 moves at `(1,0)`. Point 1 is one cell to its right; point 2 is outside separation distance but inside the wider neighbourhood. Separation alone produces a capped acceleration of `(-6,0)`. One step leaves velocity `(0.7,0)`: still rightward, but slowing. A left-pointing correction does not instantly reverse movement.

Both neighbours move at `(0,2)`, so alignment produces `(-2,4)`. Cohesion uses their average offset `(1.5,0.5)`. These requests use different observations.

## Read one moment

`step()` fills next-position and next-velocity arrays before replacing the old state. This returns to Cellular Automata's old/next discipline. No later point reads an earlier point's future. Reversing list order should preserve the physical result apart from rounding.

The installed table and aquarium use other update and boundary choices. This small reconstruction teaches the three-rule relation; its exact trajectories do not predict those exhibits. Its steering is kinematic, not a rigid-body force.

## Move the same points

The study starts paused on separation. RUN advances fixed 0.05-second steps. NEXT RULE cycles separation → alignment → cohesion → all. RADIUS switches 2 / 3.5 cells. RESET BODIES restores positions, velocities and tick, pauses, and keeps the selected rule, radius and weights. Desktop keys are **1**, **2**, **3** and **R**.

Hold any study point to pause all six. Move it across the gold radius and trigger to select it. Release projects it onto the plane and clears its velocity; other velocities remain. Running resumes if it was active. Release all points before resetting. Cyan rings identify neighbours; red, blue and green arrows show the next requests. Their scale is 0.07 metres per cell/s², not a predicted travel distance.

Save `study.gd`:

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Flock = preload("flock.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
const NAMES := ["SEPARATION", "ALIGNMENT", "COHESION", "ALL THREE"]
var flock = Flock.new()
var points: Array[Node3D] = []
var halos: Array[MeshInstance3D] = []
var arrows: Array[Node3D] = []
var radius_ring: MeshInstance3D
var caption: Label3D
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL, HEIGHT, -(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return flock.wrap_position(Vector2(p.x/CELL+8.0, -p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func visual(mesh: Mesh, colour: Color, parent: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = finish(colour)
	parent.add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.005
	mesh.outer_radius = radius+0.005
	mesh.rings = 48
	mesh.ring_segments = 6
	return visual(mesh,colour,self)

func arrow(colour: Color) -> Node3D:
	var body := Node3D.new()
	add_child(body)
	for tip in [false,true]:
		var mesh := CylinderMesh.new()
		mesh.height = 0.03 if tip else 0.1
		mesh.bottom_radius = 0.025 if tip else 0.007
		mesh.top_radius = 0.0 if tip else 0.007
		mesh.radial_segments = 8
		visual(mesh,colour,body)
	return body

func show_arrow(body: Node3D, vector: Vector2, at: Vector3) -> void:
	body.visible = not vector.is_zero_approx()
	if not body.visible: return
	var length := vector.length()*0.07
	body.position = at
	body.quaternion = Quaternion(Vector3.UP,Vector3(vector.x,0,-vector.y).normalized())
	body.get_child(0).mesh.height = length
	body.get_child(0).position.y = length*0.5
	body.get_child(1).position.y = length+0.015

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := BoxMesh.new()
	base.size = Vector3(2.7,0.08,2.7)
	visual(base,Color("747c84"),self).position.y = HEIGHT-0.13
	for i in range(flock.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		halos.append(ring(0.10,Color("a0e8ec")))
	radius_ring = ring(flock.radius*CELL,Color("f5ce60"))
	for colour in ["fa6262","679cfa","59d996","ffffff"]:
		arrows.append(arrow(Color(colour)))
	label("WHO IS NEAR?",Vector3(0,2.28,-1.3),36)
	caption = label("",Vector3(0,1.90,-1.3),24)
	label("Red: separate / blue: align / green: gather\nWhite: combined acceleration (0.07 m per cell/s²)",Vector3(0,1.51,-1.3),19)
	var actions := [toggle_play, change_rule, change_radius, restart]
	for i in range(4):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run","Rule","Radius","Reset"][i]
		button.position = Vector3((i-1.5)*0.72,0.85,1.60)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(["RUN / PAUSE","NEXT RULE","RADIUS 2 / 3.5","RESET BODIES"][i],button.position+Vector3(0,0.17,0),16)
	paint()

func choose(i: int) -> void:
	if points[i].held():
		witness = i
		paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_rule() -> void:
	flock.mode = (flock.mode+1)%4
	paint()

func change_radius() -> void:
	flock.radius = 2.0 if flock.radius > 2.0 else 3.5
	paint()

func restart() -> void:
	flock.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			flock.positions[i] = record(to_local(points[i].global_position))
			flock.velocities[i] = Vector2.ZERO
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Flock.DT:
			flock.step()
			elapsed = maxf(0.0,elapsed-Flock.DT)
	paint()

func paint() -> void:
	var nearby: Array[int] = flock.neighbours(witness)
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(flock.positions[i])
		halos[i].position = place(flock.positions[i])-Vector3.UP*0.08
		halos[i].visible = i in nearby
	var at := place(flock.positions[witness])
	radius_ring.position = at-Vector3.UP*0.065
	radius_ring.mesh.inner_radius = flock.radius*CELL-0.005
	radius_ring.mesh.outer_radius = flock.radius*CELL+0.005
	var parts: Array[Vector2] = flock.requests(witness)
	for rule in range(3):
		var active: bool = flock.mode == 3 or flock.mode == rule
		show_arrow(arrows[rule],parts[rule]*flock.weights[rule] if active else Vector2.ZERO,at+Vector3.UP*(0.14+rule*0.04))
	show_arrow(arrows[3],flock.acceleration(witness),at+Vector3.UP*0.30)
	var a: Vector2 = flock.acceleration(witness)
	var v: Vector2 = flock.velocities[witness]
	caption.text = "%s / point %d / neighbours %s\nRadius %.1f cells / v (%.2f, %.2f) cells/s\na (%.2f, %.2f) cells/s² / tick %d / %s" % [
		NAMES[flock.mode],witness,str(nearby),flock.radius,v.x,v.y,a.x,a.y,flock.steps,"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_rule()
		elif event.keycode == KEY_3: change_radius()
		elif event.keycode == KEY_R: restart()
```

`record(to_local(...))` keeps coordinates in the study's frame while XRTools holds the sphere under a controller. Leave the root unscaled. The host caps stalled-frame catch-up at half a second. Circles and arrows are explanatory meshes.

## The carried body

Keep your `point_body.gd` from FlowFields. This complete copy is unchanged; the new work belongs to the relation between bodies.

<details><summary>point_body.gd — complete carried file</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

## Predict, then check

For exact one-step tests, instantiate `flock.gd` in your test script, set `mode` and call `step()`. Modes 0, 1 and 2 select separation, alignment and cohesion. Start with a fresh instance for each comparison; the study's RUN button advances continuously.

1. Separation: predict velocity `(0.7,0)` after one step. Explain why movement has not reversed.
2. Alignment: predict `(0.9,0.2)`. Independently halve its weight to 0.5 and predict `(0.95,0.1)`. Execute both.
3. Change radius from 3.5 to 2 while paused. Point 0 loses point 2. Separation initially stays the same; the local centre changes. Move another point inside and check the neighbour list.
4. Compare a moving point alone with one beside stationary neighbours in alignment mode. One coasts; the other slows. Explain which input requests braking.

The printed-code checks also cover reversed list order, coincident points and deliberately broken variants. They test this implementation; learner experience and physical headset use need their own assessment.

## Return and carry onward

At the installed table, pause and use the hand point to change radius. Its gold links show the selected neighbours; its arrows preview the first body's next requests. Their lengths are compressed to fit, so read the magnitude labels for exact comparisons. Then observe the open flock from the balcony: its numerical boundary extends beyond the architecture.

Keep PointBody, bounded steering and the shared-snapshot discipline. **The next study sets the three flocking requests aside.** ABM returns to Physarum's trace and adds a searching/carrying state. Boids already is an agent-based model; the new lesson is a state that changes which information the body uses.

The three-behaviour lineage comes from Craig Reynolds's [Boids work](https://www.red3d.com/cwr/boids/). Each implementation makes its own choices about weights, updates and edges.


---

<a id="SwarmIntelligence_Agent_Based_Modeling_ABM"></a>

## Agent-Based Modelling

# What the point carries

## Learning elements

- Agent state: searching or carrying food
- Contact as a state transition
- A different response from the same body
- Shared trail versus individual state
- Replacing agents versus clearing the whole model

## Start in the existing hall

Begin at the six-point study table on the right near the entrance. Hold a sphere to pause all six; press its trigger to select it. Move it into FOOD, release it and press ONE TICK on the nearby rail. A green cube appears: the same point now carries food. Move it to HOME and step again. The cube disappears and the delivery count rises once.

**Lesson focus:** a stored state changes which information the point uses. The four nearby controls are RUN / PAUSE, ONE TICK, REPLACE AGENTS and CLEAR ALL. The installed table runs the complete lesson printed below. The larger colony, listening court and navigator are comparisons; return to them after testing the two state transitions.

Continue with the **same PointBody from Boids**. Keep its appearance, pickup and trigger. Bring back Physarum's three samples and one shared trace. Boids taught us to read the old state before committing the next; keep that discipline here. Boids already was an agent-based model. This lesson adds a discrete state that selects a different behaviour.

The small reconstruction isolates that operation. The existing colony also has finite food, random wandering, food quality and recruitment. We leave those mechanisms in the exhibit. Here food is inexhaustible, all points know the nest position, and they can detect food only inside its contact ring. This is a controlled study of transitions, not a reproduction of every colony feature.

## What changes at contact?

`carrying[i]` belongs to point `i`. It is a Boolean: `false` while searching, `true` while returning. A small green cube above the sphere makes that state visible. Colour alone does not carry the distinction.

| State before the tick | Observation | State and action on this tick |
| --- | --- | --- |
| Searching | Outside food ring | Read three old trail samples; steer towards the strongest, keeping direction on ties. |
| Searching | Inside food ring | Carry food; request a return towards the known nest; leave a trace. |
| Returning | Outside home ring | Keep returning and depositing; ignore trail samples. |
| Returning | Inside home ring | Deliver once; stop carrying; request an eastward departure; stop depositing. |

Contact is a distance **strictly below one cell**, checked at the start of the tick. Movement follows; arriving during that movement is noticed next tick. The rings show that threshold. This is model contact, not a Godot rigid-body collision. These points can overlap.

The return changes the desired velocity, not the current velocity instantly. We keep the familiar response time and acceleration cap. A point moving right can carry food and still move right briefly while it turns. After delivery the one-tick eastward request starts another search; subsequent ticks read the trail again.

## The complete model

Save these three files together. The scene belongs under an empty Node3D in your prepared museum working area. Day Zero supplies the player, camera, lighting, XRTools and the named `push_button.tscn` control. No prebuilt sphere, mesh path or hidden scene node is required. Attach `study.gd` to that Node3D; it creates its own display. The supplied `study.tscn` does the same.

Save **foragers.gd**. Positions and velocities retain the familiar sixteen-cell plane and fixed 0.05-second tick. `next_carrying` joins the next-position and next-velocity arrays. Every search reads the old shared field. Only after all bodies have chosen do we fade the field and add deposits from returning points.

<!-- student-code:foragers.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI / 4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.92
var return_speed := 3.0
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.assign([Vector2(3,7.4), Vector2(4.2,7.4), Vector2(5.4,7.4),
		Vector2(3,8.6), Vector2(4.2,8.6), Vector2(5.4,8.6)])
	velocities.clear()
	carrying.clear()
	for i in range(positions.size()):
		velocities.append(Vector2(SPEED,0))
		carrying.append(false)

func reset() -> void:
	values.resize(WIDTH*WIDTH)
	values.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y*WIDTH

func sensor_position(i: int, offset: float) -> Vector2:
	var heading := velocities[i].angle() if not velocities[i].is_zero_approx() else 0.0
	return wrap_position(positions[i] + Vector2.from_angle(heading+offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float) -> float:
	return values[index_at(sensor_position(i,offset))]

func search_velocity(i: int) -> Vector2:
	var direction := velocities[i].normalized() if not velocities[i].is_zero_approx() else Vector2.RIGHT
	var left := sense(i,TURN)
	var ahead := sense(i,0.0)
	var right := sense(i,-TURN)
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	var next_carrying: Array[bool] = []
	for i in range(positions.size()):
		var has_food := carrying[i]
		var arrived_home := has_food and positions[i].distance_to(HOME) < CONTACT
		if arrived_home:
			has_food = false
			delivered += 1
		elif not has_food and positions[i].distance_to(FOOD) < CONTACT:
			has_food = true
		var desired: Vector2
		if has_food:
			desired = (HOME-positions[i]).normalized()*return_speed
		elif arrived_home:
			desired = Vector2(SPEED,0)
		else:
			desired = search_velocity(i)
		var a := ((desired-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
		next_carrying.append(has_food)
	positions = next_positions
	velocities = next_velocities
	carrying = next_carrying
	for cell in range(values.size()):
		values[cell] *= retention
	for i in range(positions.size()):
		if carrying[i]:
			var cell := index_at(positions[i])
			values[cell] = minf(8.0,values[cell]+1.0)
	steps += 1
```

`replace_agents()` restores the six starting records but does not touch `values`, `delivered` or `steps`. `reset()` clears those three shared records too, then restores the agents. Neither operation changes the selected retention or return speed. Reusing the six rendered spheres is an implementation convenience; “replace” here means replace their simulated records.

The field stores one scalar per cell. A returning point adds one unit, capped at eight; each tick retains 92% of the previous amount. Searching points read it but do not deposit. A mark carries no identity or direction. A brighter route is not proof of a shorter or better route.

### The same point

This is the unchanged PointBody from Boids. Keep your existing file or use this identical copy.

<details>
<summary>point_body.gd — carried in full</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

### The display and controls

Save **study.gd**. The host maps one cell to 0.16 metres on the same XZ plane. The grid shows the shared trace; the cube follows its point's carry flag. Hold any point to pause the entire model and relocate it. Its velocity is cleared; its carry flag stays. Use the held trigger to inspect that point. Release it, then press ONE TICK to test contact. Holding does not pick up model food: a simulation tick does.

The three small samples are visible only while the selected point searches: cyan left, white ahead, pink right. The readout still reports their values during return, but the returning point ignores them.

<details>
<summary>study.gd — complete museum host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Foragers = preload("foragers.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
var model = Foragers.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	body.material_override = material
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func destination(p: Vector2, colour: Color, words: String) -> void:
	var body := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = Foragers.CONTACT*CELL-0.005
	ring.outer_radius = Foragers.CONTACT*CELL+0.005
	ring.rings = 48
	ring.ring_segments = 6
	body.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	body.material_override = material
	add_child(body)
	body.position = place(p)-Vector3.UP*0.06
	label(words,place(p)+Vector3(0,0.30,-0.22),20)

func _ready() -> void:
	tile(Vector3(2.7,0.08,2.7),Color("242832")).position.y = HEIGHT-0.13
	for y in range(Foragers.WIDTH):
		for x in range(Foragers.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94),Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5))-Vector3.UP*0.075
			tiles.append(cell)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.06,Color("a0ef82")))
	for colour in ["67c8df","ffffff","dc92ae"]:
		sensors.append(tile(Vector3(0.035,0.02,0.035),Color(colour)))
	destination(Foragers.HOME,Color("fac35f"),"HOME")
	destination(Foragers.FOOD,Color("a0ef82"),"FOOD")
	label("WHAT THE POINT CARRIES",Vector3(0,2.28,-1.3),32)
	caption = label("",Vector3(0,1.88,-1.3),22)
	label("Cube above point: carrying / gold cells: shared trace",Vector3(0,1.49,-1.3),18)
	var actions := [toggle_play, single_step, replace, restart]
	for i in range(4):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run","Step","Replace","Reset"][i]
		button.position = Vector3((i-1.5)*0.72,0.85,1.60)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(["RUN / PAUSE","ONE TICK","REPLACE AGENTS","CLEAR ALL"][i],button.position+Vector3(0,0.17,0),16)
	paint()

func choose(i: int) -> void:
	if points[i].held():
		witness = i
		paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.step()
	paint()

func replace() -> void:
	if any_held(): return
	model.replace_agents()
	playing = false
	elapsed = 0.0
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	for i in range(points.size()):
		if points[i].held():
			model.positions[i] = record(to_local(points[i].global_position))
			model.velocities[i] = Vector2.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Foragers.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Foragers.DT)
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"),model.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.14
	var offsets := [Foragers.TURN,0.0,-Foragers.TURN]
	for i in range(sensors.size()):
		sensors[i].visible = not model.carrying[witness]
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))-Vector3.UP*0.03
	var v: Vector2 = model.velocities[witness]
	caption.text = "Point %d / %s / delivered %d\nv (%.2f, %.2f) cells/s / tick %d\nL %.2f / F %.2f / R %.2f / %s" % [
		witness,"RETURN + DEPOSIT" if model.carrying[witness] else "SEARCH",model.delivered,
		v.x,v.y,model.steps,model.sense(witness,Foragers.TURN),model.sense(witness,0),
		model.sense(witness,-Foragers.TURN),"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
```

</details>

Use the nearby buttons or keys **1** Run/Pause, **2** One Tick, **3** Replace Agents and **R** Clear All. Reset and replace work only when every point is released; presses while holding are ignored. No simulation ticks pass while you hold a point; release resumes only if Run was active. Points return to the display plane when released.

## Predict, then try

Pause. Carry the pink point into the food ring, release and advance one tick. Its green cube appears. Because holding cleared its velocity, the first return tick gives it a small leftward velocity. Move this carrying point into the home ring and advance one tick. The cube disappears and delivered increases once. Another tick there must not count the same delivery again.

Let a trail form. Pause and REPLACE AGENTS. The points lose their cargo and return to the initial arrangement; the marks, tick count and delivered total remain. CLEAR ALL removes those records too. Name which part of the model each button resets before using it.

For an independent edit, set `return_speed` to **1.5**. At position `(8,8)`, velocity `(0,0)`, carrying `true`, predict one tick: desired velocity `(-1.5,0)`, acceleration `(-3,0)`, new velocity `(-0.15,0)`, new position `(7.9925,8)`. The default return speed gives `(-0.3,0)` and `(7.985,8)`. Execute both; do not judge only by the animation.

The supplied checks reconstruct the printed files and exercise both transitions, old-field sensing, bounded movement, reset scope and the speed edit. Faulty versions that never collect, erase the field on replacement or count delivery repeatedly must be detected. Synthetic pickup tests check the carried class and the host; they do not certify physical headset comfort.

## Return to the exhibit

In the colony display, follow a point through food contact and its return. Name the state change you reconstructed. Then compare ANTS with RESET after a trail has formed: which action preserves information outside the bodies? Food exhaustion and recruitment belong to the larger exhibit; the small study cannot explain them yet. It gives you one part of the encounter to recognise and test.

## What travels onward

Carry the same point, its return flag, and the distinction between individual and shared state. The next colony splits the field into **home and food channels**. Each state will choose which channel it reads and which it writes. We are not adding a new kind of creature to explain that change.

<!-- @navigator_noise -->
## Optional study — what reaches the point

- True and observed obstacle distance
- Threshold and waypoint state
- Missing observation: stop or retain a command
- Replayed input and measured outcome

Beside the colony, the inherited sphere follows a known course. Hold the world and start fixed; change the range reading and compare the responses. The [complete navigator companion](supplied/navigator_noise/tutorial.md) prints its model, carried point, constrained handle, stage and scene. It is a separate study of observation and policy; this lesson's tests cover the foraging reconstruction.


---

<a id="SwarmIntelligence_Ant_Colony_Optimization"></a>

## Ant Colony

# Ant Colony — two trails underfoot

The spheres now move through a twelve-metre field. Walk between them. The point from the previous hall still has position, velocity and a carrying flag. This time its journey leaves two kinds of trace.

## Learning elements

- Two separate fields: home trail and food trail.
- State chooses which field to read and which to write.
- Destination contact reverses direction and renews the trail strength.
- Reinforcement and evaporation; replacing bodies versus clearing their traces.

## Start here in the museum

Begin in the twelve-metre field with the blue and rose floor strips. Take the small black point beside the entrance controls: it carries a portable panel, not another colony agent. Its trigger toggles RUN / PAUSE. The four buttons run, step, replace points or clear all. The panel shows the selected agent's SEARCH / RETURN state, the channels it reads and leaves, and its three sensor values.

Hold a large sphere with the other hand and trigger to select it. Holding an agent pauses the colony; release it before stepping or resetting. Holding the panel alone lets movement continue. Drop the panel and it docks after five seconds; regrabbing cancels the return. Both original control banks still work.

**Lesson focus:** watch one state change switch both channels. The ant gallery is a comparison across appearances and scales. The portable panel is supplied museum equipment reading this lesson's model; the complete reconstruction below uses the original end controls.

## Keep the object; change its information

In ABM a returning point knew the home coordinate. Here it finds its direction from three local samples. A searching point reads **food** and writes **home**. A carrying point reads **home** and writes **food**. The destination coordinates are used for contact and source emission, not as a steering target.

Each floor cell has two strips: blue on its left for home, rose on its right for food. These are two numbers at the same address, not two lanes the point must stay inside. A green cube above a sphere means it carries food. The ring around the selected sphere and its three small sensor marks let you follow one record among the others.

Hold any sphere to pause the colony. Move it beside FOOD, release it, then press ONE TICK. Its carry flag turns on. The next samples come from the other field. Carry that same point to HOME and step again: one delivery, the flag off. Holding does not collect or deliver by itself. The trigger selects a held point for the readout.

## The complete rule

Save `colony.gd` beside the carried `point_body.gd` and the host below. The model stays in a 16×16 periodic plane. One cell now occupies 0.75 m; 24 points replace the previous six, using the same rule. The large room changes the view and reach, not the definition of a cell.

`step()` first checks destination contacts. It then reads the previous fields for every point, commits all movement, fades both fields and deposits into the selected channel. The two destinations replenish only their own cells. A new mark cannot steer a later point during the same tick.

On contact we reverse the model velocity once. This is a declared ant-like turn, not a physical collision. Between contacts the bounded steering from Boids remains. Equal sensor readings keep the direction; a stationary searcher starts east and a stationary returner starts west. There is no hidden pathfinder.

<!-- student-code:colony.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const COUNT := 24
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI/4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.995
var deposit_amount := 0.5
var home := PackedFloat32Array()
var food := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var energy: Array[float] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.clear()
	velocities.clear()
	carrying.clear()
	energy.clear()
	for i in range(COUNT):
		var direction := Vector2.from_angle(TAU*i/COUNT)
		positions.append(HOME+direction*0.5)
		velocities.append(direction*SPEED)
		carrying.append(false)
		energy.append(1.0)

func reset() -> void:
	home.resize(WIDTH*WIDTH)
	food.resize(WIDTH*WIDTH)
	home.fill(0.0)
	food.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x+cell.y*WIDTH

func heading(i: int) -> Vector2:
	if not velocities[i].is_zero_approx(): return velocities[i].normalized()
	return Vector2.LEFT if carrying[i] else Vector2.RIGHT

func sensor_position(i: int, offset: float) -> Vector2:
	return wrap_position(positions[i]+heading(i).rotated(offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float, read_home: bool) -> float:
	var cell := index_at(sensor_position(i,offset))
	return home[cell] if read_home else food[cell]

func desired_velocity(i: int) -> Vector2:
	var direction := heading(i)
	var left := sense(i,TURN,carrying[i])
	var ahead := sense(i,0.0,carrying[i])
	var right := sense(i,-TURN,carrying[i])
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func deposit(i: int) -> void:
	var cell := index_at(positions[i])
	var amount := deposit_amount*energy[i]
	if carrying[i]:
		food[cell] = minf(8.0,food[cell]+amount)
	else:
		home[cell] = minf(8.0,home[cell]+amount)

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		if carrying[i] and positions[i].distance_to(HOME) < CONTACT:
			carrying[i] = false
			delivered += 1
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		elif not carrying[i] and positions[i].distance_to(FOOD) < CONTACT:
			carrying[i] = true
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		energy[i] = maxf(0.0,energy[i]-DT*0.05)
		var a := ((desired_velocity(i)-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
	positions = next_positions
	velocities = next_velocities
	for cell in range(home.size()):
		home[cell] *= retention
		food[cell] *= retention
	for i in range(positions.size()):
		deposit(i)
	home[index_at(HOME)] = 8.0
	food[index_at(FOOD)] = 8.0
	steps += 1
```

`read_home` selects one array in `sense()`. In `deposit()`, a carrying point writes food; a searching point writes home. The opposite channel is untouched by that deposit. Both still evaporate in the field update. Energy declines with time since a destination, so a point cannot lay an equally strong trail forever.

Food is inexhaustible. The field wraps at its edges; the home and food contact tests use direct distance. The spheres can overlap and do not push you. This is a small foraging model, not a simulation of ant biology or evidence that the shortest route has been found. The hall's historical ACO title includes optimization methods that require a stated cost and a comparison; this lesson isolates their shared-trace mechanism.

## Put the same point into the room

The prepared museum supplies its floor, player, camera, lights, XRTools and `commons/interactables/push_button.tscn`. Create a Node3D at the centre of a clear 12×12 m working area, with another metre at each end for the controls, and attach `study.gd`. Its local origin is floor level. The permanent exhibit in this hall runs this same host; when reconstructing it, use a working copy of the hall and replace the existing `ant_colony_walk` instance so you do not stack two displays.

The host creates every sphere and field strip in code. PointBody itself is unchanged. Its mesh and collision shape are both enlarged threefold for this room; its rigid-body root stays unscaled. The points travel at 0.8 m above the floor. Hold one to bring it closer. Two matching banks of controls let you pause and step from either end of the field. Keys 1, 2, 3 and R provide the same actions on desktop. The supplied host batches the 512 strips into two MultiMeshes; rendering this many cells does not require one draw per strip.

<details><summary>Carried point_body.gd — complete, unchanged</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

<details><summary>study.gd — complete room and interaction host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Colony = preload("colony.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.75
const HEIGHT := 0.8
const BLUE := Color("49c9ef")
const ROSE := Color("ef789d")
var model = Colony.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var home_tiles: MultiMeshInstance3D
var food_tiles: MultiMeshInstance3D
var sensors: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var selection: MeshInstance3D
var witness := 0
var playing := true
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.4
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.035
	mesh.outer_radius = radius+0.035
	mesh.rings = 48
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 32) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func field(offset: float) -> MultiMeshInstance3D:
	var body := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL*0.43,0.012,CELL*0.9)
	batch.mesh = mesh
	batch.instance_count = Colony.WIDTH*Colony.WIDTH
	body.multimesh = batch
	var material := finish(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	body.material_override = material
	add_child(body)
	for y in range(Colony.WIDTH):
		for x in range(Colony.WIDTH):
			var at := place(Vector2(x+0.5,y+0.5))
			at.x += offset
			at.y = 0.035
			batch.set_instance_transform(x+y*Colony.WIDTH,Transform3D(Basis.IDENTITY,at))
	return body

func _ready() -> void:
	tile(Vector3(12.1,0.02,12.1),Color("111822")).position.y = 0.015
	home_tiles = field(-CELL*0.23)
	food_tiles = field(CELL*0.23)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		point.tint = Color("eae7e0") if i%2 == 0 else Color("25212a")
		# Enlarge the existing geometry and grab shape, not the rigid-body root.
		point.get_child(0).scale = Vector3.ONE*3.0
		point.get_child(1).shape.radius *= 3.0
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.15,Color("a0ef82")))
	for colour in [BLUE,Color.WHITE,ROSE]:
		sensors.append(tile(Vector3(0.12,0.04,0.12),colour))
	selection = ring(0.34,Color("ffd16d"))
	for target in [Colony.HOME,Colony.FOOD]:
		var is_home: bool = target == Colony.HOME
		var at := place(target)
		at.y = 0.10
		ring(Colony.CONTACT*CELL,BLUE if is_home else ROSE).position = at
		label("HOME / BLUE" if is_home else "FOOD / ROSE",at+Vector3.UP*2.0)
	for side in [-1,1]:
		var z: float = side*6.5
		var bank_x: float = -side*3.5
		label("TWO TRAILS UNDERFOOT",Vector3(0,3.3,z),52)
		captions.append(label("",Vector3(bank_x,1.95,z),22))
		label("Hold: pause + move   /   held trigger: select",Vector3(bank_x,1.45,z),16)
		tile(Vector3(3.65,0.08,0.5),Color("303747")).position = Vector3(bank_x,0.88,z)
		var actions := [toggle_play,single_step,replace,restart]
		for i in range(4):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Replace","Reset"][i]+str(side)
			button.position = Vector3(bank_x+(i-1.5)*1.0,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE TICK","REPLACE POINTS","CLEAR ALL"][i],button.position+Vector3.UP*0.25,20)
			words.pixel_size = 0.0025
	paint()

func choose(i: int) -> void:
	if points[i].held(): witness = i
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing
	paint()

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.step()
	paint()

func replace() -> void:
	if any_held(): return
	model.replace_agents()
	playing = false
	elapsed = 0.0
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	for i in range(points.size()):
		if points[i].held():
			model.positions[i] = record(to_local(points[i].global_position))
			model.velocities[i] = Vector2.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Colony.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Colony.DT)
	paint()

func paint() -> void:
	for i in range(model.home.size()):
		home_tiles.multimesh.set_instance_color(i,Color("142430").lerp(BLUE,model.home[i]/8.0))
		food_tiles.multimesh.set_instance_color(i,Color("241b29").lerp(ROSE,model.food[i]/8.0))
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.4
	selection.position = to_local(points[witness].global_position)-Vector3.UP*0.24
	var offsets := [Colony.TURN,0.0,-Colony.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))
		sensors[i].position.y = 0.13
	var returning: bool = model.carrying[witness]
	for text in captions:
		text.text = "Point %d / %s / delivered %d\nREAD %s  /  LEAVE %s\nL %.2f   F %.2f   R %.2f  / tick %d / %s" % [witness,
			"RETURN" if returning else "SEARCH",model.delivered,"HOME" if returning else "FOOD",
			"FOOD" if returning else "HOME",model.sense(witness,Colony.TURN,returning),
			model.sense(witness,0,returning),model.sense(witness,-Colony.TURN,returning),model.steps,
			"HELD" if any_held() else ("RUN" if playing else "PAUSE")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
```

</details>

The host keeps painting while paused. Holding a point records its position in the host's local frame and zeros its velocity. Release projects it back onto the field plane. Its carrying flag and energy stay with it. REPLACE POINTS restores the starting population but keeps both fields, deliveries and tick count. CLEAR ALL resets those records too; it retains your retention and deposit settings. Reset actions wait until all points are released.

## Predict, then change something

Pause the room. Put a searching point at FOOD. Predict: it becomes a returner, reads blue and leaves rose. Move that carrying point to HOME. Predict the reverse, with one delivery. Now replace the points: the marks remain. Clear all: the fields are empty until the next tick replenishes the destination cells.

For an independent code change, set `deposit_amount` to 0.25 instead of 0.5. A point with energy 1 deposits 0.25 into an empty cell when you call `deposit()` directly. On a tick, energy falls first to 0.9975, so its new mark is 0.249375 before another point adds anything. Test a cell away from the two sources. The other channel must remain zero. Explain why fading alone would not establish which channel was written.

Carry this distinction onward: the trace is stored outside the point. Particle Swarm Optimization replaces the trails and carrying flag with personal and shared records of scored positions. The PointBody class stays; the colony behaviour does not. We will have to ask what makes a position “best”.


---

<a id="SwarmIntelligence_Particle_Swarm_Optimization"></a>

## Particle Swarm

# Particle Swarm — a place remembered

Walk between the spheres. Hold one and move it away from the gathering. A blue ring stays behind: a position this point remembers. The gold ring marks the best position found by the group. Release the sphere and step the model. Its next movement combines where it was going, where it remembers doing well, and what the others have found.

## Learning elements

- A score is a number assigned to a position by an objective function.
- Store a personal best as both a position and its score.
- Combine inertia, personal attraction and shared attraction.
- Evaluate the starting population before moving; give every point the same shared record for one iteration.
- Changing the objective starts a new set of best records.

## Start here in the museum

Begin in the large sphere field. Take the small black grip beside the entrance bank and carry its score panel with you. Its trigger toggles RUN / PAUSE; the six buttons run, step, restart or choose CENTER, EDGE and RIDGE. Select a large sphere with its held trigger. The panel pairs its current coordinate and score with its blue personal-best record and the gold shared-best record.

Holding a candidate pauses the model and blocks stepping, restart and objective changes until release. Holding the panel alone does not pause it. Dropping the panel returns it after five seconds. Coordinates on the panel belong to the search plane, not its position in your hand.

**Lesson focus:** compare where the point is with where it remembers doing better. The smaller NOVELTY display is a later comparison. The supplied panel reads the same records as the original end controls; the complete code below reconstructs the lesson with those controls.

## Keep the point; move the memory

Ant Colony left information in the floor. Here we keep the same grabbable PointBody, but replace its carrying flag and trail sampling with a remembered position and score. The floor shows the scoring rule; it does not accumulate trails. Brighter tiles have a higher score under the current rule.

The room starts paused on CENTER, so you can meet the scattered points before they gather. Press RUN or ONE STEP when ready. The score is `-(x*x + y*y)`: the centre scores zero, and positions farther away score less. **Larger wins** throughout this lesson. The gold ring means best encountered so far, not a proven optimum. The points can coincide; they are candidate solutions, not birds avoiding a collision.

The host projects positions into a twelve-metre square. Model x runs across it; model y runs along local negative Z. These two numbers describe a search coordinate, not height. The floor stays flat.

## The complete search rule

Save `swarm.gd` beside the carried `point_body.gd` and the room host below. `reset_memories()` scores all starting positions before the first move. Each record keeps the position that earned its score. `remember()` replaces that pair only when the new score is strictly greater; ties retain the earlier record.

`terms()` returns three vectors: the previous displacement multiplied by inertia, a pull toward the point's own best, and a pull toward the group's best. Each pull gets a seeded random multiplier between zero and one. A fixed seed makes the experiment repeatable; it does not make its conclusions universal.

<!-- student-code:swarm.gd -->
```gdscript
extends RefCounted
enum Objective { CENTER, EDGE, RIDGE }
const LIMIT := 6.0
const MAX_STEP := 0.35
var inertia := 0.6
var personal_pull := 1.5
var social_pull := 1.5
var objective := Objective.CENTER
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var best_positions: Array[Vector2] = []
var best_scores: Array[float] = []
var shared_position := Vector2.ZERO
var shared_score := -INF
var steps := 0
var random := RandomNumberGenerator.new()

func _init() -> void:
	reset()

func score(p: Vector2) -> float:
	if objective == Objective.EDGE: return p.length_squared()
	if objective == Objective.RIDGE: return -pow(p.x-p.y,2.0)/2.0
	return -p.length_squared()

func reset() -> void:
	random.seed = 101006
	positions.clear()
	velocities.clear()
	for i in range(24):
		positions.append(Vector2(random.randf_range(-5.5,5.5),random.randf_range(-5.5,5.5)))
		velocities.append(Vector2(random.randf_range(-0.15,0.15),random.randf_range(-0.15,0.15)))
	steps = 0
	reset_memories()

func reset_memories() -> void:
	best_positions = positions.duplicate()
	best_scores.clear()
	for p in positions: best_scores.append(score(p))
	update_shared()

func update_shared() -> void:
	shared_score = -INF
	for i in range(best_scores.size()):
		if best_scores[i] > shared_score:
			shared_score = best_scores[i]
			shared_position = best_positions[i]

func change_objective(next: int) -> void:
	objective = clampi(next,Objective.CENTER,Objective.RIDGE)
	reset_memories()

func remember() -> void:
	for i in range(positions.size()):
		var value := score(positions[i])
		if value > best_scores[i]:
			best_scores[i] = value
			best_positions[i] = positions[i]
	update_shared()

func terms(i: int, r1: float, r2: float, shared: Vector2) -> Array[Vector2]:
	return [inertia*velocities[i],
		personal_pull*r1*(best_positions[i]-positions[i]),
		social_pull*r2*(shared-positions[i])]

func step() -> void:
	# Include a hand-placed candidate before this iteration starts.
	remember()
	var shared := shared_position
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		var parts := terms(i,random.randf(),random.randf(),shared)
		var v := (parts[0]+parts[1]+parts[2]).limit_length(MAX_STEP)
		var p := positions[i]+v
		# A bounded search square: stop outward motion at its edge.
		if absf(p.x) > LIMIT:
			p.x = clampf(p.x,-LIMIT,LIMIT)
			v.x = 0.0
		if absf(p.y) > LIMIT:
			p.y = clampf(p.y,-LIMIT,LIMIT)
			v.y = 0.0
		next_positions.append(p)
		next_velocities.append(v)
	positions = next_positions
	velocities = next_velocities
	remember()
	steps += 1
```

`step()` includes any hand-placed candidates first, then takes one copy of the shared best. Every point uses that same copy. Positions are committed together before the new best records are chosen. One point cannot silently use a discovery made halfway through another point's update.

Here `velocities` stores **displacement per algorithm iteration**, not metres per second. We cap a move at 0.35 model units and stop an outward component at the square's boundary. The host plays ten iterations per second. This is a discrete optimizer, not a force simulation; changing playback speed changes how quickly you watch it.

## Try another meaning of better

Pause and press EDGE. The positions and velocities remain. Every remembered position becomes its point's current position, and every score is recalculated as `x*x + y*y`. The four corners score highest. This rewards distance from the centre; it does not reward separation between points. All points may choose the same corner.

RIDGE uses `-(x-y)^2 / 2`: minus squared perpendicular distance to the diagonal x=y. Every position along that diagonal has the same best score. A line of equally good answers is different from one preferred destination. Switching objectives pauses the model, so you can inspect the new records before resuming. RESTART scatters the same starting population and resets the random stream under the selected objective; it keeps your three coefficients.

The smaller existing display at the back adds NOVELTY. Its score depends on a changing archive, so it must rescore memories when that archive changes. It is a comparison with an additional mechanism, not hidden work required by this first reconstruction. That display also uses different score units: ordinary distance rather than the squared distance used here.

## Put it in the existing museum

Use a working copy of this hall. Replace its `particle_swarm_walk` instance with a Node3D carrying `study.gd`; do not overlay two installations. Set the origin at floor level, leaving 12×12 m for the field and another metre at each end for controls. The museum already supplies the floor, player, camera, light, XRTools and `commons/interactables/push_button.tscn`.

The unchanged PointBody is printed below. The host enlarges its mesh and grab shape together to 0.51 m diameter while leaving the rigid-body root unscaled. These frozen, model-driven pickables move at 0.8 m height, overlap freely and do not push the player.

<details><summary>point_body.gd — carried unchanged from Ant Colony</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

<details><summary>study.gd — complete display and interaction host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Swarm = preload("swarm.gd")
const PointBody = preload("point_body.gd")
const PERIOD := 0.1
const BLUE := Color("49c9ef")
const GOLD := Color("ffd16d")
var model = Swarm.new()
var points: Array[Node3D] = []
var captions: Array[Label3D] = []
var field: MultiMeshInstance3D
var personal: MeshInstance3D
var shared: MeshInstance3D
var selection: MeshInstance3D
var connections: Array[MeshInstance3D] = []
var memory_labels: Array[Label3D] = []
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3(p.x,0.8,-p.y)

func record(p: Vector3) -> Vector2:
	return Vector2(clampf(p.x,-6,6),clampf(-p.z,-6,6))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.4
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.03
	mesh.outer_radius = radius+0.03
	mesh.rings = 48
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func connector(colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.018
	mesh.height = 1.0
	mesh.radial_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func connect_positions(body: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b-a
	body.visible = d.length() > 0.001
	if not body.visible: return
	body.transform = Transform3D(Basis(Quaternion(Vector3.UP,d.normalized()))*Basis.from_scale(Vector3(1,d.length(),1)),(a+b)*0.5)

func _ready() -> void:
	tile(Vector3(12.1,0.02,12.1),Color("111822")).position.y = 0.015
	field = MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var cell := BoxMesh.new()
	cell.size = Vector3(0.72,0.012,0.72)
	batch.mesh = cell
	batch.instance_count = 256
	field.multimesh = batch
	var material := finish(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	field.material_override = material
	add_child(field)
	for y in range(16):
		for x in range(16):
			batch.set_instance_transform(x+y*16,Transform3D(Basis.IDENTITY,Vector3((x+0.5)*0.75-6,0.035,-((y+0.5)*0.75-6))))
	for i in range(model.positions.size()):
		var point = PointBody.new()
		point.tint = Color("eae7e0") if i%2 == 0 else Color("25212a")
		point.get_child(0).scale = Vector3.ONE*3.0
		point.get_child(1).shape.radius *= 3.0
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
	selection = ring(0.32,Color.WHITE)
	personal = ring(0.4,BLUE)
	shared = ring(0.6,GOLD)
	connections = [connector(BLUE),connector(GOLD)]
	memory_labels = [label("MY BEST",Vector3.ZERO,18),label("GROUP BEST",Vector3.ZERO,18)]
	for side in [-1,1]:
		var z: float = side*6.7
		var bank_x: float = -side*3.2
		label("BETTER ACCORDING TO WHICH SCORE?",Vector3(0,3.3,z),40)
		captions.append(label("",Vector3(bank_x,1.95,z),19))
		label("Hold: pause + move   /   held trigger: select",Vector3(bank_x,1.4,z),16)
		tile(Vector3(4.45,0.08,0.5),Color("303747")).position = Vector3(bank_x,0.88,z)
		var actions := [toggle_play,single_step,restart,func(): change(0),func(): change(1),func(): change(2)]
		for i in range(6):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Reset","Center","Edge","Ridge"][i]+str(side)
			button.position = Vector3(bank_x+(i-2.5)*0.82,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE STEP","RESTART","CENTER","EDGE","RIDGE"][i],button.position+Vector3.UP*0.24,19)
			words.pixel_size = 0.0025
	colour_field()
	paint()

func choose(i: int) -> void:
	if points[i].held(): witness = i
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing
	paint()

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.step()
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
	paint()

func change(next: int) -> void:
	if any_held(): return
	model.change_objective(next)
	playing = false
	elapsed = 0.0
	colour_field()
	paint()

func _process(delta: float) -> void:
	for i in range(points.size()):
		if points[i].held():
			model.positions[i] = record(to_local(points[i].global_position))
			model.velocities[i] = Vector2.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= PERIOD:
			model.step()
			elapsed = maxf(0.0,elapsed-PERIOD)
	paint()

func colour_field() -> void:
	for i in range(256):
		var at := field.multimesh.get_instance_transform(i).origin
		var value: float = model.score(record(at))/72.0
		if model.objective != Swarm.Objective.EDGE: value += 1.0
		field.multimesh.set_instance_color(i,Color("142430").lerp(Color("bb9964"),clampf(value,0,1)))

func paint() -> void:
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
	selection.position = to_local(points[witness].global_position)-Vector3.UP*0.24
	personal.position = place(model.best_positions[witness]); personal.position.y = 0.11
	shared.position = place(model.shared_position); shared.position.y = 0.16
	var start := place(model.positions[witness]); start.y = 0.09
	connect_positions(connections[0],start,personal.position)
	connect_positions(connections[1],start,shared.position)
	memory_labels[0].position = personal.position+Vector3.UP*0.4
	memory_labels[1].position = shared.position+Vector3.UP*0.65
	var formula: String = ["CENTER: -(x*x+y*y)","EDGE: x*x+y*y","RIDGE: -(x-y)^2 / 2"][model.objective]
	for text in captions:
		text.text = "%s / larger wins\nPoint %d: now %.2f / remembered %.2f\nGroup %.2f / step %d / %s" % [formula,witness,model.score(model.positions[witness]),model.best_scores[witness],model.shared_score,model.steps,"HELD" if any_held() else ("RUN" if playing else "PAUSE")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_R: restart()
		elif event.keycode == KEY_3: change(0)
		elif event.keycode == KEY_4: change(1)
		elif event.keycode == KEY_5: change(2)
```

</details>

Hold a point to pause all motion and change its position. Its previous best remains visible; moving it by hand is not yet an evaluated iteration. Release and step: the new position is scored before movement. A worse placement leaves its remembered best intact. Holding zeros velocity. A held trigger selects that point for the readout. Reset and objective changes wait until all points are released.

The white ring follows the selected body; blue marks its own best; gold marks the group's. Thin cylinders join the current position to these remembered destinations. They show position differences, not the weighted random terms or a predicted path. Two control banks operate the same model. Desktop keys 1/2 run and step, R restarts, and 3/4/5 select CENTER/EDGE/RIDGE.

## Predict one movement

Use `terms()` with a controlled example: position (0.2, 0.1), velocity (0.1, 0), own best (0.1, 0.1), shared best (0, 0), and multipliers 0.5 and 0.25. With the supplied coefficients the three contributions are (0.06, 0), (-0.075, 0), and (-0.075, -0.0375). Their sum is (-0.09, -0.0375), below the cap. The next position is (0.11, 0.0625).

Now independently set `social_pull` to 0.0. For the same inputs, the sum is (-0.015, 0) and the next position is (0.185, 0.1). Predict the change before running it. In the room, restart and compare: removing the shared pull changes what can coordinate the points, without deleting their personal memory.

The last Swarm hall keeps PointBody and the habit of inspecting a record. It sets this optimizer aside and supplies the museum's existing ecosystem. We will write an account of births, losses and bodies added from outside, then compare it with the population we can see. A scored destination and a population account answer different questions.


---

<a id="SwarmIntelligence_Swarm_Intelligence_Algorithms"></a>

## Population Support

# Swarm — who keeps the count?

Walk among the blue and pink spheres. Green points are food. Start the model and watch the population change. Some new bodies wear a gold ring: the system supplied them. A rising count does not, by itself, tell you that anything was born.

## Learning elements

- Record an event as a dictionary; keep events in an array.
- Separate births, losses and supplied bodies.
- Reconstruct a count from an initial state and recorded changes.
- Compare the reconstructed count with the actual population.
- State what an observation can and cannot establish.

## Start here in the museum

Take the small black grip beside the entrance bank. Its portable account has separate PREY and PREDATORS columns: initial, born, lost, supplied, expected, actual and gap. Trigger the grip to run or pause; the four buttons also offer ONE STEP, RESTART and SUPPLY ROW. Select an organism with its held trigger to read its origin and health beside the account.

Holding an organism pauses the model; release it before stepping or restarting. Holding only the panel does not pause it. SUPPLY ROW remains available while a body is held. Omit it and inspect the gap without another update moving the bodies. Dropping the panel returns it after five seconds. The original end controls share the same account.

**Lesson focus:** reconcile the visible population with its recorded changes. The portable view is supplied museum equipment; the complete code below reconstructs the account, observer and original controls.

## Change the scale of the question

So far we have asked what changes a point's movement or choice. Now ask what keeps a population present to make those movements. One body's steering record cannot explain the arrival of five supplied bodies. We change from controlling movement to recording population events. This is why the new operation is an account.

## Keep the point; account for its arrival

We carry the grabbable PointBody from Particle Swarm. Its colour now identifies prey or predator; its arrival can be initial, born or supplied. A remembered best position is no longer the useful record. We need a history of changes to the population.

The existing museum ecosystem supplies the moving organisms, feeding, reproduction and population support. **Our new object is its account.** We do not rebuild the ecosystem or introduce all its biology in this lesson. Its source dependency is `res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd`, with `Creature.gd` and `food.gd` in that folder. The complete observer and display host below connect our account to that real implementation.

The hall begins paused with 50 prey and 5 predators. RUN advances the supplied model; ONE STEP advances one update. Hold any blue or pink sphere to pause everyone and move it. Its arrival record stays with it. Press the held trigger to inspect its source and health. Release to resume if RUN was active. These spheres are model-driven pickables, not rigid-body predators that push the visitor.

Let it run until a gold-ringed point arrives. In the recorded run this happened within thirty seconds of model time; pauses and slow frames extend the wait. Then compare the full account with SUPPLY ROW omitted.

## The complete account

For one population:

`now = initial + born - lost + supplied`

Each event has a `kind`, `species` and positive `amount`. The observer also supplies a serial number, update number, source position and body identifier. We use the first three fields to count. The others can locate a change without pretending to explain everything that led to it.

Save this as `account.gd`. `begin()` takes the population at the start of an observation and clears its previous events. `record()` stores a copy so changing the caller's dictionary later cannot rewrite the history. `total()` loops through that history and adds only matching entries. `difference()` subtracts our prediction from an independently observed count.

<!-- student-code:account.gd -->
```gdscript
extends RefCounted
var initial := {"prey":0, "predator":0}
var events: Array[Dictionary] = []

func begin(prey: int, predators: int) -> void:
	initial = {"prey":prey, "predator":predators}
	events.clear()

func record(event: Dictionary) -> void:
	events.append(event.duplicate(true))

func total(species: String, kind: String) -> int:
	var amount := 0
	for event in events:
		if event.species == species and event.kind == kind:
			amount += int(event.amount)
	return amount

func expected(species: String, include_supplied: bool = true) -> int:
	var count: int = initial[species]
	count += total(species,"birth")
	count -= total(species,"loss")
	if include_supplied:
		count += total(species,"supplied")
	return count

func difference(species: String, actual: int, include_supplied: bool = true) -> int:
	return actual-expected(species,include_supplied)
```

With 10 initial prey, 2 births, 3 losses and 5 supplied prey, we expect 14. If the actual list contains 14, the difference is zero. Omit the supplied row and the account predicts 9: five bodies are unexplained. Zero difference establishes consistency of this count, not a complete account of the ecosystem. Two recording mistakes could also cancel each other. Supplied arrivals accumulate in the history, including bodies that later die. The omitted-row gap therefore need not equal the number of living gold-ringed spheres.

## Where the events come from

Save `observed.gd` beside the account. It extends the existing ecosystem, calls its methods, and adds observations. Initial spawns are the baseline, not births. Spawns inside `check_for_mate()` are births. Later spawns outside that call are supplied bodies. Removal is recorded by comparing the body's membership before and after each prey or predator update. The source uses `queue_free()`, so a removed body's identity and position remain available during that comparison.

Population support is already part of this model: fewer than 10 prey causes five to be supplied; fewer than two predators can cause two to be supplied when prey exceed 20. A high predator-to-prey ratio reduces predator health. Outside food also arrives probabilistically. Food and pressure events are recorded separately. Neither is a birth or an immediate extra creature. Their later consequences may appear as births or losses.

<details><summary>observed.gd — complete observer of the supplied ecosystem</summary>

<!-- student-code:observed.gd -->
```gdscript
extends "res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd"
## Observe the supplied model. Its movement, feeding, birth and care rules remain.
signal event_record(event: Dictionary)
var recording := false
var origin_kind := "supplied"
var tick := 0
var serial := 0
var arrivals: Array = []

func _ready() -> void:
	super._ready()
	set_process(false)
	hide()
	recording = true

func emit_record(kind: String, species: String, amount: int, at: Vector3, body_id: int = 0) -> void:
	if not recording: return
	serial += 1
	event_record.emit({"serial":serial,"tick":tick,"kind":kind,"species":species,
		"amount":amount,"at":at,"body_id":body_id})

func spawn_prey(pos: Vector3, values: Dictionary = {}) -> EcoPrey:
	var body = super.spawn_prey(pos,values)
	if recording: arrivals.append(body)
	body.set_meta("arrival",origin_kind if recording else "initial")
	emit_record(origin_kind,"prey",1,pos,body.get_instance_id())
	return body

func spawn_predator(pos: Vector3, values: Dictionary = {}) -> EcoPredator:
	var body = super.spawn_predator(pos,values)
	if recording: arrivals.append(body)
	body.set_meta("arrival",origin_kind if recording else "initial")
	emit_record(origin_kind,"predator",1,pos,body.get_instance_id())
	return body

func check_for_mate(creature, is_predator: bool = false) -> void:
	var previous := origin_kind
	origin_kind = "birth"
	super.check_for_mate(creature,is_predator)
	origin_kind = previous

func losses(before: Array, after: Array, species: String) -> void:
	# Nodes removed by the source remain valid until queue_free completes.
	for body in before:
		if not after.has(body):
			emit_record("loss",species,1,body.position,body.get_instance_id())

func update_prey(delta: float) -> void:
	var before := prey_list.duplicate()
	arrivals.clear()
	super.update_prey(delta)
	losses(before+arrivals,prey_list,"prey")

func update_predators(delta: float) -> void:
	var old_prey := prey_list.duplicate()
	var old_predators := predator_list.duplicate()
	arrivals.clear()
	super.update_predators(delta)
	losses(old_prey,prey_list,"prey")
	losses(old_predators+arrivals,predator_list,"predator")

func _record_care(kind: String, amount: int) -> void:
	super._record_care(kind,amount)
	# Supplied creatures are already counted at spawning; do not count twice.
	if kind == "food_added": emit_record("food","support",amount,Vector3.ZERO)
	if kind == "pressure_steps": emit_record("pressure","support",amount,Vector3.ZERO)

func advance(delta: float) -> void:
	tick += 1
	super._process(delta)

func restart() -> void:
	recording = false
	tick = 0
	serial = 0
	origin_kind = "supplied"
	arrivals.clear()
	_rebuild_now()
	recording = true
```

</details>

The observer changes no movement, feeding, reproduction or support rule. Loss records are emitted after each update pass, while births are recorded at creation; serial order is receipt order, not a claim about the exact chronology inside a pass. Compare population totals after a completed step. The account records **that** a body left, not a certified reason for every death.

## Put the account in the existing museum

Save the carried `point_body.gd` and the complete `study.gd` below beside the first two scripts. Attach `study.gd` to a Node3D at floor level in a working copy of this hall, replacing its `population_account_walk` instance. Leave a 12.5 m square plus space for controls at both ends. The museum supplies floor, player, camera, lighting, XRTools and `commons/interactables/push_button.tscn`. Running that prepared museum is assumed from Day Zero.

<details><summary>point_body.gd — unchanged from Particle Swarm</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

<details><summary>study.gd — complete room display and interaction host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Account = preload("account.gd")
const Observed = preload("observed.gd")
const PointBody = preload("point_body.gd")
const PERIOD := 1.0/60.0
const PREY := Color("71d9e9")
const PREDATOR := Color("ec7697")
const SUPPLY := Color("ffcd68")
var account = Account.new()
var model = Observed.new()
var points: Dictionary = {}
var captions: Array[Label3D] = []
var notes: Array[Label3D] = []
var selection: MeshInstance3D
var food: MultiMeshInstance3D
var witness := 0
var playing := false
var elapsed := 0.0
var show_supply := true

func place(p: Vector3) -> Vector3:
	return Vector3(p.x*15.0,0.8+p.y*3.0,p.z*15.0)

func record(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x/15.0,-0.4,0.4),clampf((p.y-0.8)/3.0,0,0.4),clampf(p.z/15.0,-0.4,0.4))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.35
	return material

func tile(size: Vector3, colour: Color, at: Vector3) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.material_override = finish(colour)
	surface.position = at
	add_child(surface)

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.025
	mesh.outer_radius = radius+0.025
	mesh.rings = 32
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	return body

func _ready() -> void:
	add_child(model)
	account.begin(model.prey_list.size(),model.predator_list.size())
	model.event_record.connect(account.record)
	tile(Vector3(12.5,0.02,12.5),Color("152d36"),Vector3(0,0.015,0))
	for side in [-1,1]:
		tile(Vector3(12.5,0.015,0.06),SUPPLY,Vector3(0,0.035,side*6.25))
		tile(Vector3(0.06,0.015,12.5),SUPPLY,Vector3(side*6.25,0.035,0))
	food = MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var pellet := SphereMesh.new()
	pellet.radius = 0.07
	pellet.height = 0.14
	pellet.radial_segments = 8
	pellet.rings = 4
	batch.mesh = pellet
	food.multimesh = batch
	food.material_override = finish(Color("9ff082"))
	add_child(food)
	selection = ring(0.36,Color.WHITE)
	add_child(selection)
	for side in [-1,1]:
		var z: float = side*6.9
		var x: float = -side*3.1
		label("WHO KEEPS THEM HERE?",Vector3(0,3.8,z),42)
		captions.append(label("",Vector3(0,2.8,z),26))
		notes.append(label("",Vector3(x,1.8,z),17))
		tile(Vector3(3.65,0.08,0.5),Color("35444a"),Vector3(x,0.88,z))
		var actions := [toggle_play,single_step,restart,toggle_supply]
		for i in range(4):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Restart","Record"][i]+str(side)
			button.position = Vector3(x+(i-1.5)*1.05,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE STEP","RESTART","SUPPLY ROW"][i],button.position+Vector3.UP*0.23,19)
			words.pixel_size = 0.0025
		label("BLUE prey / PINK predators / GREEN food\nGOLD ring = supplied body\nHold a sphere: pause + move / trigger: inspect",Vector3(-x,1.3,z),21)
	paint()

func bodies() -> Array:
	return model.prey_list+model.predator_list

func any_held() -> bool:
	for point in points.values():
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.advance(PERIOD)
	paint()

func restart() -> void:
	if any_held(): return
	playing = false
	elapsed = 0.0
	model.restart()
	account.begin(model.prey_list.size(),model.predator_list.size())
	show_supply = true
	paint()

func toggle_supply() -> void:
	show_supply = not show_supply
	paint()

func choose(id: int) -> void:
	if points.has(id) and points[id].held(): witness = id

func _process(delta: float) -> void:
	for body in bodies():
		var id: int = body.get_instance_id()
		if points.has(id) and points[id].held():
			body.position = record(to_local(points[id].global_position))
			body.velocity = Vector3.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.1)
		while elapsed+0.000001 >= PERIOD:
			model.advance(PERIOD)
			elapsed = maxf(0,elapsed-PERIOD)
	paint()

func paint() -> void:
	var live := bodies()
	var ids: Array[int] = []
	for body in live:
		var id: int = body.get_instance_id()
		ids.append(id)
		if not points.has(id):
			var point = PointBody.new()
			point.tint = PREY if model.prey_list.has(body) else PREDATOR
			point.get_child(0).scale = Vector3.ONE*3
			point.get_child(1).shape.radius *= 3
			add_child(point)
			point.action_pressed.connect(func(_source): choose(id))
			if body.get_meta("arrival") == "supplied":
				var mark := ring(0.3,SUPPLY)
				point.add_child(mark)
			points[id] = point
		if not points[id].held(): points[id].position = place(body.position)
	for id in points.keys():
		if not ids.has(id):
			points[id].queue_free()
			points.erase(id)
	if not points.has(witness): witness = ids[0] if not ids.is_empty() else 0
	selection.visible = points.has(witness)
	if selection.visible: selection.position = to_local(points[witness].global_position)-Vector3.UP*0.25
	if food.multimesh.instance_count != model.food_list.size():
		food.multimesh.instance_count = model.food_list.size()
	for i in range(model.food_list.size()):
		food.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,place(model.food_list[i].position)))
	var lines := ""
	for species in ["prey","predator"]:
		var actual: int = model.prey_list.size() if species == "prey" else model.predator_list.size()
		lines += "%s: %d + %d born - %d lost + %s supplied = %d / actual %d / gap %d\n" % [species.to_upper(),account.initial[species],account.total(species,"birth"),account.total(species,"loss"),str(account.total(species,"supplied")) if show_supply else "?",account.expected(species,show_supply),actual,account.difference(species,actual,show_supply)]
	for text in captions:
		text.text = lines+("FULL RECORD" if show_supply else "FILTERED: SUPPLIED BODIES OMITTED")
	var arrival := "none"
	var health := 0.0
	for body in live:
		if body.get_instance_id() == witness:
			arrival = body.get_meta("arrival")
			health = body.health
	for text in notes:
		text.text = "%s / step %d\nSelected: %s / health %.2f\nOutside food %d / pressure steps %d" % ["HELD" if any_held() else ("RUN" if playing else "PAUSE"),model.tick,arrival,health,account.total("support","food"),account.total("support","pressure")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_R: restart()
		elif event.keycode == KEY_3: toggle_supply()
```

</details>

The host enlarges the display: model x and z are multiplied by 15, and model y by 3, with an added 0.8 m height. The resulting field is 12 m across and 1.2 m high. Bodies are 0.51 m across, with equally enlarged grab shapes and unscaled rigid-body roots. These are readable markers; their visible size is not the model's feeding distance. The model wraps at its own boundaries, so a body may reappear at the opposite side. That is not a birth or a loss.

Movement is sampled at a fixed 60 updates per second. This matters because the existing model applies some changes per update rather than per second. We keep those rules and declare the update rate; this is not a calibrated ecological simulation. Long rendering stalls slow playback. Holding pauses the clock, moves the chosen body in model coordinates and clears its velocity; it is an intervention, not neutral observation.

RUN, ONE STEP, RESTART and SUPPLY ROW are available at both ends; desktop keys are 1, 2, R and 3. RESTART resets model, seed and account together. It waits while a body is held. SUPPLY ROW only filters the displayed calculation. It neither stops care nor deletes the stored events. Gold rings remain visible. When the filtered count diverges from the actual population, restore the row and compare.

## Reconstruct it, then try a missing record

Create an account, begin with 10 prey and 2 predators, and record prey events `birth:2`, `loss:3`, `supplied:5`. Assert that `expected("prey") == 14` and `difference("prey",14) == 0`. Predator count must remain 2. Record a support-food event: neither population count should change.

Independently repeat the exercise with the supplied event missing. Predict the difference before running: the account expects 9 while 14 bodies exist, so the gap is 5. This is a test of incomplete evidence. It is not an experiment in which the ecosystem survived without support. The automated check also runs the actual supplied ecosystem, exercises birth and replenishment, and checks both populations against their real arrays after every update.

## What travels onward

The sequence has given the same point several relations: a trace outside it, a direction already in the field, nearby headings, a carried state, two trail channels, and a remembered score. This last account asks which conditions keep those bodies present at all. In Graph Theory we will select relations and name their edges. Carry this discipline: a recorded connection should say what it connects, and a diagram should leave room for what its record does not contain.

## Optional investigation — a good score, a scattered group

Return to Particle Swarm's RIDGE. Does weaker shared attraction leave the points more dispersed, and at what cost to their scores? Choose your prediction and comparison before running. The [open study brief](OPEN-STUDY.md) uses the same printed model, seed and controls. It asks you to gather an outcome, not to reproduce an answer already supplied here. It is optional. Write your own hypothesis before consulting the separate ghost-student results.

