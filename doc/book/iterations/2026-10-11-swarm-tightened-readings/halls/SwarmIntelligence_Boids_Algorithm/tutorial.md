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
