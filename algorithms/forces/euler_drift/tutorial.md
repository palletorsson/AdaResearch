# The same throw, different steps

**Optional comparison in VFM_05_Launch.** Keep the launch lesson first: give the point an initial velocity and calculate its flight. Here the force, beginning and elapsed time stay fixed. Change how often the calculation updates.

## Learning elements

- Explicit Euler integration
- Simulation step and render frame
- Position before velocity: update order
- Signed error against a stated reference
- A bounded, replayable trace

## Carry the point

We are still inside Endless Museum. Carry `point_body.gd` from the earlier point lesson. Its sphere and scene construction stay the same. For these two calculated markers, disable pickup and collisions: our code sets their positions. The supplied museum player and ControlConsole provide the hand slider and buttons. They are Day Zero infrastructure, not new systems to reconstruct here.

The first launch exercise used gravity 10 m/s² and stopped on return to the starting height. This separate comparison uses gravity 9.8 m/s² and a fixed **one second**, even when another launch has not landed. State those conditions before comparing results.

## Try the calculation

Press FIRE. Amber follows the constant-acceleration formula; blue takes ten explicit steps. Both receive the same initial velocity `(4, 4.9, 0)` m/s. Move the slider to 20, then 40. Changing the step resets and pauses the pair; FIRE starts it. ONE STEP advances one interval. REPLAY restores the same beginning. OTHER THROW uses `(3, 6, 0)` without changing gravity or the duration.

Each square is one metre. Both trajectories occupy the same plane, so their visible displacement is their calculated difference. At the shared start you see one point. With small error the two sphere markers partly overlap; the readout gives the distance between their centres.

## The operation

In `step()`, the point first travels at its **old velocity** for `h` seconds. Only then does gravity change that velocity. The next step uses the changed velocity. Reversing these statements gives another integration method.

The reference calculates position directly from the start, initial velocity and constant acceleration. It is exact for this stated mathematical model; it is not a claim about air resistance, impact, or the engine's rigid bodies. At a matching time, subtract the reference position from the stepped position. Preserve the sign: here positive y means the stepped point is above the reference.

`count` divides the one-second journey. An integer `tick` counts completed steps, so `time()` is `tick * h`. `advance()` accumulates elapsed time and runs as many fixed steps as are due. Rendering can happen between them. A slow frame can display fewer intermediate states without changing the calculation. This short run contains at most 40 steps; it does not need an unbounded catch-up loop.

`history()` returns a copy. A later reader can inspect or alter its copy without changing the recorded flight. The first row is the starting state; 40 steps therefore produce 41 rows.

## Complete model — step_model.gd

Path: `algorithms/forces/euler_drift/step_model.gd`

```gdscript
extends RefCounted
## Explicit Euler beside a constant-acceleration reference. Metres and seconds.
const DURATION := 1.0
const COUNTS := [10, 20, 40]
var start := Vector3(-2, .75, 0)
var initial_velocity := Vector3(4, 4.9, 0)
var gravity := Vector3(0, -9.8, 0)
var count := 10
var tick := 0
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var credit := 0.0
var _history: Array[Dictionary] = []

func _init() -> void: reset()
func h() -> float: return DURATION / count
func time() -> float: return tick * h()
func finished() -> bool: return tick == count
func reference_at(t: float) -> Vector3:
	return start + initial_velocity*t + .5*gravity*t*t
func difference() -> Vector3: return position-reference_at(time())
func snapshot() -> Dictionary:
	return {"tick":tick,"time":time(),"position":position,"velocity":velocity,"reference":reference_at(time()),"difference":difference()}
func history() -> Array[Dictionary]: return _history.duplicate(true)
func reset() -> void:
	tick=0; credit=0; position=start; velocity=initial_velocity
	_history=[snapshot()]
func choose_steps(value: int) -> bool:
	if not value in COUNTS: return false
	count=value; reset(); return true
func step() -> bool:
	if finished(): return false
	position += velocity*h()
	velocity += gravity*h()
	tick += 1
	_history.append(snapshot())
	return true
func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds<=0 or finished(): return
	# The entire run is at most forty steps, even after a long render frame.
	credit += minf(seconds,DURATION)
	while credit+1e-9>=h() and not finished():
		credit -= h(); step()
	if finished(): credit=0
```

## Carried class — point_body.gd

This is the unchanged class from the earlier lesson, included so the dependency is explicit. The stage below creates both instances with `Point.new()`.

Path: `doc/book/studies/forces-point-lineage/point_body.gd`

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

## Carry behaviour into the display — display_point.gd

The inherited point keeps its original sphere. This small extension projects the model position each physics frame, also while the comparison is paused. It adds no force or new geometry. `lane` chooses the formula or stepped position.

Path: `algorithms/forces/euler_drift/display_point.gd`

