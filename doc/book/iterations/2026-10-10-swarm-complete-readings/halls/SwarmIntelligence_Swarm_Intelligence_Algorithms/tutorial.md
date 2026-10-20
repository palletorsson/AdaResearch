# Swarm — who keeps the count?

Walk among the blue and pink spheres. Green points are food. Start the model and watch the population change. Some new bodies wear a gold ring: the system supplied them. A rising count does not, by itself, tell you that anything was born.

## Learning elements

- Record an event as a dictionary; keep events in an array.
- Separate births, losses and supplied bodies.
- Reconstruct a count from an initial state and recorded changes.
- Compare the reconstructed count with the actual population.
- State what an observation can and cannot establish.

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

With 10 initial prey, 2 births, 3 losses and 5 supplied prey, we expect 14. If the actual list contains 14, the difference is zero. Omit the supplied row and the account predicts 9: five bodies are unexplained. Zero difference establishes consistency of this count, not a complete account of the ecosystem. Two recording mistakes could also cancel each other.

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

Return to Particle Swarm's RIDGE. Does weaker shared attraction leave the points more dispersed, and at what cost to their scores? Choose your prediction and comparison before running. The [open study brief](../../OPEN-STUDY.md) uses the same printed model, seed and controls. It asks you to gather an outcome, not to reproduce an answer already supplied here. It is optional. Write your own hypothesis before consulting the separate ghost-student results.
