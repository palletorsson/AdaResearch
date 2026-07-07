extends Node3D
class_name Origin

# @identity
# essence: (0, 0, 0) — the reference from which all coordinates are measured, made visible as a slowly-rotating cyan octahedron with cycling alias labels
# desire: learner viscerally locates themselves relative to the world's fixed anchor — understanding that "zero" is a name we agreed on
# critical_parameter: spinning octahedron at origin, cycling alias labels (origin / home / zero / (0,0,0) / Vector3.ZERO and 8 more)
# triggers: proximity — labels cycle on a timer to reinforce multiple names for the same concept; the octahedron rotates so the point reads as a *thing* and not just an idea
# emerges: understanding that "zero" is a choice, not a given — every coordinate system has an origin and they could have agreed on a different one
# needs: octahedron + alias cycle [present]; class_name Origin [present, 2026-05-19]; apply_grid_config [present, 2026-05-19]; VR controls [missing — atmospheric/reference object only]
# relationships: prerequisite for all spatial reasoning; the start-point of every CoordinateLine axis; the shared zero that CoordinateSystem3M assumes; visually distinct from point.gd (origin = THE origin, point = a movable position); paired with origin_test.tscn for the multi-origin demo
# truth: the origin is a convention, not a place — but every space must agree on one. The rotating octahedron makes the convention legible: a chosen object at a chosen zero.

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

## Vertical beam rising from the origin (metres). 0 = no beam (default, so
## other maps are unaffected). In Point One the origin sits below the lab
## floor; a beam carries the eye up through the floor window into the room.
@export var beam_height: float = 0.0
## Radius of the beam cylinder.
@export var beam_radius: float = 0.012
## Text shown at the TOP of the beam (where it enters the room). Empty = none.
@export var beam_label: String = "(0, 0, 0)"

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

	# Optional vertical beam rising from the origin (e.g. up through the lab
	# floor window into the room). Built here so apply_grid_config's rebuild
	# re-creates it.
	if beam_height > 0.0:
		_build_beam()


func _build_beam() -> void:
	# Emissive cylinder from the origin straight up beam_height metres.
	var beam := MeshInstance3D.new()
	beam.name = "OriginBeam"
	var cyl := CylinderMesh.new()
	cyl.top_radius = beam_radius
	cyl.bottom_radius = beam_radius
	cyl.height = beam_height
	cyl.radial_segments = 12
	beam.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = octahedron_color
	bmat.emission_enabled = true
	bmat.emission = octahedron_color
	bmat.emission_energy_multiplier = 1.6
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color.a = 0.7
	beam.material_override = bmat
	# Cylinder origin is its centre, so lift it half its height to start at 0.
	beam.position = Vector3(0, beam_height * 0.5, 0)
	add_child(beam)

	# Label at the TOP of the beam (where it meets the room).
	if beam_label != "":
		var top_label := Label3D.new()
		top_label.name = "OriginBeamLabel"
		top_label.text = beam_label
		top_label.position = Vector3(0, beam_height + 0.12, 0)
		top_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		top_label.pixel_size = 0.0015
		top_label.font_size = 64
		top_label.outline_size = 8
		top_label.modulate = octahedron_color
		top_label.outline_modulate = Color(0, 0, 0, 0.8)
		top_label.no_depth_test = true
		add_child(top_label)

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


## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "size" / "octahedron_size" — float, half-edge of the marker
##   "color"                    — Color or [r,g,b] array
##   "rotation_speed"           — float, rotations per second
## Unknown keys are ignored.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("size"):
		octahedron_size = float(config_data["size"])
	if config_data.has("octahedron_size"):
		octahedron_size = float(config_data["octahedron_size"])
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			octahedron_color = c
		elif c is Array and c.size() >= 3:
			octahedron_color = Color(float(c[0]), float(c[1]), float(c[2]))
	if config_data.has("rotation_speed"):
		rotation_speed = float(config_data["rotation_speed"])
	if config_data.has("beam_height"):
		beam_height = float(config_data["beam_height"])
	if config_data.has("beam_radius"):
		beam_radius = float(config_data["beam_radius"])
	if config_data.has("beam_label"):
		beam_label = str(config_data["beam_label"])
	# Rebuild if already constructed
	if _octahedron:
		# Clean and rebuild
		for c in get_children():
			if c is Timer:
				continue
			c.queue_free()
		_octahedron = null
		_origin_label = null
		create_origin_marker()
