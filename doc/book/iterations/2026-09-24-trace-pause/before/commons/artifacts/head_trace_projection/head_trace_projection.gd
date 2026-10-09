extends Node3D
## One measured path, two representations. No demonstration motion is generated.
## Headset position includes locomotion; the floor mark is not foot tracking.
## Desktop input is restricted to the active museum walker's camera and labelled.

const CAPACITY := 256
const HALF_WIDTH := 1.1
const FLOOR_Y := 0.025
const MOVEMENT_GATE := 0.015
const MAX_STEP := 0.45
const HEAD_COLOR := Color(1.0, 0.60, 0.78)
const FLOOR_COLOR := Color(0.18, 0.87, 0.94)

var _points: Array[Vector3] = []
var _joins: Array[bool] = []
var _head_beads: MultiMeshInstance3D
var _floor_beads: MultiMeshInstance3D
var _head_cord: MultiMeshInstance3D
var _floor_cord: MultiMeshInstance3D
var _status: Label3D
var _break_pending := true
var _outside_time := 1.0
var _fresh_on_entry := true
var _source_id := 0
var _source_kind := ""
var _body: Node
var _interface: XRInterface

func _ready() -> void:
	_build_display()
	if XRServer.has_signal("reference_frame_changed"):
		XRServer.connect("reference_frame_changed", _interrupt_stroke)

func _process(delta: float) -> void:
	var input := _read_input()
	if input.is_empty():
		_interrupt_stroke()
		_set_status("Waiting for a tracked head\nor the desktop walking view")
		return
	var camera: Camera3D = input["camera"]
	var kind: String = input["kind"]
	if camera.get_instance_id() != _source_id or kind != _source_kind:
		# A different observer starts another record, never relabels an old one.
		_fresh_on_entry = true
		_interrupt_stroke()
		_source_id = camera.get_instance_id()
		_source_kind = kind
	if delta > 0.25:
		_interrupt_stroke()
	_accept_position(camera.global_position, delta, kind)

func _read_input() -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera): return {}
	var xr := XRServer.primary_interface
	if camera is XRCamera3D:
		if xr == null or not xr.is_initialized(): return {}
		# Do not treat an old/staging camera or uncertain tracking as measurement.
		if xr.get_tracking_status() != XRInterface.XR_NORMAL_TRACKING: return {}
		var rig := camera.get_parent() as XROrigin3D
		if rig == null or not rig.current: return {}
		if xr != _interface:
			if is_instance_valid(_interface) and _interface.play_area_changed.is_connected(_interrupt_stroke):
				_interface.play_area_changed.disconnect(_interrupt_stroke)
			_interface = xr
			_interface.play_area_changed.connect(_interrupt_stroke)
			_interrupt_stroke()
		# XRTools teleports may be shorter than the displacement guard.
		if not is_instance_valid(_body) or not rig.is_ancestor_of(_body):
			if is_instance_valid(_body) and _body.is_connected("player_teleported", _interrupt_stroke):
				_body.disconnect("player_teleported", _interrupt_stroke)
			_body = null
			for child in rig.find_children("*", "CharacterBody3D", true, false):
				if child.has_signal("player_teleported"):
					_body = child
					_body.connect("player_teleported", _interrupt_stroke)
					break
		return {"camera":camera, "kind":"HEADSET"}
	# Never silently record a spectator, photo, editor or staging camera.
	if xr != null and xr.is_initialized(): return {}
	var ancestor: Node = camera
	while ancestor != null:
		if ancestor.is_in_group("em_walker"):
			return {"camera":camera, "kind":"DESKTOP VIEW"}
		ancestor = ancestor.get_parent()
	return {}

func _interrupt_stroke(_unused: Variant = null) -> void:
	_break_pending = true

func _accept_position(world_position: Vector3, delta: float, kind: String) -> void:
	if not world_position.is_finite():
		_interrupt_stroke()
		return
	var p := to_local(world_position)
	var inside := absf(p.x) <= HALF_WIDTH and absf(p.z) <= HALF_WIDTH and p.y > 0.15 and p.y < 3.2
	if not inside:
		_outside_time += delta
		if _outside_time >= 0.6: _fresh_on_entry = true
		_interrupt_stroke()
		_set_status("Step into the square\nLean. Lower your head. Step aside.")
		return
	_outside_time = 0.0
	if _fresh_on_entry:
		_points.clear()
		_joins.clear()
		_break_pending = true
		_fresh_on_entry = false
	var join := not _break_pending and not _points.is_empty()
	if join:
		var distance := p.distance_to(_points[-1])
		if distance < MOVEMENT_GATE: return
		if distance > MAX_STEP: join = false
	_points.append(p)
	_joins.append(join)
	if _points.size() > CAPACITY:
		_points.pop_front()
		_joins.pop_front()
	_joins[0] = false
	_break_pending = false
	_rebuild_trace()
	_set_status(kind + " / " + str(_points.size()) + " positions\nStep aside to see. Return to begin again.")

