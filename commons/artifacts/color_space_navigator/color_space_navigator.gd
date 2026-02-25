extends Node3D
class_name ColorSpaceNavigator

## 3D RGB color cube — walk through color as a navigable 3D space.
## Eight corner spheres show primary/secondary colors, edges outline the cube,
## and ~500 random sample points fill the interior via MultiMesh.

# --- Configuration ---

@export var cube_size: float = 0.7
@export var sample_count: int = 500
@export var corner_radius: float = 0.018
@export var sample_radius: float = 0.006
@export var show_hsl_cylinder: bool = true

# --- Internal ---

var _rng: RandomNumberGenerator
var _edge_mesh: MeshInstance3D
var _sample_multimesh: MultiMeshInstance3D
var _hsl_edge_mesh: MeshInstance3D
var _hsl_sample_multimesh: MultiMeshInstance3D


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42
	_build_rgb_cube()
	if show_hsl_cylinder:
		_build_hsl_cylinder()


# =============================================================================
# RGB Cube
# =============================================================================

func _build_rgb_cube() -> void:
	var half := cube_size * 0.5

	# --- Cube wireframe edges ---
	_edge_mesh = MeshInstance3D.new()
	_edge_mesh.name = "RGBEdges"
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	# 8 corners in RGB order mapped to local positions
	# Corner (r,g,b) -> position (x, y, z) = (r-0.5, g-0.5, b-0.5) * cube_size
	var corners: Array[Vector3] = []
	var corner_colors: Array[Color] = []
	for r in range(2):
		for g in range(2):
			for b in range(2):
				corners.append(Vector3(r - 0.5, g - 0.5, b - 0.5) * cube_size)
				corner_colors.append(Color(float(r), float(g), float(b)))

	# 12 edges of a cube: connect corners that differ in exactly one axis
	var edges: Array[Array] = [
		[0, 1], [0, 2], [0, 4],  # from (0,0,0)
		[1, 3], [1, 5],          # from (1,0,0)
		[2, 3], [2, 6],          # from (0,1,0)
		[3, 7],                   # from (1,1,0)
		[4, 5], [4, 6],          # from (0,0,1)
		[5, 7], [6, 7],          # remaining
	]

	for e in edges:
		var a: int = e[0]
		var b: int = e[1]
		# Lerp color along edge for visual clarity
		im.surface_set_color(corner_colors[a])
		im.surface_add_vertex(corners[a])
		im.surface_set_color(corner_colors[b])
		im.surface_add_vertex(corners[b])

	im.surface_end()
	_edge_mesh.mesh = im

	var edge_mat := StandardMaterial3D.new()
	edge_mat.vertex_color_use_as_albedo = true
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_edge_mesh.material_override = edge_mat
	add_child(_edge_mesh)

	# --- Corner spheres ---
	for i in range(corners.size()):
		var sphere_inst := MeshInstance3D.new()
		sphere_inst.name = "Corner_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = corner_radius
		sphere.height = corner_radius * 2.0
		sphere.radial_segments = 12
		sphere.rings = 6
		sphere_inst.mesh = sphere
		sphere_inst.position = corners[i]

		var mat := StandardMaterial3D.new()
		mat.albedo_color = corner_colors[i]
		mat.emission_enabled = true
		mat.emission = corner_colors[i]
		mat.emission_energy_multiplier = 0.8
		# Make black corner slightly visible
		if corner_colors[i].r < 0.1 and corner_colors[i].g < 0.1 and corner_colors[i].b < 0.1:
			mat.albedo_color = Color(0.08, 0.08, 0.08)
			mat.emission = Color(0.05, 0.05, 0.05)
		sphere_inst.material_override = mat
		add_child(sphere_inst)

	# --- Sample points via MultiMesh ---
	_sample_multimesh = _create_sample_points_rgb()
	add_child(_sample_multimesh)

	# --- Axis labels ---
	_add_axis_label("R", Vector3(half + 0.06, -half, -half), Color.RED)
	_add_axis_label("G", Vector3(-half, half + 0.06, -half), Color.GREEN)
	_add_axis_label("B", Vector3(-half, -half, half + 0.06), Color(0.3, 0.3, 1.0))

	# --- Title ---
	var title := Label3D.new()
	title.name = "TitleRGB"
	title.text = "RGB Cube"
	title.font_size = 28
	title.pixel_size = 0.001
	title.modulate = Color.WHITE
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.position = Vector3(0, half + 0.08, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)


func _create_sample_points_rgb() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = sample_count

	var sphere := SphereMesh.new()
	sphere.radius = sample_radius
	sphere.height = sample_radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	mm.mesh = sphere

	for i in range(sample_count):
		var r := _rng.randf()
		var g := _rng.randf()
		var b := _rng.randf()

		var pos := Vector3(r - 0.5, g - 0.5, b - 0.5) * cube_size
		var t := Transform3D()
		t.origin = pos
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, Color(r, g, b))

	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.name = "RGBSamples"
	mm_inst.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm_inst.material_override = mat
	return mm_inst


