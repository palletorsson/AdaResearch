# RightTriangle.gd - 90 degree right triangle leaning right in black
extends Node3D
class_name RightTriangle

# @identity
# essence: right_triangle(base, height) with 90° angle at origin — the geometric primitive of Pythagoras
# desire: learner has a reference form for right angles to which other geometry is compared
# critical_parameter: the right angle at the origin — this defines the shape; moving it makes it non-right
# triggers: nothing — static reference object; thin (0.05 depth) for readability as a 2D form in 3D space
# emerges: the usefulness of black — a neutral diagnostic color that does not compete with adjacent color coding
# needs: [missing VR controls — static display only]
# relationships: used in Trans_RotationSpectacle map; sibling to pythagorean_triangle_angles
# truth: the right angle is the basis of all rectangular coordinate systems — it defines what "perpendicular" means

# --- DNA (stage 2, promoted 2026-07-29) --------------------------------------
# proportion: which right triangle this is. The legs were both hard-coded to
#   triangle_size, i.e. the isoceles case — the one whose hypotenuse is
#   irrational. Turning this knob changes the claim: "isoceles" says the metre
#   grid cannot name my longest side; "3-4-5" says the rope-stretchers could
#   build me with knots and whole numbers; "1-2" generates root five;
#   "kepler" makes the legs 1 : sqrt(phi) so the sides are in golden ratio.
# reading: how the form asks to be read. It was one uniform black slab —
#   deliberately mute. "corner_marked" adds the draughtsman's square glyph at
#   the origin, naming the invariant out loud. "legs_hypotenuse" colours the
#   two legs against the derived third side, so the Pythagorean relation is
#   visible instead of implied.
# Defaults proportion="isoceles" + reading="uniform" reproduce the original
# mesh vertex-for-vertex and add no extra nodes.
# -----------------------------------------------------------------------------

@export_enum("isoceles", "3-4-5", "1-2", "kepler") var proportion: String = "isoceles"
@export_enum("uniform", "corner_marked", "legs_hypotenuse") var reading: String = "uniform"

var base_color: Color = Color(0.1, 0.1, 0.1)  # Black
var triangle_size: float = 1.0

# Leg ratios normalised so the longer leg is always 1.0 — the footprint never grows.
var LEG_RATIOS: Dictionary = {
	"isoceles": Vector2(1.0, 1.0),
	"3-4-5": Vector2(0.75, 1.0),
	"1-2": Vector2(0.5, 1.0),
	"kepler": Vector2(0.7861513777574233, 1.0),  # 1 / sqrt(phi)
}
const READINGS := ["uniform", "corner_marked", "legs_hypotenuse"]

const SLAB_DEPTH := 0.1
const LEG_MARK_COLOR := Color(0.15, 0.75, 0.85)   # cyan — the two given sides
const HYP_MARK_COLOR := Color(0.9, 0.25, 0.55)    # pink — the derived side
const CORNER_MARK_COLOR := Color(0.95, 0.95, 0.95)

var _parts: Array[Node3D] = []
var _built: bool = false

func _ready():
	create_right_triangle()

# Leg lengths in metres for the current proportion.
func _leg_lengths() -> Vector2:
	var ratio: Vector2 = LEG_RATIOS.get(proportion, LEG_RATIOS["isoceles"])
	return ratio * triangle_size

func create_right_triangle():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_triangle_vertices()
	var faces = create_triangle_faces()

	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RightTriangle"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)
	_parts.append(mesh_instance)

	_build_reading_marks()
	_built = true

func create_triangle_vertices() -> Array:
	var vertices = []
	var legs: Vector2 = _leg_lengths()
	var bx: float = legs.x
	var by: float = legs.y

	# Create a right triangle leaning right
	# The triangle will have its right angle at the origin
	# and lean towards the positive X direction
	vertices.append_array([
		# Front face vertices (Z = 0)
		Vector3(0, 0, 0),           # 0: origin (right angle)
		Vector3(bx, 0, 0),          # 1: right point
		Vector3(0, by, 0),          # 2: top point

		# Back face vertices (Z = -0.1 for thin depth)
		Vector3(0, 0, -SLAB_DEPTH),   # 3: origin back
		Vector3(bx, 0, -SLAB_DEPTH),  # 4: right point back
		Vector3(0, by, -SLAB_DEPTH)   # 5: top point back
	])

	return vertices

