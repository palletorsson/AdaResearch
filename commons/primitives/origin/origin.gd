extends Node3D

## AXIOM 0: The origin (0, 0, 0) is the reference point
## from which all positions are measured.

const ORIGIN_ALIASES := [
	"(0,0,0)",
	"Vector3(0, 0, 0)",
	"origin",
	"*",
	"Vector3.ZERO",
	"Zero Vector",
	"World origin", 
	"Coordinate zero",
	"The center of the coordinate system",
	"The birth of space", 
	"The coordinate of silence", 
	"The root of all vectors"
]

# The origin - the center of our 3D universe
var origin = Vector3(0, 0, 0)
var _origin_label: Label3D
var _alias_index := 0
var _alias_timer: Timer

func _ready():
	print("The center of our 3D universe: ", origin)

	# Create a visual representation of the origin
	create_origin_marker()
	_start_origin_alias_cycle()


func create_origin_marker():
	"""Create a small sphere to mark the origin point"""
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	sphere_mesh.height = 0.025

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = origin  # At (0, 0, 0)

	# Make it a bright color so it stands out
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy = 10.0
	mesh_instance.set_surface_override_material(0, material)

	add_child(mesh_instance)

	# Add a label
	var label = Label3D.new()
	label.text = ORIGIN_ALIASES[_alias_index]
	label.position = Vector3(0, 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 12
	label.modulate = Color.PINK
	add_child(label)
	_origin_label = label


func _start_origin_alias_cycle():
	if ORIGIN_ALIASES.is_empty() or _origin_label == null:
		return

	if _alias_timer:
		return

	_alias_timer = Timer.new()
	_alias_timer.wait_time = 1.5
	_alias_timer.autostart = true
	_alias_timer.timeout.connect(_on_origin_alias_timeout)
	add_child(_alias_timer)


func _on_origin_alias_timeout():
	if not _origin_label:
		return

	_alias_index = (_alias_index + 1) % ORIGIN_ALIASES.size()
	_origin_label.text = ORIGIN_ALIASES[_alias_index]
