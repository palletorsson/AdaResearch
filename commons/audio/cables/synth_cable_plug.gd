extends "res://addons/godot-xr-tools/objects/pickable.gd"
class_name SynthCablePlug
## The grip, plug and physics body move together on desktop and in XR.
signal snapped_to_jack(jack: SynthJack)
signal unsnapped_from_jack(jack: SynthJack)
@export var plug_color := Color(0.8,0.2,0.2)
@export var plug_radius := 0.01
@export var plug_length := 0.025
@export var tip_color := Color(0.15,0.15,0.15)
var current_jack: SynthJack
var is_snapped := false
var _being_held := false

func _init() -> void:
	collision_layer = 4; collision_mask = 0; gravity_scale = 0.0
	freeze = true; release_mode = ReleaseMode.FROZEN

func _ready() -> void:
	add_to_group("no_gravity_gun")
	_create_plug_mesh()
	var shape := SphereShape3D.new(); shape.radius = 0.023
	var col := CollisionShape3D.new(); col.shape = shape; col.position.z = plug_length * 0.5
	add_child(col)
	super()
	picked_up.connect(_on_picked_up); dropped.connect(_on_dropped)

func _on_picked_up(_object) -> void:
	_being_held = true; _unsnap()
func _on_dropped(_object) -> void:
	_being_held = false; freeze = true
	linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO
	_check_nearby_jacks()
func on_desktop_grab(pointer: Node) -> void: _on_picked_up(pointer)
func on_desktop_drop(pointer: Node) -> void: _on_dropped(pointer)
func is_being_held() -> bool: return _being_held or is_picked_up()
func is_synth_plug() -> bool: return true
func get_plug_type(): return null

func can_snap(jack: SynthJack) -> bool:
	if not is_instance_valid(jack) or jack.is_connected: return false
	var cable = get_parent()
	if jack.manager != cable.get_parent(): return false
	var other = cable.plug_b if cable.plug_a == self else cable.plug_a
	return other.current_jack == null or (other.current_jack != jack and other.current_jack.jack_type != jack.jack_type and other.current_jack.signal_kind == jack.signal_kind)

func snap_to_jack(jack: SynthJack) -> bool:
	if current_jack == jack: return true
	if not can_snap(jack): return false
	_unsnap()
	current_jack = jack; is_snapped = true; freeze = true
	global_transform = Transform3D(jack.global_basis, jack.get_socket_position())
	jack.connected_plug = self; jack.is_connected = true
	jack._set_connected_visual(true)
	snapped_to_jack.emit(jack)
	jack.cable_connected.emit(get_parent(), self)
	return true

func _snap_to_jack(jack: SynthJack): return snap_to_jack(jack)
func _unsnap() -> void:
	if not is_snapped: return
	var previous := current_jack
	current_jack = null; is_snapped = false
	if is_instance_valid(previous):
		previous.connected_plug = null; previous.is_connected = false
		previous._set_connected_visual(false)
	unsnapped_from_jack.emit(previous)
	if is_instance_valid(previous): previous.cable_disconnected.emit(get_parent(), self)

func _check_nearby_jacks() -> void:
	var manager = get_parent().get_parent()
	if not manager is SynthCableManager: return
	var closest: SynthJack
	var distance := 0.055
	for jack in manager._all_jacks:
		var d: float = global_position.distance_to(jack.get_socket_position())
		if d < distance and can_snap(jack): closest = jack; distance = d
	if closest: snap_to_jack(closest)

func get_cable_attachment_point() -> Vector3:
	return to_global(Vector3(0,0,plug_length))

func _create_plug_mesh():
	# Main plug body
	var body_mesh = MeshInstance3D.new()
	body_mesh.name = "PlugBody"
	
	var cyl = CylinderMesh.new()
	cyl.top_radius = plug_radius
	cyl.bottom_radius = plug_radius
	cyl.height = plug_length
	cyl.radial_segments = 12
	body_mesh.mesh = cyl
	body_mesh.rotation_degrees.x = 90
	body_mesh.position.z = plug_length / 2
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = plug_color
	body_mat.metallic = 0.3
	body_mat.roughness = 0.6
	body_mesh.material_override = body_mat
	add_child(body_mesh)
	
	# Metal tip
	var tip_mesh = MeshInstance3D.new()
	tip_mesh.name = "PlugTip"
	
	var tip_cyl = CylinderMesh.new()
	tip_cyl.top_radius = plug_radius * 0.7
	tip_cyl.bottom_radius = plug_radius * 0.8
	tip_cyl.height = plug_length * 0.4
	tip_cyl.radial_segments = 12
	tip_mesh.mesh = tip_cyl
	tip_mesh.rotation_degrees.x = 90
	tip_mesh.position.z = -plug_length * 0.2
	
	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = tip_color
	tip_mat.metallic = 1.0
	tip_mat.roughness = 0.1
	tip_mesh.material_override = tip_mat
	add_child(tip_mesh)
	
	# Grip ring
	var ring_mesh = MeshInstance3D.new()
	ring_mesh.name = "GripRing"
	
	var torus = TorusMesh.new()
	torus.inner_radius = plug_radius * 0.9
	torus.outer_radius = plug_radius * 1.3
	torus.rings = 8
	torus.ring_segments = 12
	ring_mesh.mesh = torus
	ring_mesh.rotation_degrees.x = 90
	ring_mesh.position.z = plug_length * 0.3
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = plug_color.darkened(0.3)
	ring_mat.metallic = 0.2
	ring_mat.roughness = 0.8
	ring_mesh.material_override = ring_mat
	add_child(ring_mesh)


func set_plug_color(color: Color):
	plug_color = color
	var body = get_node_or_null("PlugBody") as MeshInstance3D
	if body and body.material_override:
		body.material_override.albedo_color = color
	var ring = get_node_or_null("GripRing") as MeshInstance3D
	if ring and ring.material_override:
		ring.material_override.albedo_color = color.darkened(0.3)
