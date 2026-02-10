extends Node3D

@export var total_canvases: int = 98
@export var columns: int = 14
@export var rows: int = 7

@export var canvas_size: float = 0.38
@export var canvas_depth: float = 0.04
@export var canvas_color: Color = Color(0.98, 0.98, 0.97, 1.0)

@export var frame_thickness: float = 0.02
@export var frame_depth: float = 0.03
@export var frame_color: Color = Color(0.08, 0.08, 0.09, 1.0)

@export var show_wall: bool = true
@export var show_floor: bool = false
@export var show_frames: bool = true
@export var show_canvas: bool = true

@export var gap: float = 0.08
@export var wall_margin: float = 0.7
@export var wall_depth: float = 0.12
@export var wall_color: Color = Color(0.97, 0.97, 0.97, 1.0)

@export var squares_per_canvas: int = 5
@export var inset_ratio: float = 0.78
@export var border_ratio: float = 0.05
@export var vertical_bias: float = -0.06

@export_category("Lighting")
@export var ambient_energy: float = 0.6
@export var spot_count: int = 4
@export var spot_energy: float = 6.0
@export var spot_angle: float = 55.0
@export var spot_range: float = 10.0
@export var spot_height: float = 3.8
@export var spot_distance: float = 2.4
@export var spot_color: Color = Color(1.0, 0.98, 0.92, 1.0)

@export_category("Palette")
@export var palette_seed: int = 1337
@export_range(0.0, 1.0, 0.01) var palette_saturation_min: float = 0.35
@export_range(0.0, 1.0, 0.01) var palette_saturation_max: float = 0.9
@export_range(0.0, 1.0, 0.01) var palette_value_min: float = 0.6
@export_range(0.0, 1.0, 0.01) var palette_value_max: float = 0.98

var _paint_material: StandardMaterial3D
var _frame_material: StandardMaterial3D
var _canvas_material: StandardMaterial3D
var _wall_material: StandardMaterial3D
var _wall_size: Vector2

func _ready() -> void:
	_ensure_materials()
	_build_wall()
	_build_canvases()
	_build_lighting()

func _ensure_materials() -> void:
	_paint_material = StandardMaterial3D.new()
	_paint_material.vertex_color_use_as_albedo = true
	_paint_material.albedo_color = Color.WHITE
	_paint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_paint_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_paint_material.roughness = 0.9
	_paint_material.metallic = 0.0

	_frame_material = _make_solid_material(frame_color, 0.85)
	_canvas_material = _make_solid_material(canvas_color, 0.9)
	_wall_material = _make_solid_material(wall_color, 0.95)

func _build_wall() -> void:
	var width = columns * canvas_size + (columns - 1) * gap + wall_margin * 2.0
	var height = rows * canvas_size + (rows - 1) * gap + wall_margin * 2.0
	_wall_size = Vector2(width, height)

	if show_wall:
		var wall = MeshInstance3D.new()
		wall.name = "AlbersWall"
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(width, height, wall_depth)
		wall.mesh = wall_mesh
		wall.material_override = _wall_material
		wall.position = Vector3(0.0, height * 0.5, 0.0)
		add_child(wall)

	if show_floor:
		var floor = MeshInstance3D.new()
		floor.name = "GalleryFloor"
		var floor_mesh = BoxMesh.new()
		floor_mesh.size = Vector3(width + 2.0, 0.08, 3.0)
		floor.mesh = floor_mesh
		floor.material_override = _make_solid_material(Color(0.94, 0.94, 0.94, 1.0), 0.92)
		floor.position = Vector3(0.0, -0.04, 1.1)
		add_child(floor)

