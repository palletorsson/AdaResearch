@tool
extends Node3D

# Visual parameters
@export var prime_color: Color = Color(1.0, 0.8, 0.3)
@export var ribbon_color: Color = Color(0.2, 0.6, 1.0, 0.4)
@export var horizon_color: Color = Color(0.6, 0.1, 1.0)
@export var max_x: int = 2000
@export var scale_height: float = 0.05
@export var x_scale: float = 0.01  # How much physical space per integer
@export var prime_sphere_radius: float = 0.05
@export var animate_horizon: bool = true
@export var horizon_speed: float = 0.5

# Interactive movement
@export_group("Journey Mode")
@export var enable_auto_travel: bool = false
@export var travel_speed: float = 0.5

var primes: PackedInt32Array
var mm_primes: MultiMesh
var ribbon: MeshInstance3D
var horizon: MeshInstance3D
var prime_line_node: Node3D
var travel_position: float = 0.0

func _ready():
	# --- Prime sequence ---
	primes = _generate_primes(max_x)
	print("Generated %d primes up to %d" % [primes.size(), max_x])

	# --- Prime line visualization ---
	_setup_prime_line()

	# --- π(x) ribbon ---
	_setup_pi_ribbon()

	# --- ζ(s) horizon at infinity ---
	_setup_zeta_horizon()

	# --- Environment ---
	_setup_environment()

	set_process(true)


func _process(delta):
	# Animate horizon surface phase (simulating zeta-wave oscillation)
	if animate_horizon and is_instance_valid(horizon) and horizon.material_override != null:
		var mat := horizon.material_override as ShaderMaterial
		if mat != null:
			var t = (mat.get_shader_parameter("time_phase") as float) + delta * horizon_speed
			mat.set_shader_parameter("time_phase", t)

	# Auto-travel mode (moves camera forward through the prime landscape)
	if enable_auto_travel:
		travel_position += delta * travel_speed
		var cam := get_viewport().get_camera_3d()
		if cam != null:
			cam.global_transform.origin.x = travel_position


# ----------------------------
#   PRIME GENERATION (Sieve of Eratosthenes)
# ----------------------------
func _generate_primes(limit: int) -> PackedInt32Array:
	var sieve := PackedByteArray()
	sieve.resize(limit + 1)
	for i in range(limit + 1):
		sieve[i] = 1
	sieve[0] = 0
	sieve[1] = 0

	var sqrt_limit := int(sqrt(limit)) + 1
	for p in range(2, sqrt_limit):
		if sieve[p] == 1:
			for multiple in range(p * p, limit + 1, p):
				if multiple < sieve.size():
					sieve[multiple] = 0

	var result := PackedInt32Array()
	for i in range(2, limit + 1):
		if sieve[i] == 1:
			result.append(i)
	return result


# ----------------------------
#   PRIME LINE VISUALIZATION
# ----------------------------
func _setup_prime_line():
	prime_line_node = Node3D.new()
	prime_line_node.name = "PrimeLine"
	add_child(prime_line_node)
	if Engine.is_editor_hint():
		prime_line_node.owner = get_tree().edited_scene_root

	var prime_mesh := SphereMesh.new()
	prime_mesh.radius = prime_sphere_radius
	prime_mesh.height = prime_sphere_radius * 2.0
	prime_mesh.radial_segments = 8
	prime_mesh.rings = 4

	mm_primes = MultiMesh.new()
	mm_primes.transform_format = MultiMesh.TRANSFORM_3D
	mm_primes.use_colors = false
	mm_primes.mesh = prime_mesh
	mm_primes.instance_count = primes.size()

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.multimesh = mm_primes
	mm_instance.name = "PrimeDots"
	prime_line_node.add_child(mm_instance)
	if Engine.is_editor_hint():
		mm_instance.owner = get_tree().edited_scene_root

	# Create emissive material for primes
	var mat := StandardMaterial3D.new()
	mat.albedo_color = prime_color
	mat.emission_enabled = true
	mat.emission = prime_color
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.3
	mat.roughness = 0.7
	mm_instance.material_override = mat

	# Position each prime along the X axis
	for i in range(primes.size()):
		var p = primes[i]
		var t = Transform3D(Basis.IDENTITY, Vector3(p * x_scale, 0, 0))
		mm_primes.set_instance_transform(i, t)


