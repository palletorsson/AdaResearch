extends Node3D
class_name SynthCablePlug

## Grabbable plug end of a synth cable
## Can be inserted into SynthJack sockets

signal snapped_to_jack(jack: SynthJack)
signal unsnapped_from_jack(jack: SynthJack)

@export var plug_color: Color = Color(0.8, 0.2, 0.2)
@export var plug_radius: float = 0.01
@export var plug_length: float = 0.025
@export var tip_color: Color = Color(0.15, 0.15, 0.15)

var current_jack: SynthJack = null
var is_snapped: bool = false
var _being_held: bool = false

# XR Pickable components
var rigid_body: RigidBody3D
var pickup_component: Node  # XRToolsPickable


func _ready():
	_create_plug_mesh()
	_setup_grabbable()


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


func _setup_grabbable():
	# Create RigidBody3D for physics interaction
	rigid_body = RigidBody3D.new()
	rigid_body.name = "PlugRigidBody"
	rigid_body.gravity_scale = 0.0  # Cable handles physics
	rigid_body.freeze = true  # Start frozen, unfreeze when grabbed
	
	# Collision shape
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = plug_radius * 1.5
	capsule.height = plug_length * 1.5
	collision.shape = capsule
	collision.rotation_degrees.x = 90
	collision.position.z = plug_length / 2
	rigid_body.add_child(collision)
	
	add_child(rigid_body)
	
	# Try to add XRToolsPickable if available
	_try_add_xr_pickable()
	
	# Detection area for jacks
	var detect_area = Area3D.new()
	detect_area.name = "JackDetector"
	var detect_shape = CollisionShape3D.new()
	var detect_sphere = SphereShape3D.new()
	detect_sphere.radius = plug_radius * 3
	detect_shape.shape = detect_sphere
	detect_shape.position.z = -plug_length * 0.3  # At tip
	detect_area.add_child(detect_shape)
	add_child(detect_area)
	
	detect_area.area_entered.connect(_on_area_entered)
	detect_area.area_exited.connect(_on_area_exited)


func _try_add_xr_pickable():
	# Check if XRToolsPickable exists
	var pickable_script_path = "res://addons/godot-xr-tools/interactables/interactable_handle.gd"
	if ResourceLoader.exists(pickable_script_path):
		var script = load(pickable_script_path)
		if script:
			# XRToolsInteractableHandle extends RigidBody3D, so it must live on the
			# plug rigid body itself rather than on a child Node.
			rigid_body.set_script(script)
			pickup_component = rigid_body
			
			# Connect signals if available
			if pickup_component.has_signal("picked_up"):
				pickup_component.picked_up.connect(_on_picked_up)
			if pickup_component.has_signal("dropped"):
				pickup_component.dropped.connect(_on_dropped)


func _on_picked_up(_pickable):
	_being_held = true
	rigid_body.freeze = false
	
	# Unsnap from jack if connected
	if is_snapped and current_jack:
		_unsnap()


func _on_dropped(_pickable):
	_being_held = false
	rigid_body.freeze = true
	
	# Check if near a jack to snap
	_check_nearby_jacks()


func _on_area_entered(area: Area3D):
	if _being_held:
		return  # Don't snap while being held
	
	var parent = area.get_parent()
	if parent is SynthJack and not is_snapped:
		_snap_to_jack(parent)


func _on_area_exited(_area: Area3D):
	pass  # Disconnection handled by jack or grab


func _snap_to_jack(jack: SynthJack):
	if is_snapped:
		return
	
	current_jack = jack
	is_snapped = true
	
	# Move to jack position
	var target_pos = jack.get_socket_position()
	global_position = target_pos
	
	# Align rotation with jack
	global_transform.basis = jack.global_transform.basis
	
	# Lock in place
	rigid_body.freeze = true
	
	snapped_to_jack.emit(jack)


func _unsnap():
	if not is_snapped:
		return
	
	var old_jack = current_jack
	current_jack = null
	is_snapped = false
	
	unsnapped_from_jack.emit(old_jack)


func _check_nearby_jacks():
	# Use overlapping areas to find nearby jacks
	var detect_area = get_node_or_null("JackDetector") as Area3D
	if not detect_area:
		return
	
	for area in detect_area.get_overlapping_areas():
		var parent = area.get_parent()
		if parent is SynthJack and not parent.is_connected:
			_snap_to_jack(parent)
			return


## API
func is_synth_plug() -> bool:
	return true


func is_being_held() -> bool:
	return _being_held


func get_plug_type():
	# Plugs are neutral - can go in either jack type
	return null


func snap_to_jack(jack: SynthJack):
	_snap_to_jack(jack)


func get_cable_attachment_point() -> Vector3:
	# Point where cable attaches (back of plug)
	return global_position + global_transform.basis.z * plug_length


func set_plug_color(color: Color):
	plug_color = color
	var body = get_node_or_null("PlugBody") as MeshInstance3D
	if body and body.material_override:
		body.material_override.albedo_color = color
	var ring = get_node_or_null("GripRing") as MeshInstance3D
	if ring and ring.material_override:
		ring.material_override.albedo_color = color.darkened(0.3)