func _add_axis_label(text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = "Label_%s" % text
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.001
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)


# =============================================================================
# HSL Cylinder (optional companion display)
# =============================================================================

func _build_hsl_cylinder() -> void:
	var offset := Vector3(cube_size + 0.3, 0, 0)
	var cyl_radius := cube_size * 0.35
	var cyl_height := cube_size * 0.8
	var half_h := cyl_height * 0.5
	var ring_count := 24
	var stack_count := 12

	# --- Cylinder wireframe ---
	_hsl_edge_mesh = MeshInstance3D.new()
	_hsl_edge_mesh.name = "HSLEdges"
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw horizontal rings at different lightness levels
	for s in range(stack_count + 1):
		var y := -half_h + cyl_height * float(s) / float(stack_count)
		var lightness := float(s) / float(stack_count)
		for r_idx in range(ring_count):
			var angle_a := TAU * float(r_idx) / float(ring_count)
			var angle_b := TAU * float(r_idx + 1) / float(ring_count)
			var hue_a := float(r_idx) / float(ring_count)
			var hue_b := float(r_idx + 1) / float(ring_count)

			var pa := Vector3(cos(angle_a) * cyl_radius, y, sin(angle_a) * cyl_radius) + offset
			var pb := Vector3(cos(angle_b) * cyl_radius, y, sin(angle_b) * cyl_radius) + offset

			var col_a := Color.from_hsv(hue_a, 1.0, lightness)
			var col_b := Color.from_hsv(hue_b, 1.0, lightness)

			im.surface_set_color(col_a)
			im.surface_add_vertex(pa)
			im.surface_set_color(col_b)
			im.surface_add_vertex(pb)

	# Draw vertical lines at each hue
	for r_idx in range(ring_count):
		var angle := TAU * float(r_idx) / float(ring_count)
		var hue := float(r_idx) / float(ring_count)
		var xa := cos(angle) * cyl_radius
		var za := sin(angle) * cyl_radius
		var bottom := Vector3(xa, -half_h, za) + offset
		var top := Vector3(xa, half_h, za) + offset

		im.surface_set_color(Color.from_hsv(hue, 1.0, 0.0))
		im.surface_add_vertex(bottom)
		im.surface_set_color(Color.from_hsv(hue, 1.0, 1.0))
		im.surface_add_vertex(top)

	im.surface_end()
	_hsl_edge_mesh.mesh = im

	var edge_mat := StandardMaterial3D.new()
	edge_mat.vertex_color_use_as_albedo = true
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hsl_edge_mesh.material_override = edge_mat
	add_child(_hsl_edge_mesh)

	# --- HSL sample points via MultiMesh ---
	_hsl_sample_multimesh = _create_sample_points_hsl(offset, cyl_radius, cyl_height)
	add_child(_hsl_sample_multimesh)

	# --- Axis labels ---
	_add_axis_label("H", Vector3(cyl_radius + 0.06, 0, 0) + offset, Color(1.0, 0.7, 0.3))
	_add_axis_label("S", Vector3(0, 0, cyl_radius + 0.06) + offset, Color(0.7, 0.7, 0.7))
	_add_axis_label("L", Vector3(0, half_h + 0.06, 0) + offset, Color.WHITE)

	# --- Title ---
	var title := Label3D.new()
	title.name = "TitleHSL"
	title.text = "HSV Cylinder"
	title.font_size = 28
	title.pixel_size = 0.001
	title.modulate = Color.WHITE
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.position = Vector3(0, half_h + 0.08, 0) + offset
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)


func _create_sample_points_hsl(offset: Vector3, radius: float, height: float) -> MultiMeshInstance3D:
	var half_h := height * 0.5
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = sample_count

	var sphere := SphereMesh.new()
	sphere.radius = sample_radius
	sphere.height = sample_radius * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	mm.mesh = sphere

	for i in range(sample_count):
		var hue := _rng.randf()
		var sat := _rng.randf()
		var val := _rng.randf()

		var angle := hue * TAU
		var r := sat * radius
		var y := -half_h + val * height

		var pos := Vector3(cos(angle) * r, y, sin(angle) * r) + offset
		var t := Transform3D()
		t.origin = pos
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, Color.from_hsv(hue, sat, val))

	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.name = "HSLSamples"
	mm_inst.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm_inst.material_override = mat
	return mm_inst


# =============================================================================
# Grid system integration
# =============================================================================

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("cube_size"):
		cube_size = float(config_data["cube_size"])
	if config_data.has("sample_count"):
		sample_count = int(config_data["sample_count"])
	if config_data.has("show_hsl"):
		show_hsl_cylinder = bool(config_data["show_hsl"])
