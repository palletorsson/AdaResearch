# Boids — who is near?

## Learning elements

- Selecting neighbours by distance; excluding yourself.
- Separation, alignment and cohesion.
- Averages and weighted steering requests.
- Reading one snapshot; committing the next state together.
- The difference between no request and a request to stop.

## Encounter

Find the ringed body in the museum's **flocking_controls** display. Its red, blue and green arrows can disagree. Move one slider and watch that body before judging the whole flock. Then change RADIUS. Which bodies can now contribute to its movement?

Bring the same PointBody from FlowFields. Keep its velocity, bounded steering and local coordinates. **Replace the supplied direction field with observations of nearby points.** We will make the three requests separately before combining them. The aquarium, open flock and film remain comparisons; this lesson does not reconstruct every exhibit.

## Where the code runs

Continue in the prepared Ada museum project, with its player, camera, lights and XR Tools. Save `flock.gd`, `study.gd` and the unchanged `point_body.gd` together. Attach `study.gd` to an unscaled Node3D at floor level in a clear study bay. Reserve 2.7 metres square, with space to approach its local +Z front. The supplied `res://commons/interactables/push_button.tscn` provides the four physical buttons. These three scripts create everything else in the study; no pre-made mesh node is required.

The full PointBody appears at the end for reconstruction. Read the new model first. The table, pickup and fixed-step host continue the preceding lesson.

## First choose who counts

`neighbours(i)` returns the indices of other points less than `radius` cells away. It excludes `i`, even though a point is always at zero distance from itself. At the initial radius of 3.5, point 0 sees points 1 and 2. The distant points do not enter its averages.

We retain the 16 × 16 plane and 0.16 metres per cell. This is still a three-dimensional museum object, but movement is restricted to local XZ so the calculation stays visible from above. The aquarium shows movement in all three dimensions.

The boundary remains periodic: a point crossing one edge reappears at the opposite edge. **Neighbour distances are measured directly across the drawn plane**, not across that seam. Two bodies near opposite edges may therefore be excluded from each other's calculations. This declared boundary choice matches the panel's visible seam; periodic motion does not automatically imply periodic neighbourhoods.

## Three requests, one familiar steering calculation

**Separation:** for neighbours closer than two cells, add vectors pointing away. `offset / d2` has a magnitude of one divided by distance, so closer neighbours contribute more. Normalising the sum chooses a direction; multiply by `SPEED` to request movement that way. Exact overlap has no away direction, so we skip that division. This does not invent a collision response or guarantee that overlapping points separate.

**Alignment:** average the neighbours' velocities. Use that actual average as the desired velocity. Here alignment can change speed as well as heading. If the average is zero, the request is to brake. We do not normalise this average back to full speed.

**Cohesion:** average the offsets to nearby points. That vector points towards their local centre. Normalise it and request movement at `SPEED`. There is no global flock centre in this calculation. A zero centre offset contributes no cohesion request.

Each request uses the FlowFields calculation: `(desired - current) / RESPONSE`, capped at `MAX_ACCEL`. Requests are accelerations in cells/s². Multiply them by their weights, add the active requests and cap the combined acceleration again. Separation starts at weight 1.5; the other weights start at 1. A coloured arrow shows a weighted request; the white arrow shows the capped combination. Large requests can cancel, and the final cap can hide further increases in a weight.

**No neighbours means zero acceleration and coasting.** It does not mean desired velocity zero. This distinction matters: in FlowFields an explicit zero direction requested braking. Here an empty neighbourhood requests nothing. Likewise, balanced separation or an already-centred position contributes no request; only an alignment average of zero explicitly asks this model to stop.

Save as `flock.gd`:

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

At the initial point 0, current velocity is `(1,0)`. Point 1 is one cell to its right, within the separation distance. Point 2 is farther than two cells, so it contributes to alignment and cohesion but not separation. Separation requests movement left; the bounded request is `(-6,0)`. Its weighted value is `(-9,0)`, capped again to `(-6,0)` when it acts alone. After one step the point's velocity is `(0.7,0)`: it is still moving right, but slowing. An arrow is a correction, not an instantaneous direction of travel.

Both neighbours move at `(0,2)`, so alignment requests `(0,2)` and produces acceleration `(-2,4)`. The average offset for cohesion is `(1.5,0.5)`, towards the local group. These are different observations, not three names for the same attraction.

