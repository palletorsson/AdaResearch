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
