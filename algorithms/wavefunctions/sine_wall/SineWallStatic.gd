@tool
extends Node3D

@export_range(4, 256, 1) var columns: int = 120
@export_range(4, 256, 1) var rows: int = 48
@export var wall_width: float = 12.0
@export var wall_height: float = 6.0
@export var wall_depth: float = -4.0

@export var base_frequency: float = 1.1
@export var base_amplitude: float = 1.6
@export var phase: float = 0.0

@export var wave_layers: Array = [
	{"freq_mul": 1.0, "amp_mul": 1.0, "phase_shift": 0.0},
	{"freq_mul": 1.7, "amp_mul": 0.45, "phase_shift": 0.9},
	{"freq_mul": 2.9, "amp_mul": 0.22, "phase_shift": -0.6}
]

@export var bottom_color: Color = Color(0.2, 0.3, 0.9, 1.0)
@export var mid_color: Color = Color(0.4, 0.8, 0.9, 1.0)
@export var top_color: Color = Color(0.95, 0.55, 0.35, 1.0)

@export var auto_update_in_editor: bool = true

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _last_signature: String = ""

func _ready() -> void:
	_ensure_mesh_instance()
	_ensure_material()
	_rebuild_wall()
	_update_process_state()

func rebuild_wall() -> void:
	_ensure_mesh_instance()
	_ensure_material()
	_rebuild_wall()

func _ensure_mesh_instance() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		return
	_mesh_instance = get_node_or_null("WallMesh") as MeshInstance3D
	if not _mesh_instance:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "WallMesh"
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(_mesh_instance)

func _ensure_material() -> void:
	if _material:
		return
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.roughness = 0.55
	_material.metallic = 0.0
	_material.emission_enabled = true
	_material.emission = Color(0.08, 0.12, 0.2, 1.0)
	_material.emission_energy_multiplier = 0.35
	if _mesh_instance:
		_mesh_instance.material_override = _material

func _rebuild_wall() -> void:
	var signature := _make_signature()
	if columns < 2 or rows < 2:
		_last_signature = signature
		if _mesh_instance:
			_mesh_instance.mesh = null
		return

	var mesh := _create_wall_mesh()
	_mesh_instance.mesh = mesh
	_last_signature = signature

func _create_wall_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_width := wall_width * 0.5
	var half_height := wall_height * 0.5

	var position_cache: Array = []
	var color_cache: Array = []
	var uv_cache: Array = []

	for x in range(columns):
		position_cache.append([])
		color_cache.append([])
		uv_cache.append([])

		var x_ratio := 0.0 if columns <= 1 else x / float(columns - 1)
		var x_norm := x_ratio * 2.0 - 1.0
		var x_pos = lerp(-half_width, half_width, x_ratio)
		var displacement := _wave_offset(x_norm)
		var vertex_color := _evaluate_color(displacement)

		for y in range(rows):
			var y_ratio := 0.0 if rows <= 1 else y / float(rows - 1)
			var y_pos = lerp(-half_height, half_height, y_ratio)
			var vertex = Vector3(x_pos, y_pos + displacement, wall_depth)
			position_cache[x].append(vertex)
			color_cache[x].append(vertex_color)
			uv_cache[x].append(Vector2(x_ratio, y_ratio))

	for x in range(columns - 1):
		for y in range(rows - 1):
			var v00 = position_cache[x][y]
			var v10 = position_cache[x + 1][y]
			var v11 = position_cache[x + 1][y + 1]
			var v01 = position_cache[x][y + 1]

			var c00 = color_cache[x][y]
			var c10 = color_cache[x + 1][y]
			var c11 = color_cache[x + 1][y + 1]
			var c01 = color_cache[x][y + 1]

			var uv00 = uv_cache[x][y]
			var uv10 = uv_cache[x + 1][y]
			var uv11 = uv_cache[x + 1][y + 1]
			var uv01 = uv_cache[x][y + 1]

			# First triangle
			st.set_uv(uv00)
			st.set_color(c00)
			st.add_vertex(v00)

			st.set_uv(uv10)
			st.set_color(c10)
			st.add_vertex(v10)

			st.set_uv(uv11)
			st.set_color(c11)
			st.add_vertex(v11)

			# Second triangle
			st.set_uv(uv00)
			st.set_color(c00)
			st.add_vertex(v00)

			st.set_uv(uv11)
			st.set_color(c11)
			st.add_vertex(v11)

			st.set_uv(uv01)
			st.set_color(c01)
			st.add_vertex(v01)

	st.index()
	st.generate_normals()
	return st.commit()

func _wave_offset(x_norm: float) -> float:
	var offset = 0.0
	for layer in wave_layers:
		var freq_mul := float(layer.get("freq_mul", 1.0))
		var amp_mul := float(layer.get("amp_mul", 1.0))
		var phase_shift := float(layer.get("phase_shift", 0.0))
		offset += base_amplitude * amp_mul * sin((base_frequency * freq_mul) * x_norm * PI + phase + phase_shift)
	return offset

func _evaluate_color(displacement: float) -> Color:
	var intensity := (displacement / (base_amplitude * 1.6)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)
	var mid_blend = clamp(intensity * 2.0, 0.0, 1.0)
	var color := bottom_color.lerp(mid_color, mid_blend)
	color = color.lerp(top_color, intensity)
	return color

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if not auto_update_in_editor:
		return
	var signature := _make_signature()
	if signature != _last_signature:
		_rebuild_wall()

func _update_process_state() -> void:
	set_process(Engine.is_editor_hint())

func _make_signature() -> String:
	var layers_sig: Array = []
	for layer in wave_layers:
		if layer is Dictionary:
			layers_sig.append([
				float(layer.get("freq_mul", 1.0)),
				float(layer.get("amp_mul", 1.0)),
				float(layer.get("phase_shift", 0.0))
			])
		else:
			layers_sig.append(layer)
	return str(columns, rows, wall_width, wall_height, wall_depth, base_frequency, base_amplitude, phase, layers_sig, bottom_color, mid_color, top_color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