## Let everyone read the same moment

`step()` fills two new arrays while `positions` and `velocities` remain unchanged. Only after all six calculations does it replace the old state. This is the same old/next distinction used in Cellular Automata. No later point reads an earlier point's future. Reversing the list should give the same physical next state, apart from floating-point rounding.

The existing aquarium uses a spatial grid to find neighbours and updates its bodies in place. Its formulas and boundary response also differ. Our small model deliberately uses a full pairwise scan, a shared snapshot and the bounded steering already learned. It is a readable reconstruction of the three-rule idea, not a claim that the aquarium runs this exact script. Neither model is a mass-dependent rigid-body simulation.

## Use the same points to change the neighbourhood

The study begins paused, with separation selected. **Run/pause** advances the same fixed 0.05-second steps. **Next rule** cycles separation → alignment → cohesion → all three. **Radius** switches between 2 and 3.5 cells. **Reset bodies** restores the exact positions and velocities, resets the tick and pauses, while keeping the selected rule, radius and weights. This lets you compare different requests from the same starting arrangement. Desktop keys are **1**, **2**, **3** and **R**.

The gold ring marks the observed point's radius. Cyan rings mark its selected neighbours. Red means separation, blue alignment and green cohesion; white is the acceleration actually applied. Arrow length is 0.07 metres per cell/s², an enlarged diagram rather than a distance the body will travel. The arrows show the requests for the next step.

Hold any point to pause everyone. Move it into or out of a neighbourhood. Press its trigger to make it the observed point. Release it to place it back on the plane. The held point's velocity is cleared; other velocities remain. Movement resumes after release if Run was active. The hand changes a position, not a global flock command. Release held points before Reset bodies; an attached hand continues to supply its point's position.

Save as `study.gd`:

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

`record(to_local(...))` keeps the model in the study's frame while XR Tools holds the sphere under a controller. The familiar host limits a stalled frame to half a second of catch-up. The table has no collision wall: leaving it is handled by the model's wrap rule. Its circles and arrows are explanatory meshes, not forces from the physics engine.

## The body we brought

This file is byte-identical to FlowFields. Its mesh, collision shape, frozen release and pickup behaviour are already learned. The change in this hall belongs to the relation between points.

Save the carried `point_body.gd`:

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

## Make a prediction you can check

1. With separation selected, reset and run one step. Point 0 still moves right, but more slowly. Explain why the left-pointing arrow did not instantly reverse its velocity.
2. Reset, select alignment and predict its first velocity: `(0.9,0.2)`. Then select cohesion from the same reset start. Which observation changed?
3. While paused, change radius from 3.5 to 2. Point 0 loses point 2. Separation stays the same at this start; the local centre changes. Move a distant point inside the circle and check the neighbour list.
4. In the code, change alignment's weight from 1 to 0.5. In alignment mode, predict point 0's first velocity before running it: `(0.95,0.1)`. Reset and compare at the same step, rather than comparing two unrelated scatters.
5. Put a moving point alone. It should coast. Put it beside stationary neighbours in alignment mode. It should slow. Explain the difference between absent input and a request for zero velocity.

The automated reconstruction checks these values using the code printed here, reversed agent order, coincident points, a changed weight and deliberately broken variants. It also exercises the actual buttons and synthetic XR Tools pickup. A passing run verifies this implementation; it does not establish how an independent learner or a headset user experiences the room.

## Return to the exhibit

Return to the ringed body in flocking_controls. Change RADIUS before changing a weight: which neighbours enter the calculation, and which steering arrows respond? Use the small study to explain this selection. Then step onto the observation balcony and follow the open flock through the museum walls. Its numerical bounds do not coincide with the architecture. The nearby aquarium offers another boundary to compare; these exhibits are not enlarged copies of the study's periodic plane.

## What travels onward

The same point now responds to a local set of other bodies. A large pattern can follow without a leader knowing its shape. Keep PointBody, velocity, bounded steering and the shared snapshot. The neighbour selector and three flocking requests remain available tools, but the next study sets them aside. Agent-Based Modeling brings back the shared trace and gives the carried body an internal state: searching or returning with food.

The three-behaviour lineage comes from Craig Reynolds's [Boids work](https://www.red3d.com/cwr/boids/). The museum's implementation and this deliberately small study make their own choices about weights, updates and edges.