# ----------------------------
#   π(x) RIBBON (Prime counting function)
# ----------------------------
func _setup_pi_ribbon():
	# Build the staircase of π(x)
	var arr := PackedVector3Array()
	var pi_count := 0
	var prime_idx := 0

	for x in range(2, max_x + 1):
		# Check if x is prime
		if prime_idx < primes.size() and primes[prime_idx] == x:
			pi_count += 1
			prime_idx += 1
		arr.append(Vector3(x * x_scale, pi_count * scale_height, 0))

	# Create line strip mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	for v in arr:
		st.add_vertex(v)
	var m := st.commit()

	ribbon = MeshInstance3D.new()
	ribbon.mesh = m
	ribbon.name = "PiRibbon"

	# Create material with transparency
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ribbon_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(ribbon_color.r, ribbon_color.g, ribbon_color.b, 1.0)
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon.material_override = mat

	add_child(ribbon)
	if Engine.is_editor_hint():
		ribbon.owner = get_tree().edited_scene_root


# ----------------------------
#   ZETA HORIZON (∞) - Complex wave surface
# ----------------------------
func _setup_zeta_horizon():
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 3)
	plane.subdivide_width = 32
	plane.subdivide_depth = 32

	var mat := ShaderMaterial.new()
	mat.shader = _zeta_wave_shader()
	mat.set_shader_parameter("time_phase", 0.0)
	mat.set_shader_parameter("hue_color", horizon_color)

	horizon = MeshInstance3D.new()
	horizon.mesh = plane
	horizon.material_override = mat
	horizon.name = "ZetaHorizon"

	# Position at the end of the number line, rotated to face the viewer
	horizon.position = Vector3(max_x * x_scale + 2.0, 1.0, 0)
	horizon.rotation_degrees = Vector3(0, 90, 0)

	add_child(horizon)
	if Engine.is_editor_hint():
		horizon.owner = get_tree().edited_scene_root


# ----------------------------
#   ENVIRONMENT SETUP
# ----------------------------
func _setup_environment():
	# Add a subtle ground plane for spatial reference
	var ground := MeshInstance3D.new()
	var ground_plane := PlaneMesh.new()
	ground_plane.size = Vector2(max_x * x_scale * 1.2, 8.0)
	ground.mesh = ground_plane
	ground.name = "GroundPlane"
	ground.position = Vector3(max_x * x_scale * 0.5, -0.5, 0)

	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.1, 0.1, 0.15, 0.3)
	ground_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_mat.metallic = 0.0
	ground_mat.roughness = 1.0
	ground.material_override = ground_mat

	add_child(ground)
	if Engine.is_editor_hint():
		ground.owner = get_tree().edited_scene_root


# ----------------------------
#   SHADERS
# ----------------------------
func _zeta_wave_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_back;

uniform float time_phase = 0.0;
uniform vec3 hue_color : source_color = vec3(0.6, 0.1, 1.0);

// Simulate the oscillating nature of ζ(s) zeros
void vertex() {
	// Add wave displacement
	float wave = sin(VERTEX.x * 3.14159 + time_phase) * cos(VERTEX.y * 3.14159 + time_phase * 0.7);
	VERTEX.z += wave * 0.2;
}

void fragment() {
	vec2 uv = UV * 8.0;

	// Complex interference pattern (two overlapping waves)
	float wave1 = 0.5 + 0.5 * cos(uv.x * 3.14159 + time_phase);
	float wave2 = 0.5 + 0.5 * sin(uv.y * 3.14159 + time_phase * 0.7);
	float interference = wave1 * wave2;

	// Zeta critical line visualization (subtle vertical bands)
	float critical_line = 0.5 + 0.5 * sin(uv.x * 12.0);

	vec3 col = hue_color * (0.3 + 0.7 * interference) * (0.8 + 0.2 * critical_line);

	ALBEDO = col;
	ALPHA = 0.85;
	EMISSION = col * 0.5;
}
"""
	return sh


# ----------------------------
#   PUBLIC UTILITIES
# ----------------------------
func get_prime_count() -> int:
	return primes.size()


func get_pi_at_x(x: int) -> int:
	# Binary search for π(x) - count of primes ≤ x
	var count := 0
	for p in primes:
		if p <= x:
			count += 1
		else:
			break
	return count


func teleport_to_prime(prime_index: int) -> void:
	if prime_index < 0 or prime_index >= primes.size():
		return
	var p := primes[prime_index]
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		cam.global_transform.origin = Vector3(p * x_scale, 1.0, 2.0)
