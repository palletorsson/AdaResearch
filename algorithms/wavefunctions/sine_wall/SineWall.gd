extends Node3D

@export_range(4, 96, 1) var columns: int = 48
@export_range(4, 96, 1) var rows: int = 32
@export var wall_width: float = 12.0
@export var wall_height: float = 6.0
@export var wall_depth: float = -4.0

@export var base_frequency: float = 1.1
@export var base_amplitude: float = 1.6
@export var phase_speed: float = 1.4

@export var wave_layers: Array = [
	{"freq_mul": 1.0, "amp_mul": 1.0, "phase_shift": 0.0},
	{"freq_mul": 1.7, "amp_mul": 0.45, "phase_shift": 0.9},
	{"freq_mul": 2.9, "amp_mul": 0.22, "phase_shift": -0.6}
]

@export var bottom_color: Color = Color(0.2, 0.3, 0.9, 1.0)
@export var mid_color: Color = Color(0.4, 0.8, 0.9, 1.0)
@export var top_color: Color = Color(0.95, 0.55, 0.35, 1.0)

var _time: float = 0.0
var _phase: float = 0.0
var _nodes: Array = []
var _base_mesh: SphereMesh
var _base_material: StandardMaterial3D

func _ready() -> void:
	_base_mesh = SphereMesh.new()
	_base_mesh.radius = 0.09
	_base_mesh.height = 0.09

	_base_material = StandardMaterial3D.new()
	_base_material.emission_enabled = true

	_create_wall()
	_update_wall_state()

func _process(delta: float) -> void:
	_time += delta
	_phase += delta * phase_speed

	_update_wall_state()

func _create_wall() -> void:
	var parent := Node3D.new()
	parent.name = "Wall"
	add_child(parent)

	_nodes.clear()

	for x in range(columns):
		_nodes.append([])
		for y in range(rows):
			var point := MeshInstance3D.new()
			point.mesh = _base_mesh
			point.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			point.material_override = _base_material.duplicate()
			parent.add_child(point)
			_nodes[x].append(point)

func _update_wall_state() -> void:
	if columns <= 1 or rows <= 1:
		return

	var freq := base_frequency + sin(_time * 0.37) * 0.35
	var amp := base_amplitude + cos(_time * 0.29) * 0.4

	for x in range(columns):
		var x_norm := (x / float(columns - 1)) * 2.0 - 1.0
		var x_pos := x_norm * wall_width * 0.5
		var wave_offset := _compute_wave_offset(x_norm, freq, amp)

		for y in range(rows):
			var y_norm := (y / float(rows - 1)) * 2.0 - 1.0
			var base_y := y_norm * wall_height * 0.5
			var node: MeshInstance3D = _nodes[x][y]
			node.position = Vector3(x_pos, base_y + wave_offset, wall_depth)
			_apply_color(node, wave_offset, amp)

func _compute_wave_offset(x_norm: float, freq: float, amp: float) -> float:
	var offset := 0.0
	for layer in wave_layers:
		var freq_mul := float(layer.get("freq_mul", 1.0))
		var amp_mul := float(layer.get("amp_mul", 1.0))
		var phase_shift := float(layer.get("phase_shift", 0.0))
		offset += amp * amp_mul * sin((freq * freq_mul) * x_norm * PI + _phase + phase_shift)
	return offset

func _apply_color(node: MeshInstance3D, displacement: float, amp: float) -> void:
	var material := node.material_override as StandardMaterial3D
	if material == null:
		material = _base_material.duplicate()
		node.material_override = material

	var intensity := (displacement / (amp * 1.6)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)

	var mid_blend = clamp(intensity * 2.0, 0.0, 1.0)
	var low_blend = clamp((1.0 - intensity) * 2.0, 0.0, 1.0)

	var color := bottom_color.lerp(mid_color, mid_blend)
	color = color.lerp(top_color, intensity)

	material.albedo_color = color
	material.emission = color * 0.35

func reset_wall() -> void:
	_phase = 0.0
	_time = 0.0
	_update_wall_state()
