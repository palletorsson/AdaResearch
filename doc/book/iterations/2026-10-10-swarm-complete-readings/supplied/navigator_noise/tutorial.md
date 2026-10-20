# The obstacle, the reading, the command

**Optional study inside Agent-Based Modeling · Endless Museum · G2**

**Learning elements**

- True state and observed state
- A decision threshold
- A missing value
- Stop or retain the previous command
- Replay and a defined outcome

The black point returns. Its position, trace and goal-directed movement are familiar. In the lower course it receives an accurate distance to the obstacle. In the upper course we alter that reading. The obstacles stay where they are. Press RUN and follow the point, then read the command beside its path.

Carry the point class, vectors, arrays, conditions and the saved-input comparison from earlier studies. This study adds a small decision boundary between **what is there, what is reported and what is done**. The existing colony remains this hall's primary encounter. The comparison does not reconstruct the colony, teach all of navigation or replace the earlier unfinished ABM tutorial.

## Keep the world; change the reading

Each course has a starting point at x = −1.65 m, a fixed circular obstacle of radius 0.25 m and a goal at (1.65, 0). The sphere radius is 0.14 m. Their surface clearance is the distance from the sphere centre to the obstacle centre, minus both radii. The lower and upper panels display identical model coordinates at different heights; height has no effect on the calculation.

The point initially moves towards the goal at 0.6 m/s. If its reported clearance is at most 0.5 m, it switches to three supplied waypoints around the obstacle. The green squares show the first two; the ring is the goal. These are authored waypoints, not a discovered route. Position and goal direction are known exactly. Only obstacle range is disturbed. The controller turns instantly; it is a kinematic example, not a force or inertia simulation.

In NOISE mode the upper reading is `truth + sigma_m * saved_error`. Forty independent Gaussian draws are saved once, each used for half a second. The sensor is evaluated every 0.05 s, so the **error**, not the true distance, stays constant within a block. A slider changes its scale in metres without drawing new values. Negative readings remain visible. A Gaussian marginal does not make this temporally held process white noise.

In MISSING mode a separate saved uniform draw decides whether each half-second block is absent. The slider now selects a fraction from 0 to 1. This is a probability per block, not a guarantee that precisely that fraction of one run is missing. An available reading is exact; Gaussian error is not mixed into this mode.

Missing is `null`. Zero would mean the surfaces are touching. With STOP, a missing reading produces a zero command. With HOLD, the previous velocity command continues unchanged, including its direction. Neither rule advances the waypoint state while the reading is absent. A point can therefore stop short of the deadline, hit the obstacle, or continue past a turn and leave the course. Those are distinct outcomes.

## Operate the existing study

Press RUN / PAUSE or pull the **lower** point slightly up/down and release. This chooses one common start height, limited to ±0.15 m. Its horizontal and depth movement are constrained; throwing speed is not part of the experiment. The upper point cannot be grabbed separately. All comparisons begin at rest with the same coordinates.

REPLAY restores both agents while retaining the input record. MODE separates range noise from missing readings. FALLBACK chooses STOP/HOLD and explicitly selects missing mode. NEXT SEED creates another record. RESET restores seed1847, sigma0.5 m, missing fraction0.65, STOP and the original release. Changing a setting pauses and resets the paths so the next comparison has a clear beginning.

The readout records the last decision: true clearance before that step, reported clearance, command in m/s, elapsed simulation time and path length. At a terminal state the command is the last requested command; the point has stopped. A green arrow shows an active command. Blue/rose traces contain the actual travelled positions.

Success means reaching the goal within20 simulated seconds without contact or leaving the outlined course. Collision checks the whole movement segment against the obstacle expanded by the sphere radius. This can detect a crossing between endpoints; it is an analytic disc test, not an invisible physics wall. Contact and exit stop at their first boundary. Time is reported at the end of the 0.05 s decision step, so a contact time is quantised to that clock. The experiment stops when both points finish, or at20s. An engine stall can slow the experiment: each callback accepts at most0.1 simulated seconds and reports omitted wall time. It never accelerates the player or alters headset timing.

