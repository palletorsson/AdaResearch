@tool
extends Node3D

@export_range(4, 256, 1) var columns: int = 200
@export_range(4, 256, 1) var rows: int = 64
@export var corridor_length: float = 24.0
@export var corridor_width: float = 8.0
@export var corridor_height: float = 6.0

@export var base_frequency: float = 1.3
@export var base_amplitude: float = 1.4
@export var phase: float = 0.0
@export var phase_offset_between_walls: float = 0.6

@export var wave_layers: Array = [
	{"freq_mul": 1.0, "amp_mul": 1.0, "phase_shift": 0.0},
	{"freq_mul": 1.8, "amp_mul": 0.35, "phase_shift": 0.85},
	{"freq_mul": 2.6, "amp_mul": 0.18, "phase_shift": -0.35}
]

@export var bottom_color: Color = Color(0.08, 0.18, 0.35, 1.0)
@export var mid_color: Color = Color(0.28, 0.65, 0.85, 1.0)
@export var top_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var wall_emission: Color = Color(0.05, 0.16, 0.28, 1.0)

@export var auto_update_in_editor: bool = true

var _left_wall: MeshInstance3D
var _right_wall: MeshInstance3D
var _ceiling: MeshInstance3D
var _floor: MeshInstance3D
var _wall_material: StandardMaterial3D
var _floor_material: StandardMaterial3D
var _last_signature: String = ""

func _ready() -> void:
	_ensure_nodes()
	_build_corridor()
	_update_process_state()

func rebuild_corridor() -> void:
	_ensure_nodes()
	_build_corridor()

func _ensure_nodes() -> void:
	if not _wall_material:
		_wall_material = StandardMaterial3D.new()
		_wall_material.vertex_color_use_as_albedo = true
		_wall_material.roughness = 0.45
		_wall_material.metallic = 0.1
		_wall_material.emission_enabled = true
		_wall_material.emission = wall_emission
		_wall_material.emission_energy_multiplier = 0.45

	if not _floor_material:
		_floor_material = StandardMaterial3D.new()
		_floor_material.albedo_color = Color(0.04, 0.05, 0.07, 1.0)
		_floor_material.roughness = 0.7
		_floor_material.metallic = 0.05
		_floor_material.emission_enabled = true
		_floor_material.emission = Color(0.02, 0.03, 0.05)
		_floor_material.emission_energy_multiplier = 0.25

	_left_wall = _get_or_create_mesh_instance("LeftWall", _left_wall)
	_right_wall = _get_or_create_mesh_instance("RightWall", _right_wall)
	_ceiling = _get_or_create_mesh_instance("Ceiling", _ceiling)
	_floor = _get_or_create_mesh_instance("Floor", _floor)

	for mesh in [_left_wall, _right_wall]:
		mesh.material_override = _wall_material
	for mesh in [_ceiling, _floor]:
		mesh.material_override = _floor_material

func _get_or_create_mesh_instance(name: String, cache: MeshInstance3D) -> MeshInstance3D:
	if cache and is_instance_valid(cache):
		return cache
	var node := get_node_or_null(name) as MeshInstance3D
	if not node:
		node = MeshInstance3D.new()
		node.name = name
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(node)
	return node

func _build_corridor() -> void:
	if columns < 2 or rows < 2:
		return

	var signature := _make_signature()
	if signature == _last_signature:
		return

	var half_length := corridor_length * 0.5
	var half_width := corridor_width * 0.5
	var half_height := corridor_height * 0.5

	_left_wall.mesh = _create_wall_mesh(-1, half_length, half_width, half_height, phase)
	_right_wall.mesh = _create_wall_mesh(1, half_length, half_width, half_height, phase + phase_offset_between_walls)
	_ceiling.mesh = _create_plane_mesh(half_length, half_width, half_height, true)
	_floor.mesh = _create_plane_mesh(half_length, half_width, half_height, false)

	_left_wall.transform = Transform3D.IDENTITY
	_right_wall.transform = Transform3D.IDENTITY
	_floor.transform = Transform3D.IDENTITY
	_ceiling.transform = Transform3D.IDENTITY

	_last_signature = signature