```gdscript
extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## The earlier sphere projects a calculated state, including while paused.
var apparatus: Node3D
var lane := 0
func _ready() -> void:
	super._ready(); process_physics_priority=101
func _physics_process(_delta: float) -> void:
	if apparatus==null: return
	var p: Vector3=apparatus.model.reference_at(apparatus.model.time()) if lane==0 else apparatus.model.position
	global_position=apparatus.to_global(apparatus.display(p,lane))
	# At the shared start, show one point rather than two coincident surfaces.
	visible=lane==1 or apparatus.model.tick>0
	linear_velocity=Vector3.ZERO; angular_velocity=Vector3.ZERO
```

## Museum display and controls — step_study.gd

The full companion script below creates the board, labels, traces, two points and controls. The learning change is in the model above; this display is supplied scaffolding you can inspect. It contains no hidden scene-node references. Physics frames only deliver elapsed time and project the model positions onto the existing point bodies; no force is applied to the player.

Path: `algorithms/forces/euler_drift/step_study.gd`

```gdscript
extends Node3D
## Optional launch-hall comparison; no changes to the engine physics clock.
const Model = preload("res://algorithms/forces/euler_drift/step_model.gd")
const Point = preload("res://algorithms/forces/euler_drift/display_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
var model = Model.new()
var points: Array = []
var buttons := {}
var slider: Node3D
var console: Node3D
var status: Label3D
var trace: MeshInstance3D
var reference_path: MeshInstance3D
var running := false
var syncing := false
var last_tick := -1

func _ready() -> void:
	name="StepStudy"
	box(Vector3(0,2.10,-.12),Vector3(5.3,4.15,.16),material("243440"),true)
	box(Vector3(0,1.95,-.025),Vector3(4.9,2.8,.025),material("ede7db"))
	for x in range(-2,3): box(Vector3(x,1.95,0),Vector3(.008,2.8,.008),material("b9b3aa"))
	for y in range(1,4): box(Vector3(0,y,0),Vector3(4.9,.008,.008),material("b9b3aa"))
	label("THE SAME THROW / DIFFERENT STEPS",Vector3(0,3.93,.02),.0020)
	status=label("",Vector3(0,3.48,.03),.0018)
	label("AMBER: formula   BLUE: position first, then velocity\n1 square = 1 metre / both stop at 1 second",Vector3(0,2.98,.04),.0015).modulate=Color("243440")
	trace=MeshInstance3D.new(); add_child(trace)
	reference_path=MeshInstance3D.new(); add_child(reference_path)
	for i in 2:
		var point=Point.new(); point.name="FormulaPoint" if i==0 else "SteppedPoint"
		point.apparatus=self; point.lane=i
		point.enabled=false; point.collision_layer=0; point.collision_mask=0
		point.add_to_group("no_gravity_gun"); add_child(point)
		point.get_child(0).material_override=material("c47b22" if i==0 else "207890")
		points.append(point)
	console=Console.new(); console.auto_demo=false; console.face_to_origin=false
	console.body_height=.6; console.board_width=2.4; console.position=Vector3(0,0,1.25)
	add_child(console); console.set_title("KEEP THE THROW / CHANGE THE INTERVAL")
	slider=console.add_slider("STEPS PER SECOND: 10 / 20 / 40","steps")
	slider.slider_moved.connect(_step_changed)
	for id in ["FIRE / PAUSE","ONE STEP","REPLAY","OTHER THROW","RESET"]:
		var button=console.add_button(id); buttons[id]=button; button.pressed.connect(act.bind(id))
	process_physics_priority=100
	restart(false); sync_slider()

func display(p: Vector3, _lane: int) -> Vector3:
	# Both paths share one plane, preserving their difference from every angle.
	return Vector3(p.x,p.y,.16)
func _physics_process(delta: float) -> void:
	if running:
		model.advance(delta)
		if model.finished(): running=false
	for lane in 2:
		var p: Vector3=model.reference_at(model.time()) if lane==0 else model.position
		points[lane].global_position=to_global(display(p,lane))
		points[lane].linear_velocity=Vector3.ZERO; points[lane].angular_velocity=Vector3.ZERO
	draw_state()
func restart(play: bool) -> void:
	model.reset(); running=play; last_tick=-1
	var samples: Array[Vector3]=[]
	for i in 81: samples.append(display(model.reference_at(float(i)/80),0))
	reference_path.mesh=path_mesh(samples,material("c47b22"))
	draw_state()
func sync_slider() -> void:
	syncing=true; slider.set_normalized_value(float(Model.COUNTS.find(model.count))/2); syncing=false
func _step_changed(_value: Variant) -> void:
	if syncing: return
	var i:=clampi(roundi(slider.get_normalized_value()*2),0,2)
	model.choose_steps(Model.COUNTS[i]); restart(false)
func act(id: String) -> void:
	match id:
		"FIRE / PAUSE":
			if model.finished(): restart(true)
			else: running=not running
		"ONE STEP": running=false; model.credit=0; model.step()
		"REPLAY": restart(true)
		"OTHER THROW":
			model.initial_velocity=Vector3(3,6,0) if model.initial_velocity.x==4 else Vector3(4,4.9,0)
			restart(false)
		"RESET":
			model.initial_velocity=Vector3(4,4.9,0); model.choose_steps(10); restart(false); sync_slider()
	draw_state()
func draw_state() -> void:
	if status==null: return
	status.text="h = %.3f s / %d steps    t = %.3f / 1.000 s\nv0 = (%.1f, %.1f) m/s    Δy = %+.4f m    %s"%[model.h(),model.count,model.time(),model.initial_velocity.x,model.initial_velocity.y,model.difference().y,"RUNNING" if running else ("FINISHED" if model.finished() else "READY / PAUSED")]
	if last_tick==model.tick: return
	last_tick=model.tick
	var samples: Array[Vector3]=[]
	for row in model.history(): samples.append(display(row.position,1))
	trace.mesh=path_mesh(samples,material("207890"),true)
func path_mesh(samples: Array[Vector3],mat: Material,marks:=false) -> ImmediateMesh:
	var mesh:=ImmediateMesh.new()
	if samples.size()<2: return mesh
	# A flat trace must remain visible from both sides of its display plane.
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,mat)
	for i in range(1,samples.size()):
		var a:=samples[i-1];var b:=samples[i]
		var side:=Vector3(-(b-a).y,(b-a).x,0).normalized()*.009
		for v in [a-side,b-side,b+side,a-side,b+side,a+side]:mesh.surface_add_vertex(v)
		if marks:
			for v in [b+Vector3(-.025,-.025,0),b+Vector3(.025,-.025,0),b+Vector3(.025,.025,0),b+Vector3(-.025,-.025,0),b+Vector3(.025,.025,0),b+Vector3(-.025,.025,0)]:mesh.surface_add_vertex(v)
	mesh.surface_end(); return mesh
func material(hex: String) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(hex); m.roughness=.35
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; return m
func box(at: Vector3,size: Vector3,mat: Material,solid:=false) -> void:
	var v:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v)
	if solid:
		var body:=StaticBody3D.new(); body.position=at; add_child(body)
		var c:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; c.shape=shape; body.add_child(c)
func label(text: String,at: Vector3,pixels: float) -> Label3D:
	var l:=Label3D.new(); l.text=text; l.position=at; l.font_size=40; l.pixel_size=pixels
	l.outline_size=0; l.modulate=Color("f3eddf"); add_child(l); return l
```