## Reconstruct inside the museum

Use the prepared Ada project and the declared paths below. The museum supplies the player, camera, lighting, XR Tools and `commons/ui/control_console.gd`. These are the Day Zero host, not new tasks. The point class is carried unchanged; it is printed for completeness. The model, constrained handle, stage and tiny scene wrapper are new. The stage creates its meshes, labels and controls. It has no reference to an unexplained prepared mesh.

Run the wrapper under that host, or attach the stage script to an empty Node3D in a clear museum work area. Do not duplicate the placed exhibit on top of itself. To transplant the code outside Ada, those named host dependencies must also be supplied.

The model separates three functions to read closely: `distance_at` defines the measured variable, `reading` intervenes on it, and `decision` chooses an action. The state list stores where each agent is in the detour. History stores new dictionaries with value-type vectors, so a later update cannot rewrite an earlier step.

## navigation_pair.gd

Save as `res://commons/artifacts/navigator_noise/navigation_pair.gd`.

```gdscript
extends RefCounted
## A fixed two-dimensional course. Noise changes range, not geometry or waypoints.
const DT := 0.05
const LAST_TICK := 400
const SPEED := 0.6
const RADIUS := 0.14
const OBSTACLE_RADIUS := 0.25
const CLEARANCE := 0.5
const START_X := -1.65
const GOAL := Vector2(1.65,0)
const WAYPOINTS := [Vector2(-.65,.65),Vector2(.65,.65),GOAL]
const COURSE_MIN := Vector2(-1.85,-.18)
const COURSE_MAX := Vector2(1.85,.8)
const TERMINAL := ["GOAL","CONTACT","LEFT COURSE","TIMEOUT"]
var sample_seed := 1847
var sigma_m := .5
var dropout := .65
var missing_mode := false
var hold_command := false
var start_y := 0.0
var unit_noise := PackedFloat64Array()
var uniforms := PackedFloat64Array()
var tick := 0
var positions: Array[Vector2] = []
var commands: Array[Vector2] = []
var stages: Array[int] = [] # -1: approach goal; 0,1,2: detour waypoints.
var observations: Array = [] # A missing reading is null, never a numeric distance.
var sensed_true: Array[float] = []
var outcomes: Array[String] = []
var elapsed: Array[float] = []
var lengths: Array[float] = []
var history: Array[Dictionary] = []

func _init() -> void:
	resample(sample_seed); reset()

func resample(value: int) -> void:
	sample_seed=value
	var rng := RandomNumberGenerator.new(); rng.seed=sample_seed
	unit_noise.clear(); uniforms.clear()
	# Forty half-second blocks. Each has one saved range error and dropout draw.
	for i in 40:
		unit_noise.append(rng.randfn()); uniforms.append(rng.randf())

func reset() -> void:
	tick=0; positions=[Vector2(START_X,start_y),Vector2(START_X,start_y)]
	commands=[Vector2.ZERO,Vector2.ZERO]; stages=[-1,-1]
	observations=[null,null]; sensed_true=[distance_at(positions[0]),distance_at(positions[1])]
	outcomes=["READY","READY"]; elapsed=[0.0,0.0]; lengths=[0.0,0.0]; history.clear()

func distance_at(p: Vector2) -> float:
	return p.length()-OBSTACLE_RADIUS-RADIUS # Surface-to-surface clearance, metres.

func reading(lane: int, t: int, truth: float) -> Variant:
	if lane==0: return truth
	var block := mini(t/10,39)
	if missing_mode: return null if uniforms[block]<dropout else truth
	return truth+sigma_m*unit_noise[block] # Negative observations remain visible.

func decision(p: Vector2, stage: int, observed: Variant, previous: Vector2) -> Dictionary:
	if observed==null:
		return {"stage":stage,"command":previous if hold_command else Vector2.ZERO,"reason":"HOLD" if hold_command else "STOP"}
	if stage<0 and float(observed)<=CLEARANCE: stage=0
	if stage>=0 and stage<2 and p.distance_to(WAYPOINTS[stage])<.001: stage+=1
	var target: Vector2 = GOAL if stage<0 else WAYPOINTS[stage]
	var command := (target-p).limit_length(SPEED*DT)/DT
	return {"stage":stage,"command":command,"reason":"SEEK" if stage<0 else "DETOUR %d"%stage}

func contact_fraction(a: Vector2, b: Vector2) -> float:
	# Swept point versus expanded disc: first contact, including between endpoints.
	var radius := OBSTACLE_RADIUS+RADIUS
	var c := a.length_squared()-radius*radius
	if c<=0: return 0.0
	var d := b-a; var aa := d.length_squared()
	if aa<1e-16: return -1.0
	var bb := 2*a.dot(d); var discriminant := bb*bb-4*aa*c
	if discriminant<0: return -1.0
	var fraction := (-bb-sqrt(discriminant))/(2*aa)
	return fraction if fraction>=0 and fraction<=1 else -1.0

func finished() -> bool:
	return tick>=LAST_TICK or (outcomes[0] in TERMINAL and outcomes[1] in TERMINAL)

func exit_fraction(a: Vector2,b: Vector2) -> float:
	var fraction := 2.0
	for axis in 2:
		if b[axis]>COURSE_MAX[axis]: fraction=minf(fraction,(COURSE_MAX[axis]-a[axis])/(b[axis]-a[axis]))
		if b[axis]<COURSE_MIN[axis]: fraction=minf(fraction,(COURSE_MIN[axis]-a[axis])/(b[axis]-a[axis]))
	return fraction if fraction<=1 else -1.0

func step() -> bool:
	if finished(): return false
	var rows: Array[Dictionary]=[]
	for lane in 2:
		if outcomes[lane] in TERMINAL:
			rows.append({"inactive":true}); continue
		var before := positions[lane]
		# The sensor is read every simulation step; its recorded error is held .5s.
		sensed_true[lane]=distance_at(before)
		observations[lane]=reading(lane,tick,sensed_true[lane])
		var result := decision(before,stages[lane],observations[lane],commands[lane])
		stages[lane]=result.stage; commands[lane]=result.command
		var next := before+commands[lane]*DT
		var fraction := contact_fraction(before,next)
		var exit := exit_fraction(before,next)
		outcomes[lane]=result.reason
		if exit>=0 and (fraction<0 or exit<fraction):
			next=before.lerp(next,exit); outcomes[lane]="LEFT COURSE"
		elif fraction>=0:
			next=before.lerp(next,fraction); outcomes[lane]="CONTACT"
		positions[lane]=next; lengths[lane]+=before.distance_to(next)
		elapsed[lane]=(tick+1)*DT
		if outcomes[lane] not in TERMINAL and next.distance_to(GOAL)<.001: outcomes[lane]="GOAL"
		if tick+1==LAST_TICK and outcomes[lane] not in TERMINAL: outcomes[lane]="TIMEOUT"
		rows.append({"from":before,"to":next,"true":sensed_true[lane],"observed":observations[lane],"command":commands[lane],"stage":stages[lane],"outcome":outcomes[lane]})
	# New dictionaries and value-type vectors: old records do not alias current state.
	history.append({"time":tick*DT,"lanes":rows}); tick+=1
	return true
```

