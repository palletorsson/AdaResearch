extends Node3D
## The inherited PointBody supplies grab/release; this instrument records input.
signal started
signal received(value: int, receipt: Dictionary)
const PointBody = preload("res://commons/artifacts/ignorance_gallery/point_body.gd")
const Sample = preload("res://algorithms/randomness/seed_replay/movement_seed.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const HOME := Vector3(0, 1.13, 0.35)
var sample := Sample.new()
var point: XRToolsPickable
var readout: Label3D
var trace: MeshInstance3D
var collecting := false
var _desktop: Node3D
var _started_usec := 0
var _interval := 0.0
var _points: Array[Vector3] = []
var _rotations: Array[Vector3] = []
var _previous := Transform3D.IDENTITY
var _have_previous := false
var _status := ""

func _ready() -> void:
	name = "MovementSampler"
	Stage.box(self,Vector3(0,0.48,0.35),Vector3(0.3,0.96,0.3),Color("263039"),true)
	Stage.box(self,Vector3(0,1.72,0),Vector3(1.1,0.77,0.045),Color("131e25"))
	var title := _label("MOVE / KEEP",Vector3(0,2.03,0.035),27)
	title.modulate = Color("ffdc9b")
	readout = _label("Hold, move, release. Collect 30 samples.\nDesktop: right-click to hold / release.",Vector3(0,1.42,0.045),19)
	_label("X   Y   Z     /     ROTATION\nChange per sample: 5 cm / 15 deg full height",Vector3(0,1.91,0.035),16)
	trace = MeshInstance3D.new()
	add_child(trace)
	point = PointBody.new()
	point.name = "SeedPoint"
	point.position = HOME
	point.set_meta("desktop_hook_target",self)
	add_child(point)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1e2630")
	mat.metallic = 0.65
	mat.roughness = 0.16
	point.get_child(0).material_override = mat
	point.picked_up.connect(func(_p): begin_capture("xr_tracking"))
	point.dropped.connect(func(_p): end_capture())
	_redraw_trace()

func _label(words: String, at: Vector3, size: int) -> Label3D:
	var label := Stage.label(self,words,at)
	label.font_size = size
	label.pixel_size = 0.0014
	label.outline_size = 0
	return label

func on_desktop_grab(pointer: Node3D) -> void:
	_desktop = pointer
	begin_capture("desktop_movement")

func on_desktop_drop(_pointer: Node3D = null) -> void:
	end_capture()
	_desktop = null

func begin_capture(kind: String) -> void:
	if collecting: return
	sample.start(kind)
	collecting = true
	_started_usec = Time.get_ticks_usec()
	_interval = 0.0
	_points.clear()
	_rotations.clear()
	_have_previous = false
	started.emit()
	_show("Collecting movement; release to keep.")
	_redraw_trace()

func _process(delta: float) -> void:
	if not collecting: return
	_interval += delta
	if _interval < 1.0/60.0: return
	_interval = 0.0 # Never fabricate catch-up samples from a single pose.
	if sample.samples.size() >= Sample.MAX_SAMPLES:
		_show("Sample full; release to keep.")
		return
	if sample.source == "desktop_movement":
		if not is_instance_valid(_desktop):
			cancel_capture("Pointer lost; previous seed kept.")
			return
		# This mode measures the carried object, not an imaginary XR controller.
		accept_pose(point.transform,Time.get_ticks_usec()-_started_usec,true)
	else:
		sample_controller(point.get_picked_up_by_controller())

func sample_controller(controller: XRController3D) -> bool:
	if controller == null:
		return accept_pose(Transform3D.IDENTITY,Time.get_ticks_usec()-_started_usec,false)
	var pose := controller.get_pose()
	var valid := pose != null and pose.has_tracking_data and pose.tracking_confidence == XRPose.XR_TRACKING_CONFIDENCE_HIGH
	# Runtime pose is relative to the tracking origin, excluding virtual locomotion.
	return accept_pose(pose.transform if valid else Transform3D.IDENTITY,Time.get_ticks_usec()-_started_usec,valid)

func accept_pose(pose: Transform3D, elapsed_usec: int, valid: bool) -> bool:
	if not collecting: return false
	if not sample.add_pose(pose,elapsed_usec,valid):
		_show("Tracking unavailable; waiting." if not valid else "Sample held; waiting.")
		return false
	if _have_previous:
		_points.append(pose.origin-_previous.origin)
		var rotation := (_previous.basis.inverse()*pose.basis).get_rotation_quaternion()
		_rotations.append(rotation.get_axis()*rotation.get_angle())
		if _points.size() > 90:
			_points.pop_front()
			_rotations.pop_front()
	_previous = pose
	_have_previous = true
	_show("Move the sphere; release to keep.")
	_redraw_trace()
	return true

func _show(message: String) -> void:
	_status = message
	readout.text = "%s\n%d samples / %d changed / %d skipped\n%s" % [message,sample.samples.size(),sample.changes,sample.rejected,
		"Desktop movement" if sample.source == "desktop_movement" else "XR tracking sample"]

func cancel_capture(message: String = "Previous seed kept.") -> void:
	collecting = false
	_show(message)

## Recall the actual kept trace, not a fresh measurement or a fresh seed.
func show_kept_recording(receipt: Dictionary) -> void:
	if collecting or not receipt.has("samples"): return
	sample.start(str(receipt.source))
	sample.samples = receipt.samples.duplicate(true)
	sample.changes = int(receipt.get("changed_samples",0))
	sample.rejected = int(receipt.get("rejected_samples",0))
	_points.clear();_rotations.clear()
	var previous := Transform3D.IDENTITY
	for i in range(sample.samples.size()):
		var row: Array = sample.samples[i]
		var position := Vector3(row[1],row[2],row[3])/100000.0
		var q := Quaternion(row[4]/1000000.0,row[5]/1000000.0,row[6]/1000000.0,row[7]/1000000.0).normalized()
		var pose := Transform3D(Basis(q),position)
		if i>0:
			_points.append(pose.origin-previous.origin)
			var rotation := (previous.basis.inverse()*pose.basis).get_rotation_quaternion()
			_rotations.append(rotation.get_axis()*rotation.get_angle())
		previous=pose
	while _points.size()>90: _points.pop_front();_rotations.pop_front()
	_redraw_trace()
	_show("Kept recording: seed %d.\nMove again to make a new recording." % int(receipt.seed))

func end_capture() -> void:
	if collecting:
		collecting = false
		var receipt := sample.finish()
		if receipt.is_empty():
			_show("Too short / no measured change; seed kept.")
		else:
			_show("Last sample: seed %d.\nREPLAY uses the seed on the big display." % int(receipt.seed))
			received.emit(int(receipt.seed),receipt)
	_return_home.call_deferred()

func _return_home() -> void:
	if not is_instance_valid(point) or point.is_picked_up() or collecting: return
	point.freeze = true
	point.linear_velocity = Vector3.ZERO
	point.angular_velocity = Vector3.ZERO
	point.transform = Transform3D(Basis.IDENTITY,HOME)
	PhysicsServer3D.body_set_state(point.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,point.global_transform)

func _redraw_trace() -> void:
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat)
	var hues := [Color("fc9aac"),Color("8eedc2"),Color("83bbff")]
	for channel in range(6):
		var base := 1.83 - channel*0.048
		mesh.surface_set_color(hues[channel%3]*0.35)
		mesh.surface_add_vertex(Vector3(-0.47,base,0.034))
		mesh.surface_add_vertex(Vector3(0.47,base,0.034))
		mesh.surface_set_color(hues[channel%3])
		var data: Array[Vector3] = _points if channel < 3 else _rotations
		var maximum := 0.05 if channel < 3 else deg_to_rad(15)
		for i in range(1,data.size()):
			for j in [i-1,i]:
				var height := clampf(data[j][channel%3]/maximum,-1,1)*0.021
				mesh.surface_add_vertex(Vector3(-0.47+0.94*j/89.0,base+height,0.04))
	mesh.surface_end()
	trace.mesh = mesh
