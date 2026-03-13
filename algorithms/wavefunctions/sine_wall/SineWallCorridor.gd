@tool
extends Node3D

@export_range(4, 256, 1) var columns: int = 200
@export_range(4, 256, 1) var rows: int = 64
@export var corridor_length: float = 24.0
@export var corridor_width: float = 1.0
@export var corridor_height: float = 6.0

@export var base_frequency: float = 2.2
@export var base_amplitude: float = 0.45
@export var left_wall_frequency_multiplier: float = 1.6
@export var left_wall_amplitude_multiplier: float = 0.5
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
@export var enable_collision: bool = true
@export var use_plush_shader: bool = true

@export var auto_update_in_editor: bool = false
@export var animate_at_runtime: bool = false
@export var animation_speed: float = 0.05  # Very slow animation

var _left_wall: MeshInstance3D
var _right_wall: MeshInstance3D
var _floor: MeshInstance3D
var _left_wall_body: StaticBody3D
var _right_wall_body: StaticBody3D
var _left_wall_shape: CollisionShape3D
var _right_wall_shape: CollisionShape3D
var _wall_material: Material
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
	# Check if material needs to be switched
	if _wall_material:
		var is_shader = _wall_material is ShaderMaterial
		if is_shader != use_plush_shader:
			_wall_material = null

	if not _wall_material:
		if use_plush_shader:
			var shader = load("res://algorithms/wavefunctions/sine_wall/plush_red.gdshader")
			if shader:
				var sm = ShaderMaterial.new()
				sm.shader = shader
				_wall_material = sm
			else:
				var sm = StandardMaterial3D.new()
				sm.albedo_color = Color(0.6, 0.0, 0.1)
				_wall_material = sm
		else:
			var sm = StandardMaterial3D.new()
			sm.vertex_color_use_as_albedo = true
			sm.roughness = 0.45
			sm.metallic = 0.1
			sm.emission_enabled = true
			sm.emission = wall_emission
			sm.emission_energy_multiplier = 0.45
			sm.cull_mode = BaseMaterial3D.CULL_DISABLED
			_wall_material = sm

	# Re-assign material to meshes in case it changed
	if _left_wall: _left_wall.material_override = _wall_material
	if _right_wall: _right_wall.material_override = _wall_material

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
	_floor = _get_or_create_mesh_instance("Floor", _floor)
	_left_wall_body = _get_or_create_static_body("LeftWallBody", _left_wall_body)
	_right_wall_body = _get_or_create_static_body("RightWallBody", _right_wall_body)
	_left_wall_shape = _get_or_create_collision_shape(_left_wall_body, "LeftWallShape", _left_wall_shape)
	_right_wall_shape = _get_or_create_collision_shape(_right_wall_body, "RightWallShape", _right_wall_shape)

	var existing_ceiling := get_node_or_null("Ceiling")
	if existing_ceiling:
		existing_ceiling.queue_free()

	for mesh in [_left_wall, _right_wall]:
		mesh.material_override = _wall_material
	_floor.material_override = _floor_material
	_left_wall_body.transform = Transform3D.IDENTITY
	_right_wall_body.transform = Transform3D.IDENTITY

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

func _get_or_create_static_body(name: String, cache: StaticBody3D) -> StaticBody3D:
	if cache and is_instance_valid(cache):
		return cache
	var body := get_node_or_null(name) as StaticBody3D
	if not body:
		body = StaticBody3D.new()
		body.name = name
		add_child(body)
	return body

func _get_or_create_collision_shape(parent: Node3D, name: String, cache: CollisionShape3D) -> CollisionShape3D:
	if cache and is_instance_valid(cache):
		return cache
	var shape_node := parent.get_node_or_null(name) as CollisionShape3D
	if not shape_node:
		shape_node = CollisionShape3D.new()
		shape_node.name = name
		parent.add_child(shape_node)
	return shape_node

func _build_corridor() -> void:
	if columns < 2 or rows < 2:
		return

	var signature := _make_signature()
	if signature == _last_signature:
		return

	var half_length := corridor_length * 0.5
	var half_width := corridor_width * 0.5
	var half_height := corridor_height * 0.5

	_left_wall.mesh = _create_wall_mesh(-1, half_length, half_width, half_height, phase, left_wall_frequency_multiplier, left_wall_amplitude_multiplier)
	_right_wall.mesh = _create_wall_mesh(1, half_length, half_width, half_height, phase + phase_offset_between_walls, 1.0, 1.0)
	_floor.mesh = _create_plane_mesh(half_length, half_width, half_height, false)
	_update_wall_collision(_left_wall, _left_wall_shape)
	_update_wall_collision(_right_wall, _right_wall_shape)

	_left_wall.transform = Transform3D.IDENTITY
	_right_wall.transform = Transform3D.IDENTITY
	_floor.transform = Transform3D.IDENTITY

	_last_signature = signature

func _update_wall_collision(mesh_instance: MeshInstance3D, shape_node: CollisionShape3D) -> void:
	if not shape_node:
		return
	if not enable_collision:
		shape_node.shape = null
		return
	var mesh := mesh_instance.mesh
	if mesh:
		shape_node.shape = mesh.create_trimesh_shape()
	else:
		shape_node.shape = null

func _create_wall_mesh(side: int, half_length: float, half_width: float, half_height: float, phase_shift: float, freq_multiplier: float, amp_multiplier: float) -> ArrayMesh:
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
		var displacement: float = _wave_displacement(z_ratio, phase_shift, freq_multiplier, amp_multiplier)
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

func _wave_displacement(z_ratio: float, phase_shift: float, freq_multiplier: float = 1.0, amp_multiplier: float = 1.0) -> float:
	var z_norm: float = z_ratio * 2.0 - 1.0
	var offset: float = 0.0
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
		offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase + phase_shift + phase_layer)
	return offset

func _evaluate_color(displacement: float) -> Color:
	var intensity: float = (displacement / (base_amplitude * 1.6)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)
	var blend: float = clamp(intensity * 1.8, 0.0, 1.0)
	var color: Color = bottom_color.lerp(mid_color, blend)
	color = color.lerp(top_color, intensity)
	return color

func _make_signature() -> String:
	return str(columns, rows, corridor_length, corridor_width, corridor_height, base_frequency, base_amplitude, left_wall_frequency_multiplier, left_wall_amplitude_multiplier, phase, phase_offset_between_walls, wave_layers, bottom_color, mid_color, top_color, enable_collision, use_plush_shader)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Editor mode: check for parameter changes
		if not auto_update_in_editor:
			return
		var signature := _make_signature()
		if signature != _last_signature:
			_build_corridor()
	else:
		# Runtime mode: animate phase slowly
		if animate_at_runtime:
			phase += delta * animation_speed
			_last_signature = ""  # Force rebuild
			_build_corridor()

func _update_process_state() -> void:
	set_process(Engine.is_editor_hint() or animate_at_runtime)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