func _build_canvases() -> void:
	var width = _wall_size.x
	var height = _wall_size.y
	var start_x = -width * 0.5 + wall_margin + canvas_size * 0.5
	var start_y = wall_margin + canvas_size * 0.5
	var wall_front = wall_depth * 0.5 if show_wall else 0.0
	var frame_z = wall_front + frame_depth * 0.5 + 0.01
	var canvas_z = wall_front + canvas_depth * 0.5 + 0.015
	var paint_z = wall_front + canvas_depth + 0.02

	var index = 0
	for row in range(rows):
		var y = start_y + (rows - 1 - row) * (canvas_size + gap)
		for col in range(columns):
			if index >= total_canvases:
				return
			var x = start_x + col * (canvas_size + gap)
			var canvas_root = Node3D.new()
			canvas_root.name = "Canvas_%02d" % index
			canvas_root.position = Vector3(x, y, 0.0)
			add_child(canvas_root)

			if show_frames:
				# Create 4-bar picture frame (hollow, not solid)
				var half_size = canvas_size * 0.5
				var bar_length = canvas_size + frame_thickness * 2.0
				
				# Top bar
				var top_bar = MeshInstance3D.new()
				var top_mesh = BoxMesh.new()
				top_mesh.size = Vector3(bar_length, frame_thickness, frame_depth)
				top_bar.mesh = top_mesh
				top_bar.material_override = _frame_material
				top_bar.position = Vector3(0.0, half_size + frame_thickness * 0.5, frame_z)
				canvas_root.add_child(top_bar)
				
				# Bottom bar
				var bottom_bar = MeshInstance3D.new()
				bottom_bar.mesh = top_mesh
				bottom_bar.material_override = _frame_material
				bottom_bar.position = Vector3(0.0, -half_size - frame_thickness * 0.5, frame_z)
				canvas_root.add_child(bottom_bar)
				
				# Left bar
				var left_bar = MeshInstance3D.new()
				var side_mesh = BoxMesh.new()
				side_mesh.size = Vector3(frame_thickness, canvas_size, frame_depth)
				left_bar.mesh = side_mesh
				left_bar.material_override = _frame_material
				left_bar.position = Vector3(-half_size - frame_thickness * 0.5, 0.0, frame_z)
				canvas_root.add_child(left_bar)
				
				# Right bar
				var right_bar = MeshInstance3D.new()
				right_bar.mesh = side_mesh
				right_bar.material_override = _frame_material
				right_bar.position = Vector3(half_size + frame_thickness * 0.5, 0.0, frame_z)
				canvas_root.add_child(right_bar)

			if show_canvas:
				var canvas = MeshInstance3D.new()
				var canvas_mesh = BoxMesh.new()
				canvas_mesh.size = Vector3(canvas_size, canvas_size, canvas_depth)
				canvas.mesh = canvas_mesh
				canvas.material_override = _canvas_material
				canvas.position = Vector3(0.0, 0.0, canvas_z)
				canvas_root.add_child(canvas)

			var palette = _generate_palette(index)
			var painting = MeshInstance3D.new()
			painting.mesh = _make_homage_mesh(canvas_size, palette)
			painting.material_override = _paint_material
			painting.position = Vector3(0.0, 0.0, paint_z)
			canvas_root.add_child(painting)

			index += 1

func _build_lighting() -> void:
	var ambient = DirectionalLight3D.new()
	ambient.name = "AmbientFill"
	ambient.light_energy = ambient_energy
	ambient.rotation_degrees = Vector3(-35.0, 15.0, 0.0)
	add_child(ambient)

	if spot_count <= 0:
		return

	var width = _wall_size.x
	var height = _wall_size.y
	for i in range(spot_count):
		var t = 0.5 if spot_count == 1 else float(i) / float(spot_count - 1)
		var x = lerp(-width * 0.45, width * 0.45, t)
		var spot = SpotLight3D.new()
		spot.name = "Spot_%02d" % i
		spot.light_energy = spot_energy
		spot.light_color = spot_color
		spot.spot_angle = spot_angle
		spot.spot_range = spot_range
		spot.shadow_enabled = true
		spot.position = Vector3(x, height + 0.4, spot_distance)
		var target = Vector3(x, height * 0.45, 0.0)
		spot.look_at_from_position(spot.position, target, Vector3.UP)
		add_child(spot)

func _generate_palette(index: int) -> Array[Color]:
	var rng = RandomNumberGenerator.new()
	rng.seed = palette_seed + index * 31

	var base_hue = fposmod(0.61803398875 * float(index), 1.0)
	var hue_span = rng.randf_range(0.18, 0.36)
	var sat_outer = rng.randf_range(palette_saturation_min, palette_saturation_max)
	var val_outer = rng.randf_range(palette_value_min, palette_value_max)
	var sat_inner = rng.randf_range(max(0.4, palette_saturation_min), palette_saturation_max)
	var val_inner = rng.randf_range(max(0.7, palette_value_min), palette_value_max)

	var palette: Array[Color] = []
	for i in range(squares_per_canvas):
		var t = 0.0 if squares_per_canvas == 1 else float(i) / float(squares_per_canvas - 1)
		var hue = fposmod(base_hue + t * hue_span + rng.randf_range(-0.03, 0.03), 1.0)
		var sat = lerp(sat_outer, sat_inner, t)
		var val = lerp(val_outer, val_inner, t)
		palette.append(Color.from_hsv(hue, sat, val))
	return palette

func _make_homage_mesh(size: float, palette: Array[Color]) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var count = palette.size()
	var max_size = size * (1.0 - border_ratio * 2.0)
	var base_index = 0

	for i in range(count):
		var s = max_size * pow(inset_ratio, i)
		var half_s = s * 0.5
		var t = 0.0 if count <= 1 else float(i) / float(count - 1)
		var y_bias = vertical_bias * size * t
		var color = palette[i]

		vertices.append(Vector3(-half_s, -half_s + y_bias, 0.0))
		vertices.append(Vector3(half_s, -half_s + y_bias, 0.0))
		vertices.append(Vector3(half_s, half_s + y_bias, 0.0))
		vertices.append(Vector3(-half_s, half_s + y_bias, 0.0))

		for _j in range(4):
			normals.append(Vector3(0.0, 0.0, 1.0))
			colors.append(color)
			uvs.append(Vector2.ZERO)

		indices.append(base_index + 0)
		indices.append(base_index + 1)
		indices.append(base_index + 2)
		indices.append(base_index + 0)
		indices.append(base_index + 2)
		indices.append(base_index + 3)

		base_index += 4

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	if vertices.size() > 0:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func _make_solid_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	return mat
