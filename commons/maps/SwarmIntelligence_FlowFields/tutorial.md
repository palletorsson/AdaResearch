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
