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
	# Use the requested scene: grab_sphere_point.tscn
	var point_scene = load("res://commons/primitives/point/grab_sphere_point.tscn")
	if point_scene:
		var point_instance = point_scene.instantiate()
		point_instance.position = origin
		add_child(point_instance)
	else:
		# Fallback if scene not found
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.01
		sphere_mesh.height = 0.025
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = sphere_mesh
		mesh_instance.position = origin
		add_child(mesh_instance)

	# Add a label
	var label = Label3D.new()
	label.text = ORIGIN_ALIASES[_alias_index]
	label.position = Vector3(0, 0.15, 0) # Slightly above
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y  # Billboard with Y-axis only rotation
	# Small 3D text
	label.pixel_size = 0.001 # Even smaller
	label.font_size = 64 # High res texture
	label.outline_size = 8
	label.modulate = Color(1.0, 0.5, 0.8) # Pinkish
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
