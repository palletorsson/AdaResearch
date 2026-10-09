extends Node3D
## A local flight volume with a physical glass envelope. The contained sculpture
## remains solid; the envelope changes locomotion, not the sculpture's rule.

const GROUP := "ada_museum_flight"
const EDGE := 12.0
const SPEED := 2.4
const DOOR_WIDTH := 3.0
const DOOR_HEIGHT := 2.6

func _ready() -> void:
	add_to_group(GROUP)
	_build_enclosure()
	_install_xr_adapter.call_deferred()
	get_tree().node_added.connect(_node_added)

func contains_point(world_position: Vector3) -> bool:
	var p := to_local(world_position)
	return absf(p.x) < EDGE * 0.5 and absf(p.z) < EDGE * 0.5 \
		and p.y >= -0.03 and p.y < EDGE

static func at_point(tree: SceneTree, world_position: Vector3) -> Node3D:
	for zone in tree.get_nodes_in_group(GROUP):
		if zone.contains_point(world_position): return zone
	return null

## One bounded velocity for simultaneous strafe, forward and vertical input.
## Neutral input hovers. No inertia is carried out through the ground doors.
func flight_velocity(view: Basis, axes: Vector2, vertical: float = 0.0) -> Vector3:
	var direction := view.x * axes.x - view.z * axes.y + Vector3.UP * vertical
	return direction.limit_length(1.0) * SPEED

func desktop_velocity(view: Basis) -> Vector3:
	var axes := Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S)))
	var vertical := float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_CTRL))
	return flight_velocity(view, axes, vertical)

func _node_added(node: Node) -> void:
	if node is XRToolsPlayerBody: _install_xr_adapter.call_deferred()

func _install_xr_adapter() -> void:
	if not is_inside_tree(): return
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("MuseumFlightAdapter") != null: continue
		var adapter = preload("res://commons/movement/museum_flight_provider.gd").new()
		adapter.name = "MuseumFlightAdapter"
		adapter.receiver = body
		body.add_child(adapter)
		if adapter not in body._movement_providers: body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

func _material(colour: Color, luminous: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.3
	if colour.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if luminous:
		m.emission_enabled = true
		m.emission = Color(colour.r, colour.g, colour.b)
		m.emission_energy_multiplier = 0.7
	return m

func _box(label_: String, at: Vector3, size_: Vector3, material: Material, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label_
	var cube := BoxMesh.new()
	cube.size = size_
	mesh.mesh = cube
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position = at
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = label_ + "Collision"
		body.position = at
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size_
		shape.shape = box
		body.add_child(shape)
		add_child(body)

func _sign(at: Vector3, yaw: float) -> void:
	var mount := Node3D.new()
	mount.position = at
	mount.rotation.y = yaw
	add_child(mount)
	var backing := MeshInstance3D.new()
	var panel := BoxMesh.new()
	panel.size = Vector3(4.9,0.8,0.05)
	backing.mesh = panel
	backing.material_override = _material(Color(0.015,0.035,0.045))
	mount.add_child(backing)
	var label_ := Label3D.new()
	label_.name = "FlightInstructions"
	label_.text = "FLY THROUGH THE HOLES\nFlight begins inside the frame\nDesktop: look + WASD / Space up / Ctrl down\nVR: tilt the left controller + left stick\nRelease to hover. Descend to either door to leave."
	label_.font_size = 40
	label_.pixel_size = 0.002
	label_.modulate = Color(0.65, 0.95, 1.0)
	label_.outline_size = 8
	label_.no_depth_test = false
	label_.double_sided = false
	label_.position.z = 0.035
	mount.add_child(label_)

func _build_enclosure() -> void:
	var glass := _material(Color(0.3, 0.7, 0.85, 0.065))
	var frame := _material(Color(0.14, 0.8, 0.94), true)
	var landing := _material(Color(0.18, 0.31, 0.37))
	var h := EDGE * 0.5
	var t := 0.06
	# Floor top at zero; roof underside at EDGE. Side faces have real collisions.
	_box("Floor", Vector3(0,-t*0.5,0), Vector3(EDGE,t,EDGE),glass,true)
	# The museum camera is 15 cm above its capsule. A 24 cm roof keeps the eye
	# inside the visible envelope when that capsule reaches the ceiling.
	_box("Roof", Vector3(0,EDGE-0.06,0), Vector3(EDGE,0.24,EDGE),glass,true)
	for s in [-1.0,1.0]:
		_box("Side", Vector3(s*(h+t*0.5),h,0), Vector3(t,EDGE,EDGE),glass,true)
		var wing := (EDGE-DOOR_WIDTH)*0.5
		for side in [-1.0,1.0]:
			_box("DoorWing", Vector3(side*(DOOR_WIDTH+wing)*0.5,h,s*(h+t*0.5)),Vector3(wing,EDGE,t),glass,true)
		_box("DoorLintel",Vector3(0,(EDGE+DOOR_HEIGHT)*0.5,s*(h+t*0.5)),Vector3(DOOR_WIDTH,EDGE-DOOR_HEIGHT,t),glass,true)
		_box("Landing",Vector3(0,-0.025,s*h),Vector3(DOOR_WIDTH,0.05,1.0),landing,true)
		for side in [-1.0,1.0]:
			_box("DoorFrame",Vector3(side*(DOOR_WIDTH*0.5+0.04),DOOR_HEIGHT*0.5,s*h),Vector3(0.08,DOOR_HEIGHT,0.08),frame,false)
		_box("DoorFrameTop",Vector3(0,DOOR_HEIGHT,s*h),Vector3(DOOR_WIDTH+0.16,0.08,0.08),frame,false)
		# The floor edge stops at the door: no hidden sill to catch the feet.
		for side in [-1.0,1.0]:
			_box("FloorEdge",Vector3(side*(DOOR_WIDTH+wing)*0.5,0.035,s*h),Vector3(wing,0.04,0.04),frame,false)
		_box("TopEdgeX",Vector3(0,EDGE,s*h),Vector3(EDGE,0.06,0.06),frame,false)
		for y in [0.035,EDGE]:
			_box("EdgeZ",Vector3(s*h,y,0),Vector3(0.06,0.06,EDGE),frame,false)
		for side in [-1.0,1.0]:
			_box("Upright",Vector3(s*h,h,side*h),Vector3(0.08,EDGE,0.08),frame,false)
	# Outside and inside, on both ground doors, so return controls remain visible.
	for s in [-1.0,1.0]:
		_sign(Vector3(0,3.25,s*(h+0.08)), PI if s < 0 else 0.0)
		_sign(Vector3(0,3.25,s*(h-0.08)), 0.0 if s < 0 else PI)