func create_triangle_faces() -> Array:
	# Create faces for a thin 3D triangle
	var faces = [
		# Front face
		[0, 1, 2],  # Main triangle face (counter-clockwise)

		# Back face
		[3, 5, 4],  # Back triangle face (clockwise from back)

		# Side edges (thin rectangular faces)
		# Bottom edge (connecting origins to right points)
		[0, 4, 3],  # Triangle 1
		[0, 1, 4],  # Triangle 2

		# Right edge (connecting right points to top points)
		[1, 5, 4],  # Triangle 1
		[1, 2, 5],  # Triangle 2

		# Hypotenuse edge (connecting top points to origins)
		[2, 3, 5],  # Triangle 1
		[2, 0, 3]   # Triangle 2
	]

	return faces

# --- reading marks -----------------------------------------------------------

func _build_reading_marks() -> void:
	if reading == "uniform":
		return

	var legs: Vector2 = _leg_lengths()
	var bx: float = legs.x
	var by: float = legs.y
	# Marks sit just proud of both faces so the form reads from either side.
	var planes: Array[float] = [0.014, -SLAB_DEPTH - 0.014]

	if reading == "corner_marked":
		var g: float = min(bx, by) * 0.18
		var t: float = min(bx, by) * 0.035
		for z: float in planes:
			_add_bar(Vector3(0, g, z), Vector3(g, g, z), t, CORNER_MARK_COLOR, "CornerMarkH")
			_add_bar(Vector3(g, 0, z), Vector3(g, g, z), t, CORNER_MARK_COLOR, "CornerMarkV")
	elif reading == "legs_hypotenuse":
		var t2: float = min(bx, by) * 0.045
		for z: float in planes:
			_add_bar(Vector3(0, 0, z), Vector3(bx, 0, z), t2, LEG_MARK_COLOR, "LegBase")
			_add_bar(Vector3(0, 0, z), Vector3(0, by, z), t2, LEG_MARK_COLOR, "LegHeight")
			_add_bar(Vector3(bx, 0, z), Vector3(0, by, z), t2, HYP_MARK_COLOR, "Hypotenuse")

# All marks lie in the XY plane, so a single rotation about Z aims the bar.
func _add_bar(from_p: Vector3, to_p: Vector3, thickness: float, color: Color, bar_name: String) -> void:
	var length: float = from_p.distance_to(to_p)
	if length <= 0.0 or thickness <= 0.0:
		return
	var box := BoxMesh.new()
	box.size = Vector3(length, thickness, thickness)

	var mi := MeshInstance3D.new()
	mi.name = bar_name
	mi.mesh = box
	mi.position = (from_p + to_p) * 0.5
	var dir: Vector3 = to_p - from_p
	mi.rotation = Vector3(0.0, 0.0, atan2(dir.y, dir.x))
	apply_queer_material(mi, color)
	add_child(mi)
	_parts.append(mi)

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the SimpleGrid shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader

		# Set shader parameters
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)

		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	if _built:
		_rebuild()

func set_triangle_size(size: float):
	if size <= 0.0 or is_equal_approx(size, triangle_size):
		return
	triangle_size = size
	if _built:
		_rebuild()

# --- grid config -------------------------------------------------------------

# Guarded: only rebuilds when a declared axis actually changed AND the first
# build has already happened. Shipped placements that pass no config are never
# touched.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false

	if config_data.has("proportion"):
		var p: String = str(config_data["proportion"])
		if LEG_RATIOS.has(p) and p != proportion:
			proportion = p
			dirty = true

	if config_data.has("reading"):
		var r: String = str(config_data["reading"])
		if READINGS.has(r) and r != reading:
			reading = r
			dirty = true

	if config_data.has("triangle_size"):
		var s: float = float(config_data["triangle_size"])
		if s > 0.0 and not is_equal_approx(s, triangle_size):
			triangle_size = s
			dirty = true

	if config_data.has("base_color"):
		var c: Color = _color_from(config_data["base_color"], base_color)
		if c != base_color:
			base_color = c
			dirty = true

	if dirty and _built:
		_rebuild()

func _color_from(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String and Color.html_is_valid(value):
		return Color.html(value)
	return fallback

func _rebuild() -> void:
	for part: Node3D in _parts:
		if is_instance_valid(part):
			remove_child(part)
			part.queue_free()
	_parts.clear()
	_built = false
	create_right_triangle()