func floor_position(p: Vector3) -> Vector3:
	return Vector3(p.x, FLOOR_Y, p.z)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _instances(label: String, mesh: Mesh) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = CAPACITY
	node.multimesh.visible_instance_count = 0
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _build_display() -> void:
	var bead := SphereMesh.new()
	bead.radius = 0.008
	bead.height = 0.016
	bead.radial_segments = 6
	bead.rings = 3
	bead.material = _material(HEAD_COLOR)
	_head_beads = _instances("HeadPositions", bead)
	var flat_bead := bead.duplicate() as SphereMesh
	flat_bead.material = _material(FLOOR_COLOR)
	_floor_beads = _instances("FloorPositions", flat_bead)
	var cord := CylinderMesh.new()
	cord.top_radius = 0.005
	cord.bottom_radius = 0.005
	cord.height = 1.0
	cord.radial_segments = 6
	cord.rings = 1
	cord.material = _material(HEAD_COLOR)
	_head_cord = _instances("HeadJoins", cord)
	var flat_cord := cord.duplicate() as CylinderMesh
	flat_cord.material = _material(FLOOR_COLOR)
	_floor_cord = _instances("FloorJoins", flat_cord)
	# A flush square, not a stage or an obstacle. The existing museum is the floor.
	_box(Vector3(2.2,0.008,2.2), Vector3(0,0.005,0), Color(0.08,0.10,0.13))
	for side in [-1.0,1.0]:
		_box(Vector3(2.2,0.003,0.012), Vector3(0,0.011,side*HALF_WIDTH), FLOOR_COLOR)
		_box(Vector3(0.012,0.003,2.2), Vector3(side*HALF_WIDTH,0.011,0), FLOOR_COLOR)
	# Narrow label at the back edge leaves the square clear to move through.
	_box(Vector3(0.74,0.33,0.035), Vector3(0,1.10,-1.15), Color(0.045,0.05,0.065))
	_box(Vector3(0.022,1.08,0.022), Vector3(0,0.54,-1.16), Color(0.22,0.24,0.27))
	_label("HEAD PATH", Vector3(0,1.20,-1.126), 0.0015, HEAD_COLOR)
	_label("SAME POINTS / ON THE FLOOR", Vector3(0,1.13,-1.126), 0.0011, FLOOR_COLOR)
	_status = _label("Step into the square", Vector3(0,1.01,-1.125), 0.001, Color(0.85,0.86,0.88))

func _box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	add_child(node)

func _label(words: String, pos: Vector3, pixels: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = pos
	label.pixel_size = pixels
	label.font_size = 32
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	add_child(label)
	return label

func _set_status(words: String) -> void:
	if _status.text != words: _status.text = words

func _segment(a: Vector3, b: Vector3) -> Transform3D:
	var span := b-a
	var length := span.length()
	var y := span/length
	var helper := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var x := helper.cross(y).normalized()
	return Transform3D(Basis(x,y*length,x.cross(y).normalized()), (a+b)*0.5)

func _rebuild_trace() -> void:
	var head_count := 0
	var floor_count := 0
	_head_beads.multimesh.visible_instance_count = _points.size()
	_floor_beads.multimesh.visible_instance_count = _points.size()
	for i in range(_points.size()):
		var p := _points[i]
		var flat := floor_position(p)
		_head_beads.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,p))
		_floor_beads.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,flat))
		if i == 0 or not _joins[i]: continue
		var previous := _points[i-1]
		if previous.distance_to(p) > 0.000001:
			_head_cord.multimesh.set_instance_transform(head_count,_segment(previous,p))
			head_count += 1
		var flat_previous := floor_position(previous)
		if flat_previous.distance_to(flat) > 0.000001:
			_floor_cord.multimesh.set_instance_transform(floor_count,_segment(flat_previous,flat))
			floor_count += 1
	_head_cord.multimesh.visible_instance_count = head_count
	_floor_cord.multimesh.visible_instance_count = floor_count
