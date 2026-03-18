extends Node3D

@export var hallway_length: float = 60.0
@export var hallway_width: float = 12.0
@export var hallway_height: float = 12.0
@export var tube_count: int = 8
@export var tube_length: float = 80.0
@export var wave_amplitude: float = 2.5
@export var wave_frequency: float = 0.3
@export var tube_radius: float = 0.4
@export var segment_spacing: float = 1.0
@export var animate_tubes: bool = true
@export var rotation_speed: float = 0.35

@export var color_variants: Array = [
	Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW,
	Color.PURPLE, Color.AQUA, Color.DARK_ORANGE, Color.CYAN
]

var tube_segments: Array[MultiMeshInstance3D] = []
var elapsed: float = 0.0

func _ready() -> void:
	_setup_environment()
	_create_sine_tubes()

func _process(delta: float) -> void:
	if not animate_tubes:
		return
	elapsed += delta
	_update_tubes(elapsed)

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 0.6
	$WorldEnvironment.environment = env


func _create_sine_tubes() -> void:
	var half_len := int(tube_length * 0.5)
	var segments_per_tube := half_len * 2  # -half_len to half_len-1

	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = tube_radius
	cyl_mesh.bottom_radius = tube_radius
	cyl_mesh.height = segment_spacing
	cyl_mesh.rings = 8
	cyl_mesh.radial_segments = 24

	for i in range(tube_count):
		var color = color_variants[i % color_variants.size()]
		var material := _make_metallic(color)

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = segments_per_tube
		mm.mesh = cyl_mesh

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = material
		add_child(mmi)
		tube_segments.append(mmi)

	_update_tubes(0.0)

func _update_tubes(time_val: float) -> void:
	var half_len := int(tube_length * 0.5)
	var rot_basis := Basis.IDENTITY.rotated(Vector3(1, 0, 0), PI * 0.5)

	for i in range(tube_segments.size()):
		var mm: MultiMesh = tube_segments[i].multimesh
		var idx := 0
		for z in range(-half_len, half_len):
			var phase := float(i) * 0.6 + (time_val * rotation_speed)
			var x := sin(float(z) * wave_frequency + phase) * wave_amplitude
			var y := sin(float(z) * wave_frequency * 0.7 + phase) * 0.5 * wave_amplitude + hallway_height * 0.5
			var pos := Vector3(x, y, float(z))
			mm.set_instance_transform(idx, Transform3D(rot_basis, pos))
			idx += 1

func _make_metallic(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.85
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = col * 0.25
	mat.emission_energy_multiplier = 1.0
	return mat

func _make_reflective(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 1.0
	mat.roughness = 0.06
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
