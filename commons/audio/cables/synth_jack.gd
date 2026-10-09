extends Node3D
class_name SynthJack

## A jack socket on a synth module that can receive cable plugs
## Supports both input and output types with parameter binding

signal cable_connected(cable: Node3D, plug: Node3D)
signal cable_disconnected(cable: Node3D, plug: Node3D)

enum JackType { OUTPUT, INPUT }

@export var jack_type: JackType = JackType.OUTPUT
@export var signal_kind := "audio"
@export var parameter_name: String = ""  ## e.g., "frequency", "amplitude"
@export var jack_color: Color = Color(0.2, 0.2, 0.25)
@export var ring_color: Color = Color(0.8, 0.8, 0.8)
@export var connected_color: Color = Color(0.2, 1.0, 0.4)  ## Glow when connected
@export var socket_radius: float = 0.012
@export var socket_depth: float = 0.015

var manager: SynthCableManager

class SocketPointer extends StaticBody3D:
	var jack: SynthJack
	func pointer_event(event) -> void:
		if event.event_type == 2 and jack.manager: jack.manager.select_jack(jack)

var connected_plug: Node3D = null
var is_connected: bool = false
var level: float = 1.0  ## 0.0–1.0 attenuation, controlled by level slider
var level_slider: Node3D = null  ## Reference to the attached slider_smooth instance

var socket_area: Area3D = null
var socket_mesh: MeshInstance3D = null
var ring_mesh: MeshInstance3D = null
var glow_light: OmniLight3D = null


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
	cyl.radial_segments = 24
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
	torus.rings = 16
	torus.ring_segments = 24
	ring_mesh.mesh = torus
	ring_mesh.rotation_degrees.x = 90
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = ring_color
	ring_mat.metallic = 0.9
	ring_mat.roughness = 0.2
	ring_mesh.material_override = ring_mat
	
	# Type indicator — strong distinction: output=orange, input=blue
	var type_color: Color
	if jack_type == JackType.OUTPUT:
		type_color = Color(0.95, 0.45, 0.15)  # Orange
		ring_mat.albedo_color = ring_color.lerp(type_color, 0.6)
	else:
		type_color = Color(0.27, 0.55, 0.95)  # Blue
		ring_mat.albedo_color = ring_color.lerp(type_color, 0.6)

	# Emissive ring for visibility in VR
	ring_mat.emission_enabled = true
	ring_mat.emission = type_color
	ring_mat.emission_energy_multiplier = 0.4


func _setup_detection():
	var pointer := SocketPointer.new(); pointer.jack = self
	pointer.collision_layer = (1 << 20) | (1 << 22); pointer.collision_mask = 0
	var col := CollisionShape3D.new(); var sphere := SphereShape3D.new()
	sphere.radius = socket_radius * 1.7; col.shape = sphere
	pointer.add_child(col); add_child(pointer)

func _connect_plug(plug: Node3D):
	return plug.snap_to_jack(self)

func _disconnect_plug():
	if is_instance_valid(connected_plug): connected_plug._unsnap()

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
