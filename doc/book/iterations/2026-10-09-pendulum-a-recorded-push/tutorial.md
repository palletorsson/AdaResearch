# Keep the release; change the push

**Learning elements**

- A common initial state
- A saved force record
- Force projected onto a constrained direction
- Damping under matched input
- Replay and finite observation windows

The black point is familiar. In this bay it hangs from a rod. Pull either point sideways and let go: both begin from the angle you selected, with zero angular velocity. The depth of your hand movement and the speed of your throw are excluded. This makes a release that can be compared and repeated.

Start with **A: NO PUSH / B: RECORDED PUSH**. Only B receives the external force; both have the same damping. The push stops after four seconds. Watch the points continue. Their current angles and velocities retain consequences of the input even when its arrow disappears.

Press REPLAY. The input is a saved list, not another random draw. Increase FORCE and replay again: you changed the size of those same values. NEXT SEED replaces the list. These are different experiments.

Now press MODE. **SAME PUSH** sends the record to both points. A keeps its damping coefficient; B DRAG changes B. Make B equal to A before comparing a different value. Equal release, input and damping must produce equal states. That is the first useful test.

## What you bring

Keep the sphere class from Lines and Forces. Keep arrays from Trace, the update of velocity before position, and the distinction between local and world coordinates. This is an optional extension beside the hall's existing spring lesson. Waves later returns to the pendulum's sampled record; Randomness and Noise examine how the input values are generated. Here you can first treat the forty saved values as a supplied input.

We are working inside the existing Endless Museum. The code builds this small apparatus and its labels. The museum supplies its camera, room, player, installed XR Tools and shared ControlConsole. No prepared mesh children or unexplained dollar references are required. The public source paths below are part of this project; save the files there to reconstruct the same scene. Use the finished scene in a clear study bay at floor level and unit scale. It does not replace the larger spring or swing artifacts.

## The new relation

Angle and angular velocity are the moving state. A point at angle zero hangs below its pivot. The mass and rod length are fixed. Gravity contributes `-(g/L)*sin(angle)`. Tangential drag contributes `-(b/m)*angular_velocity`. A horizontal push contributes `F*cos(angle)/(m*L)`: its projection onto the direction the bob can move changes as it swings.

The model takes one fixed step of1/120s. It updates angular velocity, then angle. The rod's length follows from the position formula, so the model cannot pull it loose. This is an angular simulation with no contacts, not a Jolt hinge. The surrounding hall gives you other mechanisms to compare with it.

The saved force changes every twelve model ticks. Forty values last four seconds; the following sixteen seconds contain no external push. Sampling the state every fourth tick gives601 stored snapshots including the initial state. Recording less often changes the trace, not the update clock. Peak and settling measurements still inspect every step.

## Complete model — pendulum_pair.gd

Save as `commons/artifacts/pendulum_noise/pendulum_pair.gd`. The model owns the saved input, two states and their measurements. `reset()` restores their common start without drawing another input. `step()` reads the current force, advances the states and records what happened.