## point_body.gd

Save as `res://doc/book/studies/forces-point-lineage/point_body.gd`.

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

## start_point.gd

Save as `res://commons/artifacts/navigator_noise/start_point.gd`.

```gdscript
extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## Reuse the earlier point as a constrained starting-position handle.
var apparatus: Node3D
var lane := 0
func _ready() -> void:
	super._ready(); process_physics_priority=100
func _physics_process(_delta: float) -> void:
	if apparatus==null: return
	if lane==0 and is_picked_up(): apparatus.start_from_hand(global_position)
	global_position=apparatus.agent_world(lane)
	linear_velocity=Vector3.ZERO; angular_velocity=Vector3.ZERO
```

## NavigatorNoise.gd

Save as `res://commons/artifacts/navigator_noise/NavigatorNoise.gd`.

```gdscript
extends Node3D
## Two views of the same small course; bottom A point sets both starting heights.
const Model = preload("res://commons/artifacts/navigator_noise/navigation_pair.gd")
const StartPoint = preload("res://commons/artifacts/navigator_noise/start_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
var model = Model.new()
var points: Array = []
var labels: Array[Label3D] = []
var commands: Array[MeshInstance3D] = []
var heads: Array[MeshInstance3D] = []
var status: Label3D
var trace: MeshInstance3D
var buttons := {}
var slider: Node3D
var console: Node3D
var running := false
var held := false
var accumulator := 0.0
var omitted_wall_seconds := 0.0
var synchronizing := false
var plot_tick := -1
var plot_clock := 0.0

func _ready() -> void:
	name="NavigatorNoise"
	var black := material("151b25"); black.roughness=.16; black.metallic=.25
	box(Vector3(0,2.28,-.13),Vector3(4.35,4.46,.16),material("253340",true))
	for lane in 2:
		var base := base_height(lane)
		box(Vector3(0,base+.20,-.025),Vector3(4.08,1.20,.03),material("e5e0d6"))
		var obstacle := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius=Model.OBSTACLE_RADIUS; mesh.bottom_radius=Model.OBSTACLE_RADIUS; mesh.height=.22
		obstacle.mesh=mesh; obstacle.material_override=material("4c5664"); obstacle.rotation.x=PI/2
		obstacle.position=display(Vector2.ZERO,lane); add_child(obstacle)
		var goal := MeshInstance3D.new(); var ring := TorusMesh.new()
		ring.inner_radius=.10; ring.outer_radius=.15; ring.rings=24; ring.ring_segments=8
		goal.mesh=ring; goal.material_override=material("328370",true); goal.rotation.x=PI/2
		goal.position=display(Model.GOAL,lane); add_child(goal)
		var point = StartPoint.new(); point.apparatus=self; point.lane=lane
		point.name="ReferencePoint" if lane==0 else "ObservedPoint"
		point.collision_mask=0; point.enabled=lane==0; point.add_to_group("no_gravity_gun")
		add_child(point); point.get_child(0).material_override=black; points.append(point)
		if lane==0:
			point.picked_up.connect(_picked); point.dropped.connect(_dropped)
		labels.append(plate("",Vector3(0,base-.40,.04),Vector2(4.08,.40),34,.0022))
		commands.append(box(Vector3.ZERO,Vector3(.3,.025,.025),material("328370",true)))
		var head:=MeshInstance3D.new(); var cone:=CylinderMesh.new()
		cone.top_radius=0; cone.bottom_radius=.045; cone.height=.10
		head.mesh=cone; head.material_override=commands[-1].material_override; add_child(head); heads.append(head)
		# The authored detour is visible from the beginning, not discovered by the agent.
		for p in Model.WAYPOINTS.slice(0,2):
			box(display(p,lane),Vector3(.035,.035,.035),material("328370",true))
		for y in [Model.COURSE_MIN.y,Model.COURSE_MAX.y]: box(display(Vector2(0,y),lane),Vector3(3.70,.007,.008),material("7d827c",true))
		for x in [Model.COURSE_MIN.x,Model.COURSE_MAX.x]: box(display(Vector2(x,.31),lane),Vector3(.007,.98,.008),material("7d827c",true))
	plate("THE OBSTACLE / THE READING / THE COMMAND",Vector3(0,4.30,0),Vector2(4.22,.32),44,.0020)
	status=plate("",Vector3(0,3.98,.04),Vector2(4.22,.30),32,.0021)
	plate("A LOWER · ACCURATE     B UPPER · INTERVENED\nPull A up/down, release both · same goal and detour",Vector3(0,.28,.03),Vector2(4.22,.34),32,.0020)
	trace=MeshInstance3D.new(); add_child(trace)
	console=Console.new(); console.auto_demo=false; console.face_to_origin=false
	console.body_height=.60; console.board_width=2.3; console.position=Vector3(0,0,1.0)
	add_child(console); console.set_title("COMPARE WHAT THE POINT RECEIVES")
	slider=console.add_slider("STRENGTH: σ METRES / MISSING FRACTION","strength")
	slider.slider_moved.connect(_strength_changed)
	for id in ["RUN / PAUSE","REPLAY","MODE","FALLBACK","NEXT SEED","RESET"]:
		var b=console.add_button(id); buttons[id]=b; b.pressed.connect(act.bind(id))
	_sync(); draw_state()

func base_height(lane: int) -> float: return 1.45+lane*1.40
func display(p: Vector2,lane: int) -> Vector3: return Vector3(p.x,p.y+base_height(lane),.16)
func agent_world(lane: int) -> Vector3: return to_global(display(model.positions[lane],lane))

func _picked(_point: Node3D) -> void:
	held=true; running=false; accumulator=0
	model.reset(); plot_tick=-1

func start_from_hand(world: Vector3) -> void:
	if not held: return
	model.start_y=clampf(to_local(world).y-base_height(0),-.15,.15)
	model.reset(); plot_tick=-1

func _dropped(_point: Node3D) -> void:
	held=false; restart(true)

func _physics_process(delta: float) -> void:
	if not running or held or not is_finite(delta) or delta<=0: return
	omitted_wall_seconds+=maxf(0,delta-.1); accumulator+=minf(delta,.1)
	while accumulator+1e-10>=Model.DT:
		accumulator-=Model.DT
		if not model.step() or model.finished(): running=false; accumulator=0; break

func _process(delta: float) -> void:
	draw_state(); plot_clock+=delta
	if plot_clock>=.1: plot_clock=0; draw_trace()

func restart(play: bool) -> void:
	model.reset(); accumulator=0; omitted_wall_seconds=0; running=play; plot_tick=-1
	draw_state(); draw_trace()

func _sync() -> void:
	synchronizing=true
	slider.set_normalized_value(model.dropout if model.missing_mode else model.sigma_m/.8)
	synchronizing=false

func _strength_changed(_value: Variant) -> void:
	if synchronizing: return
	var value: float=slider.get_normalized_value()
	if model.missing_mode: model.dropout=value
	else: model.sigma_m=value*.8
	restart(false)

func act(id: String) -> void:
	if held: return
	match id:
		"RUN / PAUSE":
			if model.finished(): restart(true)
			else: running=not running
		"REPLAY": restart(true)
		"MODE": model.missing_mode=not model.missing_mode; _sync(); restart(false)
		"FALLBACK": model.hold_command=not model.hold_command; model.missing_mode=true; _sync(); restart(false)
		"NEXT SEED": model.resample(0 if model.sample_seed==9223372036854775807 else model.sample_seed+1); restart(false)
		"RESET":
			model.sigma_m=.5; model.dropout=.65; model.missing_mode=false; model.hold_command=false; model.start_y=0
			model.resample(1847); _sync(); restart(false)

func draw_state() -> void:
	if status==null: return
	for lane in 2:
		if not points[lane].is_picked_up(): points[lane].global_position=agent_world(lane)
		var command: Vector2=model.commands[lane]
		commands[lane].visible=command.length()>.001 and not model.outcomes[lane] in Model.TERMINAL
		commands[lane].position=display(model.positions[lane]+command*.25,lane)+Vector3(0,0,.18)
		commands[lane].rotation.z=command.angle(); commands[lane].scale.x=maxf(.001,command.length()/.6)
		heads[lane].visible=commands[lane].visible
		heads[lane].position=display(model.positions[lane]+command*.5,lane)+Vector3(0,0,.18)
		heads[lane].rotation.z=command.angle()-PI/2
		var observed: String="not sampled" if model.tick==0 else ("MISSING" if model.observations[lane]==null else "%.2f m"%model.observations[lane])
		labels[lane].text="%s · sample true %.2f m / read %s\n%s · cmd (%.2f, %.2f) m/s · %.2f s / %.2f m"%["A" if lane==0 else "B",model.sensed_true[lane],observed,model.outcomes[lane],command.x,command.y,model.elapsed[lane],model.lengths[lane]]
	var mode: String="MISSING %.0f%% · %s"%[100*model.dropout,"HOLD command" if model.hold_command else "STOP"] if model.missing_mode else "RANGE NOISE σ %.2f m"%model.sigma_m
	status.text="%s · seed %d\n%s · %.2f/20 s · omitted wall time %.2f s"%[mode,model.sample_seed,"PULLING" if held else ("RUNNING" if running else ("FINISHED" if model.finished() else "READY / PAUSED")),model.tick*Model.DT,omitted_wall_seconds]

func draw_trace() -> void:
	if plot_tick==model.tick: return
	plot_tick=model.tick
	var mesh:=ImmediateMesh.new()
	for lane in 2:
		if model.history.is_empty(): continue
		mesh.surface_begin(Mesh.PRIMITIVE_LINES,material("cb728b" if lane else "258b9c",true))
		for row in model.history:
			var entry: Dictionary=row.lanes[lane]
			if entry.has("inactive"): continue
			mesh.surface_add_vertex(display(entry.from,lane)+Vector3(0,0,.015))
			mesh.surface_add_vertex(display(entry.to,lane)+Vector3(0,0,.015))
		mesh.surface_end()
	trace.mesh=mesh

func material(hex: String, unshaded := false) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(hex)
	if unshaded: m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
func box(at: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var v:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v); return v
func plate(text: String,at: Vector3,size: Vector2,font: int,pixels: float) -> Label3D:
	var backing:=box(at,Vector3(size.x,size.y,.025),material("253340",true))
	var label:=Label3D.new(); label.text=text; label.font_size=font; label.pixel_size=pixels
	label.position.z=.02; label.outline_size=0; label.modulate=Color("f3eddf"); backing.add_child(label); return label
```