func _create_wall_mesh(side: int, half_length: float, half_width: float, half_height: float, phase_shift: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var position_columns: Array[PackedVector3Array] = []
	var color_columns: Array[PackedColorArray] = []
	var uv_columns: Array[PackedVector2Array] = []

	for col in range(columns):
		var column_positions: PackedVector3Array = PackedVector3Array()
		var column_colors: PackedColorArray = PackedColorArray()
		var column_uvs: PackedVector2Array = PackedVector2Array()

		var z_ratio: float = col / float(columns - 1)
		var z_pos: float = lerp(-half_length, half_length, z_ratio)
		var displacement: float = _wave_displacement(z_ratio, phase_shift)
		var column_color: Color = _evaluate_color(displacement)

		for row in range(rows):
			var y_ratio: float = row / float(rows - 1)
			var y_pos: float = lerp(-half_height, half_height, y_ratio)
			var base_x: float = side * half_width
			var x_pos: float = base_x - side * displacement
			column_positions.append(Vector3(x_pos, y_pos, z_pos))
			column_colors.append(column_color)
			column_uvs.append(Vector2(z_ratio, y_ratio))

		position_columns.append(column_positions)
		color_columns.append(column_colors)
		uv_columns.append(column_uvs)

	for col in range(columns - 1):
		var left_positions: PackedVector3Array = position_columns[col]
		var right_positions: PackedVector3Array = position_columns[col + 1]
		var left_colors: PackedColorArray = color_columns[col]
		var right_colors: PackedColorArray = color_columns[col + 1]
		var left_uvs: PackedVector2Array = uv_columns[col]
		var right_uvs: PackedVector2Array = uv_columns[col + 1]

		for row in range(rows - 1):
			var v00: Vector3 = left_positions[row]
			var v10: Vector3 = right_positions[row]
			var v11: Vector3 = right_positions[row + 1]
			var v01: Vector3 = left_positions[row + 1]

			var c00: Color = left_colors[row]
			var c10: Color = right_colors[row]
			var c11: Color = right_colors[row + 1]
			var c01: Color = left_colors[row + 1]

			var uv00: Vector2 = left_uvs[row]
			var uv10: Vector2 = right_uvs[row]
			var uv11: Vector2 = right_uvs[row + 1]
			var uv01: Vector2 = left_uvs[row + 1]

			if side < 0:
				_add_triangle(st, v00, c00, uv00, v10, c10, uv10, v11, c11, uv11)
				_add_triangle(st, v00, c00, uv00, v11, c11, uv11, v01, c01, uv01)
			else:
				_add_triangle(st, v00, c00, uv00, v11, c11, uv11, v10, c10, uv10)
				_add_triangle(st, v00, c00, uv00, v01, c01, uv01, v11, c11, uv11)

	st.generate_normals()
	return st.commit()

func _add_triangle(st: SurfaceTool, a: Vector3, ca: Color, uva: Vector2, b: Vector3, cb: Color, uvb: Vector2, c: Vector3, cc: Color, uvc: Vector2) -> void:
	st.set_color(ca)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_color(cb)
	st.set_uv(uvb)
	st.add_vertex(b)
	st.set_color(cc)
	st.set_uv(uvc)
	st.add_vertex(c)

func _create_plane_mesh(half_length: float, half_width: float, half_height: float, is_ceiling: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var y: float = half_height if is_ceiling else -half_height
	var color: Color = mid_color

	var c0 := Vector3(-half_width, y, -half_length)
	var c1 := Vector3(half_width, y, -half_length)
	var c2 := Vector3(half_width, y, half_length)
	var c3 := Vector3(-half_width, y, half_length)

	if is_ceiling:
		_add_triangle(st, c0, color, Vector2(0, 0), c1, color, Vector2(1, 0), c2, color, Vector2(1, 1))
		_add_triangle(st, c0, color, Vector2(0, 0), c2, color, Vector2(1, 1), c3, color, Vector2(0, 1))
	else:
		_add_triangle(st, c0, color, Vector2(0, 0), c2, color, Vector2(1, 1), c1, color, Vector2(1, 0))
		_add_triangle(st, c0, color, Vector2(0, 0), c3, color, Vector2(0, 1), c2, color, Vector2(1, 1))

	st.generate_normals()
	return st.commit()

func _wave_displacement(z_ratio: float, phase_shift: float) -> float:
	var z_norm: float = z_ratio * 2.0 - 1.0
	var offset: float = 0.0
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
		offset += base_amplitude * amp_mul * sin((base_frequency * freq_mul) * z_norm * PI + phase + phase_shift + phase_layer)
	return offset

func _evaluate_color(displacement: float) -> Color:
	var intensity: float = (displacement / (base_amplitude * 1.6)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)
	var blend: float = clamp(intensity * 1.8, 0.0, 1.0)
	var color: Color = bottom_color.lerp(mid_color, blend)
	color = color.lerp(top_color, intensity)
	return color

func _make_signature() -> String:
	return str(columns, rows, corridor_length, corridor_width, corridor_height, base_frequency, base_amplitude, phase, phase_offset_between_walls, wave_layers, bottom_color, mid_color, top_color)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if not auto_update_in_editor:
		return
	var signature := _make_signature()
	if signature != _last_signature:
		_build_corridor()

func _update_process_state() -> void:
	set_process(Engine.is_editor_hint())
