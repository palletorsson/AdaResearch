extends Node3D

# @identity
# essence: (0, 0, 0) — the reference from which all coordinates are measured
# desire: learner viscerally locates themselves relative to the world's fixed anchor
# critical_parameter: spinning octahedron at origin, cycling alias labels (origin / home / zero / (0,0,0))
# triggers: proximity — labels cycle on a timer to reinforce multiple names for the same concept
# emerges: understanding that "zero" is a choice, not a given — every coordinate system has an origin
# needs: [missing VR controls — atmospheric/reference object only]
# relationships: prerequisite for all spatial reasoning; every other artifact measures itself from here
# truth: the origin is a convention, not a place — but every space must agree on one

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

@export var octahedron_size: float = 0.05
@export var rotation_speed: float = 0.5  # Rotations per second
@export var octahedron_color: Color = Color(0.0, 1.0, 1.0)  # Cyan

# The origin - the center of our 3D universe
var origin = Vector3(0, 0, 0)
var _origin_label: Label3D
var _alias_index := 0
var _alias_timer: Timer
var _octahedron: MeshInstance3D

func _ready():
	print("The center of our 3D universe: ", origin)

	# Create a visual representation of the origin
	create_origin_marker()
	_start_origin_alias_cycle()

func _process(delta: float):
	# Rotate the octahedron
	if _octahedron:
		_octahedron.rotate_y(delta * rotation_speed * TAU)
		_octahedron.rotate_x(delta * rotation_speed * TAU * 0.3)

func create_origin_marker():
	"""Create a small rotating octahedron to mark the origin point"""
	_octahedron = MeshInstance3D.new()
	_octahedron.name = "OriginOctahedron"
	_octahedron.mesh = _create_octahedron_mesh(octahedron_size)
	_octahedron.position = origin

	# Create emissive material
	var material = StandardMaterial3D.new()
	material.albedo_color = octahedron_color
	material.emission_enabled = true
	material.emission = octahedron_color
	material.emission_energy_multiplier = 2.0
	_octahedron.material_override = material

	add_child(_octahedron)

	# Add a label (fixed in space, does not rotate to face camera)
	var label = Label3D.new()
	label.text = ORIGIN_ALIASES[_alias_index]
	label.position = Vector3(0, 0.15, 0) # Slightly above
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y  # Rotates to face camera on Y axis only
	# Small 3D text
	label.pixel_size = 0.001 # Even smaller
	label.font_size = 64 # High res texture
	label.outline_size = 8
	label.modulate = Color(1.0, 0.5, 0.8) # Pinkish
	add_child(label)
	_origin_label = label

func _create_octahedron_mesh(size: float) -> ArrayMesh:
	"""Create an octahedron mesh with 6 vertices and 8 triangular faces"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 6 vertices of octahedron (along each axis)
	var top = Vector3(0, size, 0)
	var bottom = Vector3(0, -size, 0)
	var front = Vector3(0, 0, size)
	var back = Vector3(0, 0, -size)
	var right = Vector3(size, 0, 0)
	var left = Vector3(-size, 0, 0)

	# 8 triangular faces (4 top, 4 bottom)
	# Top faces (CCW when viewed from outside)
	_add_triangle(st, top, front, right)
	_add_triangle(st, top, right, back)
	_add_triangle(st, top, back, left)
	_add_triangle(st, top, left, front)

	# Bottom faces
	_add_triangle(st, bottom, right, front)
	_add_triangle(st, bottom, back, right)
	_add_triangle(st, bottom, left, back)
	_add_triangle(st, bottom, front, left)

	return st.commit()

func _add_triangle(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3):
	var normal = (v1 - v0).cross(v2 - v0).normalized()
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)


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