## NavigatorNoise.tscn

Save as `res://commons/artifacts/navigator_noise/NavigatorNoise.tscn`.

```ini
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://commons/artifacts/navigator_noise/NavigatorNoise.gd" id="1"]
[node name="NavigatorNoise" type="Node3D"]
script = ExtResource("1")
```

## Predict a different case

Set noise strength to zero. Both full histories should match, not merely their final pictures. Set missing fraction to zero and expect the same result. Set it to one with STOP: the upper point should remain at the start and time out, while the lower reaches the goal. Now raise the shared start by0.15m, replay and check whether your account of clearance still holds.

For a code experiment, retain one correct reading at the start and then make every subsequent block missing. Predict the difference between STOP and HOLD before running. The native tests perform this independent input case: HOLD makes contact, STOP times out without contact. They also test a deliberately overestimated range, a negative reading, a swept crossing and a course exit. A separate mutation check rejects replacing missing with zero.

Do not infer that noise is helpful or harmful from one seed. In the ten recorded seeds1847–1856 at sigma0.5 m, all upper agents reach the goal; some take a shorter path than the conservative accurate-distance route. That does not establish optimality or robustness. Under the same numbered dropout records with HOLD, some make contact, some leave the course and one reaches the goal. This is a small declared fixture set, not an estimated population failure rate.

You leave with a point, a record and a distinction: a changed action can follow from changed information while geometry and policy remain unchanged. A later Machine Learning lesson can change a policy explicitly. Nothing in this study trains, learns or adapts its rule.

The record can be replayed on this engine build. For durable replay across versions, preserve the actual saved noise and uniform arrays as well as the seed, settings and source revision. The review exports both arrays; it does not promise identical RNG output across Godot versions.
