extends Node3D


# @identity
# essence: z_offset(x, t) = A * sin(omega * x + phi * t) applied to a grid of spheres
# desire: Stand before a wall of spheres displaced by a traveling sine wave
# critical_parameter: base_frequency — controls spatial wave density across the wall
# triggers: time drives phase animation; base_amplitude sets displacement depth
# emerges: a frozen moment of wave propagation made tangible as displaced matter
# needs: VR observation [has], frequency/amplitude control [missing]
# relationships: depends on MultiMesh sphere instancing; contrasts with sine_wall_explanation (immersive vs explanatory); unlocks spatial frequency visualization
# truth: A wave is not a thing — it is a pattern of displacement that moves through things.

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
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh

func _ready() -> void:
	_create_wall()
	_update_wall_state()

func _process(delta: float) -> void:
	_time += delta
	_phase += delta * phase_speed
	_update_wall_state()

func _create_wall() -> void:
	# Create MultiMesh for all wall points
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "Wall"
	_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	_multimesh = MultiMesh.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.09
	sphere_mesh.height = 0.09
	_multimesh.mesh = sphere_mesh
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = columns * rows
	_multimesh_instance.multimesh = _multimesh
	
	# Material with vertex colors and emission
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color(0.15, 0.25, 0.4)
	material.emission_energy_multiplier = 0.35
	material.roughness = 0.4
	material.metallic = 0.1
	_multimesh_instance.material_override = material
	
	add_child(_multimesh_instance)

func _update_wall_state() -> void:
	if columns <= 1 or rows <= 1 or not _multimesh:
		return

	var freq := base_frequency + sin(_time * 0.37) * 0.35
	var amp := base_amplitude + cos(_time * 0.29) * 0.4
	var index := 0

	for x in range(columns):
		var x_norm := (x / float(columns - 1)) * 2.0 - 1.0
		var x_pos := x_norm * wall_width * 0.5
		var wave_offset := _compute_wave_offset(x_norm, freq, amp)

		for y in range(rows):
			var y_norm := (y / float(rows - 1)) * 2.0 - 1.0
			var base_y := y_norm * wall_height * 0.5
			var pos = Vector3(x_pos, base_y + wave_offset, wall_depth)
			
			_multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, pos))
			_multimesh.set_instance_color(index, _compute_color(wave_offset, amp))
			index += 1

func _compute_wave_offset(x_norm: float, freq: float, amp: float) -> float:
	var offset := 0.0
	for layer in wave_layers:
		var freq_mul := float(layer.get("freq_mul", 1.0))
		var amp_mul := float(layer.get("amp_mul", 1.0))
		var phase_shift := float(layer.get("phase_shift", 0.0))
		offset += amp * amp_mul * sin((freq * freq_mul) * x_norm * PI + _phase + phase_shift)
	return offset

func _compute_color(displacement: float, amp: float) -> Color:
	var intensity := (displacement / (amp * 1.6)) + 0.5
	intensity = clamp(intensity, 0.0, 1.0)

	var mid_blend = clamp(intensity * 2.0, 0.0, 1.0)

	var color := bottom_color.lerp(mid_color, mid_blend)
	color = color.lerp(top_color, intensity)
	return color

func reset_wall() -> void:
	_phase = 0.0
	_time = 0.0
	_update_wall_state()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