```gdscript
extends RefCounted
## Two angular pendulums, one recorded horizontal force. SI units; no contact solver.
const DT := 1.0 / 120.0
const LENGTH := 1.1
const MASS := 1.0
const GRAVITY := 9.8
const BASE_DRAG := 0.35 # kg/s; tangential drag = -b * speed
const FORCE_SECONDS := 4.0
const DURATION := 20.0
const SAMPLE_TICKS := 12 # one saved force sample per 0.1 s
const LAST_TICK := 2400
const ANGLE_LIMIT := PI / 3.0 # initial release control only
const ANGLE_TOLERANCE := PI / 90.0 # 2 degrees
const SPEED_TOLERANCE := 0.05 # rad/s
var noise_seed: int = 1847
var sigma_n := 2.0
var changed_drag := 1.2
var compare_damping := false
var initial_angle := 0.6
var unit_forces := PackedFloat64Array()
var angle := PackedFloat64Array([0.6, 0.6])
var omega := PackedFloat64Array([0.0, 0.0])
var peak := PackedFloat64Array([0.6, 0.6])
var last_outside := PackedFloat64Array([4.0, 4.0])
var tick := 0
var history: Array[Dictionary] = []

func _init() -> void:
	resample(noise_seed)

func resample(value: int) -> void:
	noise_seed = value
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	unit_forces.clear()
	for i in 40: unit_forces.append(rng.randfn())
	reset()

func reset() -> void:
	tick = 0
	angle = PackedFloat64Array([initial_angle, initial_angle])
	omega = PackedFloat64Array([0.0, 0.0])
	peak = PackedFloat64Array([absf(initial_angle), absf(initial_angle)])
	last_outside = PackedFloat64Array([FORCE_SECONDS, FORCE_SECONDS])
	history.clear()
	record()

func force_at(at_tick: int, lane: int) -> float:
	if at_tick < 0 or at_tick >= 480: return 0.0
	if lane == 0 and not compare_damping: return 0.0
	return unit_forces[at_tick / SAMPLE_TICKS] * sigma_n

func drag_for(lane: int) -> float:
	return changed_drag if lane == 1 and compare_damping else BASE_DRAG

func acceleration(theta: float, speed: float, force: float, drag: float) -> float:
	# A horizontal force projects onto the tangent through cos(theta).
	return -GRAVITY / LENGTH * sin(theta) - drag / MASS * speed + force * cos(theta) / (MASS * LENGTH)

func step() -> bool:
	if tick >= LAST_TICK: return false
	for lane in 2:
		omega[lane] += acceleration(angle[lane], omega[lane], force_at(tick, lane), drag_for(lane)) * DT
		angle[lane] += omega[lane] * DT
		peak[lane] = maxf(peak[lane], absf(angle[lane]))
	tick += 1
	var time := tick * DT
	if time >= FORCE_SECONDS:
		for lane in 2:
			if absf(angle[lane]) > ANGLE_TOLERANCE or absf(omega[lane]) > SPEED_TOLERANCE:
				last_outside[lane] = time
	if tick % 4 == 0: record()
	return true

func record() -> void:
	history.append({"time":tick * DT, "angles":angle.duplicate(), "speeds":omega.duplicate()})

func settled_at(lane: int) -> float:
	# Only report a terminal window after the finite run, with >= 1 s in tolerance.
	if tick < LAST_TICK or DURATION - last_outside[lane] < 1.0: return -1.0
	return last_outside[lane] + DT

func offset(lane: int) -> Vector3:
	return Vector3(LENGTH * sin(angle[lane]), -LENGTH * cos(angle[lane]), 0)

func energy(lane: int) -> float:
	return 0.5 * MASS * pow(LENGTH * omega[lane], 2) + MASS * GRAVITY * LENGTH * (1.0 - cos(angle[lane]))
```

## The inherited point — point_body.gd

This is the unchanged sphere, boundary and pickup class from the earlier lessons, at `doc/book/studies/forces-point-lineage/point_body.gd`. You already have it; its source is repeated here so the dependency is visible.

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

## Constrain the held point — angle_point.gd

Save beside the model. XR Tools first follows the hand. This extension then projects that position onto the permitted angle and restores the fixed rod length. Its late physics priority follows the same pattern as the museum's existing constrained mower and spring handle. The unheld point follows the model. Pickup and release keep their established meanings; throwing is deliberately disabled for this comparison.

```gdscript
extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## The existing point becomes a constrained release handle, not a thrown rigid body.
var apparatus: Node3D
var lane := 0

func _ready() -> void:
	super._ready()
	process_physics_priority = 100 # Project after XR Tools has moved the held point.

func _physics_process(_delta: float) -> void:
	if apparatus == null: return
	if is_picked_up(): apparatus.set_release_from_hand(lane, global_position)
	global_position = apparatus.bob_world(lane)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
```

## Make the comparison visible — PendulumNoise.gd

Save beside the model. The two rigs share construction and styling. Their state remains separate. The familiar ControlConsole supplies physical controls, explicitly loaded from `commons/ui/control_console.gd`; it is inherited museum infrastructure.

`_picked` gives one hand authority over the common release. `_dropped` starts both at rest. The physics callback accumulates model time in fixed steps. The process callback displays the current state and refreshes the bounded plot. Button and slider changes restart the comparison, while RUN/PAUSE preserves its state.