## Scene — step_study.tscn

Save the files at their printed repository paths. Add this scene to an available place in your existing museum host, or visit the installed comparison in Launch. The museum supplies camera, lighting, player and input. Running this scene alone would omit that host. No new player or XR installation is part of this lesson.

Path: `algorithms/forces/euler_drift/step_study.tscn`

```ini
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://algorithms/forces/euler_drift/step_study.gd" id="1"]
[node name="StepStudy" type="Node3D"]
script = ExtResource("1")
```

## Predict, change, check

At the end of one second, explicit Euler differs from the formula by `-0.5 * gravity * T * h`. With downward gravity this is an upward difference. Halving the interval halves that difference for this constant-acceleration fixture.

| Steps | h (seconds) | Final difference, y (metres) |
|---|---|---|
| 10 | 0.100 | +0.4900 |
| 20 | 0.050 | +0.2450 |
| 40 | 0.025 | +0.1225 |

Try OTHER THROW. Predict the endpoint: `(-2, .75, 0) + (3, 6, 0) + (0, -4.9, 0) = (1, 1.85, 0)`. The flight changes; the same-step error remains unchanged because this fixture's error depends on acceleration, duration and interval, not initial velocity.

Then make your own variation in the model, outside the display's fixed framing: start `(2, 1, 0)`, velocity `(-3, 7, 0)`, gravity `(1, -6, 0)`, 20 steps. The reference endpoint should be `(-0.5, 5, 0)` and the signed difference `(-0.025, +0.15, 0)`. Explain why there is now an x error too. Adjust the board to show your changed range; do not silently rescale the metre labels.

## What the tests establish

Run `python tools/test_euler_step.py` in the Ada project. It checks the formula, all three intervals, signed difference, an independent launch, frame cadence, bounded saved states, reset and the constructed controls. `python tools/test_euler_printed.py` extracts the code printed here into fresh files and runs the same checks. It then reverses the two update statements in a deliberately faulty copy: the signed comparison must fail.

A passed script test establishes the calculation and declared scene construction. The museum probe separately exercises the real pointer buttons, simulated XR slider movement and a supported approach route. A tracked headset and a new human learner still need their own test.

## Carry onward

Keep the state, clock, saved trace and explicit comparison. They can return when a spring responds to a changing force. One second of constant acceleration does not demonstrate collisions, tunnelling or stability for every force law. It makes one approximation visible enough to question.
