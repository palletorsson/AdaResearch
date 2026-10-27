extends Node3D
## Release a point to gravity; the stand supplies another when its place is clear.
## Each retained ball has its own measured trace. Never drives the released path.
const RADIUS := 0.14
const HOME := Vector3(0, 1.14, -0.20)
const SAMPLE_DISTANCE := 0.018
const CAPACITY := 1024
class BallTrace:
	var body: XRToolsPickable
	var samples: PackedVector3Array = []
	var recording := false
	var held := false
	var ink: MultiMeshInstance3D
	var segment_count := 0

## The latest supplied ball, until it is released. Older balls stay in traces.
var ball: XRToolsPickable
var traces: Array[BallTrace] = []
var _black: StandardMaterial3D
var _refill_requested := false

func _ready() -> void:
	var porcelain := material(Color(0.93,0.92,0.88),0.48)
	var black := material(Color(0.009,0.01,0.015),0.27)
	_black = black
	box("Plinth",Vector3(1.25,1,1.25),Vector3(0,0.5,0),porcelain)
	var a := Vector3(0,1,0.55)
	var b := Vector3(0,0.045,3.80)
	var axis := (b-a).normalized()
	var ramp_basis := Basis(Quaternion(Vector3.BACK,axis))
	var plank := box("Plank",Vector3(0.82,0.12,a.distance_to(b)),(a+b)*0.5-ramp_basis.y*0.06,porcelain)
	plank.basis=ramp_basis
	for side in [-1.0,1.0]:
		var rail := box("PlankLip",Vector3(0.028,0.055,a.distance_to(b)),(a+b)*0.5+ramp_basis.y*0.027+Vector3(side*0.425,0,0),black)
		rail.basis=ramp_basis
	box("Landing",Vector3(1.8,0.045,1.65),Vector3(0,0.0225,4.57),porcelain)
	box("EndStop",Vector3(1.8,0.26,0.045),Vector3(0,0.15,5.395),black)
	for side in [-1.0,1.0]:
		box("LandingLip",Vector3(0.045,0.26,1.65),Vector3(side*0.88,0.15,4.57),black)
	_supply_ball()
	label("POINT / RELEASE",Vector3(-0.632,0.79,0.00),Vector3(0,-PI/2,0),0.004,black.albedo_color)
	label("Let go. Another point waits here.",Vector3(-0.632,0.56,0.00),Vector3(0,-PI/2,0),0.002,black.albedo_color)
	label("A path after your hand lets go",Vector3(0,0.051,4.70),Vector3(-PI/2,0,0),0.002,black.albedo_color)

func _supply_ball() -> void:
	var trace := BallTrace.new()
	ball=preload("res://commons/artifacts/primitive_encounters/trace_point_ball.tscn").instantiate()
	ball.name="BlackPoint%d" % (traces.size() + 1)
	add_child(ball);ball.position=HOME
	trace.body = ball
	ball.picked_up.connect(_picked_up.bind(trace))
	ball.dropped.connect(_dropped.bind(trace))
	var ink := MultiMeshInstance3D.new();ink.name="ActualPath%d" % (traces.size() + 1)
	ink.multimesh=MultiMesh.new();ink.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var tube := CylinderMesh.new();tube.top_radius=0.009;tube.bottom_radius=0.009;tube.height=1;tube.radial_segments=8
	ink.multimesh.mesh=tube;ink.multimesh.instance_count=CAPACITY;ink.multimesh.visible_instance_count=0
	ink.material_override=_black;ink.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ink)
	trace.ink = ink
	traces.append(trace)
	_refill_requested = false

func _picked_up(_body: Node3D, trace: BallTrace) -> void:
	trace.held = true
	trace.recording = false

func _dropped(body: Node3D, trace: BallTrace) -> void:
	trace.held = false
	trace.recording = trace.segment_count < CAPACITY
	# Start a separate stroke after each carry, preserving the previous ink.
	if trace.recording:
		trace.samples.append(to_local(body.global_position))
	if body == ball:
		ball = null
		_refill_requested = true
		_refill_stand.call_deferred()

func _refill_stand() -> void:
	if not _refill_requested or is_instance_valid(ball):
		return
	var home := to_global(HOME)
	for trace in traces:
		if is_instance_valid(trace.body) and trace.body.global_position.distance_to(home) < RADIUS * 2.0 + 0.04:
			return # A returned or held ball must not overlap the new one.
	_supply_ball()

func _physics_process(_delta: float) -> void:
	if _refill_requested:
		_refill_stand.call_deferred()
	for trace in traces:
		if not is_instance_valid(trace.body) or trace.held or not trace.recording:
			continue
		_record_ball(trace)

func _record_ball(trace: BallTrace) -> void:
	var body := trace.body
	var p := to_local(body.global_position)
	if p.y < -2 or p.length() > 16:
		# Park escaped bodies where they are; never recycle one onto the stand.
		trace.recording = false
		body.freeze = true
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		return
	if trace.samples.is_empty() or trace.segment_count >= CAPACITY:return
	var a := trace.samples[-1]
	var length := a.distance_to(p)
	if length<SAMPLE_DISTANCE:return
	var direction := (p-a)/length
	var frame := Basis(Quaternion(Vector3.UP,direction))*Basis.from_scale(Vector3(1,length,1))
	trace.ink.multimesh.set_instance_transform(trace.segment_count,Transform3D(frame,(a+p)*0.5))
	trace.segment_count += 1
	trace.ink.multimesh.visible_instance_count = trace.segment_count
	trace.samples.append(p)

func material(colour: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=colour;m.roughness=roughness
	return m

func box(title: String, size: Vector3, at: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new();body.name=title;body.position=at;body.collision_layer=1;body.collision_mask=0
	var mesh := MeshInstance3D.new();var form := BoxMesh.new();form.size=size;mesh.mesh=form;mesh.material_override=mat
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=size;collision.shape=shape
	body.add_child(mesh);body.add_child(collision);add_child(body)
	return body

func label(words: String, at: Vector3, angles: Vector3, size: float, colour: Color) -> void:
	var text := Label3D.new();text.text=words;text.position=at;text.rotation=angles;text.pixel_size=size;text.font_size=32
	text.modulate=colour;text.outline_size=0;text.no_depth_test=false;add_child(text)