```gdscript
extends Node3D
## Paired angular model; each hand point sets a common release, never a throw.
const Model = preload("res://commons/artifacts/pendulum_noise/pendulum_pair.gd")
const Point = preload("res://commons/artifacts/pendulum_noise/angle_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
const HEIGHT := 2.35
var model = Model.new()
var points: Array = []
var pivots: Array[Node3D] = []
var arrows: Array[MeshInstance3D] = []
var arrowheads: Array[MeshInstance3D] = []
var buttons := {}
var sliders := {}
var console: Node3D
var readout: Label3D
var lane_labels: Array[Label3D] = []
var trace: MeshInstance3D
var input_trace: MeshInstance3D
var running := false
var held_lane := -1
var accumulator := 0.0
var discarded_wall_seconds := 0.0
var _ui_clock := 0.0
var _synchronizing := false
var _plot_key := ""
var log_entries: Array[Dictionary] = []

func _ready() -> void:
	name = "PendulumNoise"
	var black := material("171b23")
	black.metallic = 0.25; black.roughness = 0.18
	box(Vector3(0,.025,0),Vector3(6.6,.035,2.5),material("dbd7d0"))
	for x in [-3.1,3.1]: box(Vector3(x,1.22,0),Vector3(.065,2.44,.08),black)
	box(Vector3(0,2.44,0),Vector3(6.25,.07,.08),black)
	for lane in 2:
		var pivot := Node3D.new(); pivot.position = anchor(lane); add_child(pivot); pivots.append(pivot)
		var rod := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius = .008; mesh.bottom_radius = .008; mesh.height = Model.LENGTH
		rod.mesh = mesh; rod.material_override = black; rod.position.y = -Model.LENGTH/2
		pivot.add_child(rod)
		var point = Point.new(); point.apparatus = self; point.lane = lane
		point.name = "PointA" if lane == 0 else "PointB"
		point.gravity_scale = 0; point.collision_layer = 4; point.collision_mask = 0
		point.add_to_group("no_gravity_gun"); add_child(point); points.append(point)
		point.get_child(0).material_override = black
		point.picked_up.connect(_picked.bind(lane)); point.dropped.connect(_dropped.bind(lane))
		var arrow := box(Vector3.ZERO,Vector3(1,.022,.022),material("d770ab" if lane else "318897",true))
		arrows.append(arrow)
		var head := MeshInstance3D.new(); var cone := CylinderMesh.new()
		cone.top_radius=0; cone.bottom_radius=.045; cone.height=.12
		head.mesh=cone; head.material_override=arrow.material_override; add_child(head); arrowheads.append(head)
		lane_labels.append(plate("",Vector3((lane*2-1)*2.12,.90,.25),Vector2(1.85,.48),36,.0023))
	plate("THE SAME RELEASE / A RECORDED PUSH",Vector3(0,3.18,-.2),Vector2(6.3,.35),60,.0026)
	readout = plate("",Vector3(0,2.77,-.2),Vector2(6.3,.46),42,.0025)
	plate("PULL EITHER POINT · RELEASE BOTH\nAngular model / 1 kg / 1.1 m / no contacts",Vector3(0,.40,.25),Vector2(4.8,.34),38,.0024)
	box(Vector3(0,.075,-1.35),Vector3(6.2,.06,2.0),material("1e2936",true))
	trace = MeshInstance3D.new(); add_child(trace)
	input_trace = MeshInstance3D.new(); input_trace.material_override = material("f0d5a5",true); add_child(input_trace)
	plate("A BLUE / B ROSE · ANGLE 0–20 s, ±π\nGOLD: INPUT 0–4 s, ±12 N · plots clip, model does not",Vector3(0,.30,-2.2),Vector2(6.1,.3),32,.0023)
	console = Console.new(); console.auto_demo = false; console.face_to_origin = false
	console.body_height = .8; console.board_width = 2.25; console.position = Vector3(0,0,1.8)
	add_child(console); console.set_title("ONE COMPARISON AT A TIME")
	for spec in [["FORCE σ / 0–6 N","force"],["B DRAG / 0–3 kg/s","drag"]]:
		var slider = console.add_slider(spec[0],spec[1]); sliders[spec[1]] = slider
		slider.slider_moved.connect(_slider_changed.bind(spec[1]))
	for id in ["RUN / PAUSE","REPLAY","MODE","NEXT SEED","RESET"]:
		var button = console.add_button(id); buttons[id] = button; button.pressed.connect(act.bind(id))
	_sync_sliders(); draw_state(); draw_records(); _receipt("initial")

func anchor(lane: int) -> Vector3:
	return Vector3((lane*2-1)*1.55,HEIGHT,0)

func bob_world(lane: int) -> Vector3:
	return to_global(anchor(lane)+model.offset(lane))

func _picked(_point: Node3D, lane: int) -> void:
	held_lane = lane; running = false; accumulator = 0
	points[1-lane].enabled = false
	model.initial_angle = clampf(model.angle[lane],-Model.ANGLE_LIMIT,Model.ANGLE_LIMIT)
	model.reset(); draw_state()

func set_release_from_hand(lane: int, world: Vector3) -> void:
	if held_lane != lane: return
	var p := to_local(world)-anchor(lane)
	if Vector2(p.x,p.y).length()<.01: return
	model.initial_angle = clampf(atan2(p.x,-p.y),-Model.ANGLE_LIMIT,Model.ANGLE_LIMIT)
	model.reset()

func _dropped(_point: Node3D, lane: int) -> void:
	if lane != held_lane: return
	held_lane = -1; points[1-lane].enabled = true
	model.reset(); accumulator = 0; running = true
	_receipt("hand release; throw speed discarded")

func _physics_process(delta: float) -> void:
	if not running or held_lane >= 0: return
	if not is_finite(delta) or delta <= 0: return
	# At most .1 model seconds per callback; report dropped wall time, never jump state.
	discarded_wall_seconds += maxf(0,delta-.1)
	accumulator += minf(delta,.1)
	while accumulator >= Model.DT:
		accumulator -= Model.DT
		if not model.step():
			running = false; accumulator = 0; _receipt("finished"); break

func _process(delta: float) -> void:
	draw_state()
	_ui_clock += delta
	if _ui_clock >= .1:
		_ui_clock = 0; draw_records()

func _sync_sliders() -> void:
	_synchronizing = true
	sliders.force.set_normalized_value(model.sigma_n/6)
	sliders.drag.set_normalized_value(model.changed_drag/3)
	_synchronizing = false

func _slider_changed(_value: Variant, id: String) -> void:
	if _synchronizing or held_lane >= 0: return
	var value: float = sliders[id].get_normalized_value()
	if not is_finite(value): return
	if id == "force": model.sigma_n = clampf(value,0,1)*6
	else:
		model.changed_drag = clampf(value,0,1)*3
		model.compare_damping = true # A labelled comparison, not a hidden second change.
	restart(false); _receipt("parameter "+id)

func restart(play: bool) -> void:
	model.reset(); accumulator = 0; discarded_wall_seconds = 0; running = play
	draw_state(); draw_records()

func act(id: String) -> void:
	if held_lane >= 0: return
	match id:
		"RUN / PAUSE":
			if model.tick >= Model.LAST_TICK: restart(true)
			else: running = not running
		"REPLAY": restart(true)
		"MODE": model.compare_damping = not model.compare_damping; restart(false)
		"NEXT SEED":
			model.resample(0 if model.noise_seed == 9223372036854775807 else model.noise_seed+1)
			restart(false)
		"RESET":
			model.sigma_n=2; model.changed_drag=1.2; model.compare_damping=false; model.initial_angle=.6
			model.resample(1847); _sync_sliders(); restart(false)
	_receipt(id)

func draw_state() -> void:
	if readout == null: return
	for lane in 2:
		pivots[lane].rotation.z = model.angle[lane]
		if not points[lane].is_picked_up(): points[lane].global_position = bob_world(lane)
		var f: float = model.force_at(model.tick,lane)
		arrows[lane].visible = absf(f)>.01
		arrows[lane].scale.x = maxf(absf(f)*.12,.001)
		arrows[lane].position = anchor(lane)+model.offset(lane)+Vector3(f*.06,0,.19)
		arrowheads[lane].visible=arrows[lane].visible
		arrowheads[lane].position=anchor(lane)+model.offset(lane)+Vector3(f*.12,0,.19)
		arrowheads[lane].rotation.z=-PI/2 if f>0 else PI/2
		var settle: float = model.settled_at(lane)
		lane_labels[lane].text = ("%s · θ %.1f° · ω %.2f rad/s\nF %.2f N · peak %.1f°\nsettle %s") % ["A" if lane==0 else "B",rad_to_deg(model.angle[lane]),model.omega[lane],f,rad_to_deg(model.peak[lane]),"pending" if model.tick<Model.LAST_TICK else ("not in 20 s" if settle<0 else "%.2f s"%settle)]
	var comparison := "A: NO PUSH / B: RECORDED PUSH · both drag 0.35 kg/s"
	if model.compare_damping: comparison = "SAME PUSH · A drag 0.35 / B drag %.2f kg/s"%model.changed_drag
	readout.text = "%s\n%.2f / 20 s · %s · seed %d · σ %.2f N · wall time omitted %.2f s" % [comparison,model.tick*Model.DT,"PULLING" if held_lane>=0 else ("COMPLETE" if model.tick>=Model.LAST_TICK else ("RUNNING" if running else "READY / PAUSED")),model.noise_seed,model.sigma_n,discarded_wall_seconds]

func draw_records() -> void:
	var key := str([model.tick,model.noise_seed,model.sigma_n,model.compare_damping,model.changed_drag,model.initial_angle])
	if key==_plot_key: return
	_plot_key=key
	var lines := ImmediateMesh.new()
	for lane in 2:
		if model.history.size()<2: continue
		lines.surface_begin(Mesh.PRIMITIVE_LINES,material("d770ab" if lane else "50b4c4",true))
		for i in range(1,model.history.size()):
			for j in [i-1,i]:
				var p: Dictionary = model.history[j]
				lines.surface_add_vertex(Vector3(-2.8+5.6*p.time/20,.12, -1.6-clampf(p.angles[lane],-PI,PI)*.17))
		lines.surface_end()
	trace.mesh = lines
	var force_lines := ImmediateMesh.new()
	force_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 40:
		var x := -2.8+float(i)*5.6/40
		force_lines.surface_add_vertex(Vector3(x,.14,-.7))
		force_lines.surface_add_vertex(Vector3(x,.14,-.7-clampf(model.unit_forces[i]*model.sigma_n,-12,12)*.018))
	force_lines.surface_end(); input_trace.mesh=force_lines

func _receipt(event: String) -> void:
	log_entries.append({"event":event,"seed":model.noise_seed,"sigma_n":model.sigma_n,
		"mode":"same input/different drag" if model.compare_damping else "off/on",
		"changed_drag":model.changed_drag,"initial_angle":model.initial_angle,"tick":model.tick,
		"peak":model.peak.duplicate(),"settled_at":[model.settled_at(0),model.settled_at(1)],
		"engine":Engine.get_version_info().string,"dropped_wall_seconds":discarded_wall_seconds})
	if log_entries.size()>64: log_entries.pop_front()

func material(hex: String, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=Color(hex)
	if unshaded: m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var v := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v); return v

func plate(text: String, at: Vector3, size: Vector2, font: int, pixels: float) -> Label3D:
	var backing := box(at,Vector3(size.x,size.y,.035),material("25303d",true))
	var label := Label3D.new(); label.text=text; label.font_size=font; label.pixel_size=pixels
	label.position.z=.02; label.outline_size=0; label.modulate=Color("f4ebdf")
	backing.add_child(label); return label
```

