extends Node3D
class_name SynthJack

## A jack socket on a synth module that can receive cable plugs
## Supports both input and output types with parameter binding

signal cable_connected(cable: Node3D, plug: Node3D)
signal cable_disconnected(cable: Node3D, plug: Node3D)

enum JackType { OUTPUT, INPUT }

@export var jack_type: JackType = JackType.OUTPUT
@export var parameter_name: String = ""  ## e.g., "frequency", "amplitude"
@export var jack_color: Color = Color(0.2, 0.2, 0.25)
@export var ring_color: Color = Color(0.8, 0.8, 0.8)
@export var connected_color: Color = Color(0.2, 1.0, 0.4)  ## Glow when connected
@export var socket_radius: float = 0.012
@export var socket_depth: float = 0.015

var connected_plug: Node3D = null
var is_connected: bool = false

@onready var socket_area: Area3D = $SocketArea
@onready var socket_mesh: MeshInstance3D = $SocketMesh
@onready var ring_mesh: MeshInstance3D = $RingMesh
@onready var glow_light: OmniLight3D = $GlowLight if has_node("GlowLight") else null


func _ready():
	_setup_visuals()
	_setup_detection()


func _setup_visuals():
	# Create socket mesh (cylinder hole)
	if not socket_mesh:
		socket_mesh = MeshInstance3D.new()
		socket_mesh.name = "SocketMesh"
		add_child(socket_mesh)
	
	var cyl = CylinderMesh.new()
	cyl.top_radius = socket_radius
	cyl.bottom_radius = socket_radius * 0.8
	cyl.height = socket_depth
	cyl.radial_segments = 16
	socket_mesh.mesh = cyl
	socket_mesh.rotation_degrees.x = 90  # Face forward
	socket_mesh.position.z = -socket_depth / 2
	
	var socket_mat = StandardMaterial3D.new()
	socket_mat.albedo_color = Color(0.02, 0.02, 0.02)
	socket_mat.metallic = 1.0
	socket_mat.roughness = 0.1
	socket_mesh.material_override = socket_mat
	
	# Create outer ring
	if not ring_mesh:
		ring_mesh = MeshInstance3D.new()
		ring_mesh.name = "RingMesh"
		add_child(ring_mesh)
	
	var torus = TorusMesh.new()
	torus.inner_radius = socket_radius
	torus.outer_radius = socket_radius + 0.006
	torus.rings = 12
	torus.ring_segments = 16
	ring_mesh.mesh = torus
	ring_mesh.rotation_degrees.x = 90
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = ring_color
	ring_mat.metallic = 0.9
	ring_mat.roughness = 0.2
	ring_mesh.material_override = ring_mat
	
	# Type indicator (output = green tint, input = orange tint)
	if jack_type == JackType.OUTPUT:
		ring_mat.albedo_color = ring_color.lerp(Color(0.2, 0.8, 0.3), 0.3)
	else:
		ring_mat.albedo_color = ring_color.lerp(Color(0.9, 0.5, 0.2), 0.3)
	
	# Label
	var label = Label3D.new()
	label.name = "ParamLabel"
	label.text = parameter_name.to_upper() if parameter_name else ("OUT" if jack_type == JackType.OUTPUT else "IN")
	label.font_size = 24
	label.pixel_size = 0.0005
	label.position = Vector3(0, socket_radius + 0.015, 0.005)
	label.modulate = Color(0.7, 0.7, 0.7)
	add_child(label)


func _setup_detection():
	# Create detection area for cable plugs
	if not socket_area:
		socket_area = Area3D.new()
		socket_area.name = "SocketArea"
		add_child(socket_area)
		
		var collision = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = socket_radius * 2.5  # Detection range
		collision.shape = sphere
		socket_area.add_child(collision)
	
	socket_area.body_entered.connect(_on_body_entered)
	socket_area.body_exited.connect(_on_body_exited)
	socket_area.area_entered.connect(_on_area_entered)
	socket_area.area_exited.connect(_on_area_exited)


func _on_body_entered(body: Node3D):
	_try_connect(body)


func _on_area_entered(area: Area3D):
	var parent = area.get_parent()
	if parent:
		_try_connect(parent)


func _on_body_exited(body: Node3D):
	_try_disconnect(body)


func _on_area_exited(area: Area3D):
	var parent = area.get_parent()
	if parent:
		_try_disconnect(parent)


func _try_connect(node: Node3D):
	if is_connected:
		return
	
	# Check if this is a cable plug
	if node.has_method("is_synth_plug") and node.is_synth_plug():
		var plug = node
		var plug_type = plug.get_plug_type() if plug.has_method("get_plug_type") else null
		
		# Only connect if types match (output jack → input plug, input jack → output plug)
		# Or if plug is neutral
		if plug_type != null and plug_type != _opposite_type():
			return
		
		# Check if plug is being held (only connect when released)
		if plug.has_method("is_being_held") and plug.is_being_held():
			return
		
		_connect_plug(plug)


func _try_disconnect(node: Node3D):
	if not is_connected:
		return
	
	if node == connected_plug:
		# Only disconnect if plug is being grabbed
		if node.has_method("is_being_held") and node.is_being_held():
			_disconnect_plug()


func _connect_plug(plug: Node3D):
	connected_plug = plug
	is_connected = true
	
	# Snap plug to socket position
	if plug.has_method("snap_to_jack"):
		plug.snap_to_jack(self)
	
	# Update visuals
	_set_connected_visual(true)
	
	# Get cable reference
	var cable = plug.get_parent() if plug.get_parent().has_method("is_synth_cable") else plug
	cable_connected.emit(cable, plug)
	
	print("SynthJack: Connected plug to %s (%s)" % [parameter_name, "OUTPUT" if jack_type == JackType.OUTPUT else "INPUT"])


func _disconnect_plug():
	var old_plug = connected_plug
	var cable = old_plug.get_parent() if old_plug.get_parent().has_method("is_synth_cable") else old_plug
	
	connected_plug = null
	is_connected = false
	
	# Update visuals
	_set_connected_visual(false)
	
	cable_disconnected.emit(cable, old_plug)
	
	print("SynthJack: Disconnected from %s" % parameter_name)


func _set_connected_visual(connected: bool):
	if ring_mesh and ring_mesh.material_override:
		var mat = ring_mesh.material_override as StandardMaterial3D
		if connected:
			mat.emission_enabled = true
			mat.emission = connected_color
			mat.emission_energy_multiplier = 0.5
		else:
			mat.emission_enabled = false


func _opposite_type() -> JackType:
	return JackType.INPUT if jack_type == JackType.OUTPUT else JackType.OUTPUT


## API for cable system
func get_parameter_name() -> String:
	return parameter_name


func get_jack_type() -> JackType:
	return jack_type


func is_output() -> bool:
	return jack_type == JackType.OUTPUT


func is_input() -> bool:
	return jack_type == JackType.INPUT


func get_connected_plug() -> Node3D:
	return connected_plug


func get_socket_position() -> Vector3:
	return global_position + global_transform.basis.z * (-socket_depth * 0.8)


func force_disconnect():
	if is_connected:
		_disconnect_plug()
