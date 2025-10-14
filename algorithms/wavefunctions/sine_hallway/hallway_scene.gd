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

var tube_segments: Array = []
var elapsed: float = 0.0

func _ready():
	_setup_environment()
	_create_hallway()
	_create_sine_tubes()

func _process(delta: float) -> void:
	if not animate_tubes:
		return
	elapsed += delta
	_update_tubes(elapsed)

func _setup_environment():
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 0.6
	$WorldEnvironment.environment = env

func _create_hallway():
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(hallway_width, 0.5, hallway_length)
	floor.mesh = floor_mesh
	floor.material_override = _make_metallic(Color(0.1, 0.1, 0.12))
	floor.position = Vector3(0, -0.25, 0)
	add_child(floor)

	var ceiling := floor.duplicate() as MeshInstance3D
	ceiling.position.y = hallway_height
	add_child(ceiling)

	var wall_left := MeshInstance3D.new()
	var wl_mesh := BoxMesh.new()
	wl_mesh.size = Vector3(0.5, hallway_height, hallway_length)
	wall_left.mesh = wl_mesh
	wall_left.material_override = _make_reflective(Color(0.85, 0.88, 0.95))
	wall_left.position = Vector3(-hallway_width * 0.5, hallway_height * 0.5, 0)
	add_child(wall_left)

	var wall_right := wall_left.duplicate() as MeshInstance3D
	wall_right.position.x = hallway_width * 0.5
	add_child(wall_right)

func _create_sine_tubes():
	var half_len := int(tube_length * 0.5)
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = tube_radius
	cyl_mesh.bottom_radius = tube_radius
	cyl_mesh.height = segment_spacing
	cyl_mesh.rings = 8
	cyl_mesh.radial_segments = 24

	for i in range(tube_count):
		var segments_for_tube: Array[MeshInstance3D] = []
		var color = color_variants[i % color_variants.size()]
		var material := _make_metallic(color)
		for z in range(-half_len, half_len):
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = cyl_mesh
			mesh_instance.material_override = material
			add_child(mesh_instance)
			segments_for_tube.append(mesh_instance)
		tube_segments.append(segments_for_tube)
	_update_tubes(0.0)

func _update_tubes(time_val: float):
	var half_len := int(tube_length * 0.5)
	for i in range(tube_segments.size()):
		var segments: Array = tube_segments[i]
		var idx := 0
		for z in range(-half_len, half_len):
			var phase := float(i) * 0.6 + (time_val * rotation_speed)
			var x := sin(float(z) * wave_frequency + phase) * wave_amplitude
			var y := sin(float(z) * wave_frequency * 0.7 + phase) * 0.5 * wave_amplitude + hallway_height * 0.5
			var pos := Vector3(x, y, float(z))
			var node: MeshInstance3D = segments[idx]
			node.position = pos
			# Orient cylinder along Z direction
			var basis := Basis.IDENTITY
			basis = basis.rotated(Vector3(1, 0, 0), PI * 0.5)
			node.basis = basis
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