## Scene wrapper — PendulumNoise.tscn

This root is all the scene needs; the scripts construct its contents. Open it within the Ada project or add it to your existing study bay. Camera and XR setup remain the museum's supplied environment.

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://commons/artifacts/pendulum_noise/PendulumNoise.gd" id="1"]

[node name="PendulumNoise" type="Node3D"]
script = ExtResource("1")
```

## Read the result, then make another case

The gold plot shows the saved input; blue and rose show the two angle histories. The input plot spans four seconds, while the angle plot spans twenty. Their vertical display limits are±12N and±πrad. These are drawing limits only. They do not clip the actual forcing, state or measurements. The force arrow uses0.12m per newton and shows the external push, not gravity or the total force.

The settling readout waits until the experiment ends. It asks whether, after the last violation following the cutoff, the state remained within2° and0.05rad/s for at least the final second. It describes the observed twenty seconds. A brief crossing through zero would not pass: a fast-moving point can be at the centre without being settled.

Try three cases before adding more machinery:

1. Set force strength to zero. Predict the two traces in OFF/ON, then compare them. The code must preserve equality.
2. In SAME INPUT set B drag to0.35kg/s, matching A. The two states should remain equal even with a strong push. Then change only B drag and replay.
3. Change the initial angle to zero in the model and set force strength to zero. Both states should remain at rest. This is a new case, not a reproduction of the opening swing.

The native checks execute these invariants and also compare the small-angle period against its numerical reference. Tests do not prove exact mechanics: the undamped integration shows a small energy discrepancy. A long engine callback advances at most0.1model seconds and reports omitted wall time. Nothing changes headset tracking or assumes that wall time and model time remain identical during a stall.

Gaussian values come from a local seeded generator. The sample is neither a bounded force distribution nor continuous ideal white noise. Generator details can change between engine versions; preserve the values as well as the seed for a durable experiment. [Godot4.6 RandomNumberGenerator](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html)

Run `python -X utf8 tools/test_pendulum_noise.py` for the model and control checks. The installed-room probe also uses the actual pointer and supplied XR pickup poses. The author-led tests do not certify a physical headset, Quest performance or an independent student's understanding.

What travels onward is a comparison you can reconstruct: common release, saved input, stated update, separate response. The later Noise study scales a saved displacement field instead. A navigator can eventually return to the same method with an imperfect observation; that changes where the disturbance enters the computation.
