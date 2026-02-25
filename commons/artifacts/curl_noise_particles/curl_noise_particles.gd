extends Node3D
class_name CurlNoiseParticles

## Curl noise particle flow — divergence-free velocity field drives 300 particles
## in smooth, swirling ribbons. Curl noise is the cross product of noise gradients,
## guaranteeing incompressible (solenoidal) flow. Particles color-shift from cool
## blue at rest to hot white at speed.

# --- Configuration ---

@export var particle_count: int = 300
@export var bounds: Vector3 = Vector3(0.7, 0.5, 0.7)
@export var noise_scale: float = 2.5
@export var flow_speed: float = 0.3
@export var time_scale: float = 0.15

# --- Internal ---

var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _bounds_mesh: MeshInstance3D
var _title_label: Label3D
var _info_label: Label3D

var _positions: PackedVector3Array
var _velocities: PackedVector3Array
var _trail_mesh: MeshInstance3D

var _time: float = 0.0
var _rng: RandomNumberGenerator

# Noise offset seeds (so x/y/z noise fields differ)
var _offset_a: Vector3
var _offset_b: Vector3

# Color ramp: slow → fast
var _color_slow: Color = Color(0.15, 0.25, 0.85)     # Deep blue
var _color_mid: Color = Color(0.3, 0.8, 1.0)          # Cyan
var _color_fast: Color = Color(1.0, 0.95, 0.9)        # Near-white


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42

	# Generate unique offset seeds for the two noise potential fields
	_offset_a = Vector3(_rng.randf() * 100.0, _rng.randf() * 100.0, _rng.randf() * 100.0)
	_offset_b = Vector3(_rng.randf() * 100.0, _rng.randf() * 100.0, _rng.randf() * 100.0)

	_create_bounds_wireframe()
	_create_multimesh()
	_create_trail_mesh()
	_create_labels()
	_spawn_particles()


# ------------------------------------------------------------------
# Bounds wireframe
# ------------------------------------------------------------------

func _create_bounds_wireframe() -> void:
	_bounds_mesh = MeshInstance3D.new()
	_bounds_mesh.name = "BoundsWireframe"
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var hx = bounds.x / 2.0
	var hy = bounds.y / 2.0
	var hz = bounds.z / 2.0

	var corners: Array[Vector3] = [
		Vector3(-hx, -hy, -hz), Vector3( hx, -hy, -hz),
		Vector3( hx, -hy,  hz), Vector3(-hx, -hy,  hz),
		Vector3(-hx,  hy, -hz), Vector3( hx,  hy, -hz),
		Vector3( hx,  hy,  hz), Vector3(-hx,  hy,  hz),
	]
	var edges: Array[int] = [
		0,1, 1,2, 2,3, 3,0,
		4,5, 5,6, 6,7, 7,4,
		0,4, 1,5, 2,6, 3,7,
	]

	var edge_color = Color(0.25, 0.3, 0.45, 0.25)
	for idx in range(0, edges.size(), 2):
		im.surface_set_color(edge_color)
		im.surface_add_vertex(corners[edges[idx]])
		im.surface_set_color(edge_color)
		im.surface_add_vertex(corners[edges[idx + 1]])

	im.surface_end()
	_bounds_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bounds_mesh.material_override = mat
	add_child(_bounds_mesh)


# ------------------------------------------------------------------
# MultiMesh for particles
# ------------------------------------------------------------------

func _create_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = particle_count

	var sphere = SphereMesh.new()
	sphere.radius = 0.004
	sphere.height = 0.008
	sphere.radial_segments = 6
	sphere.rings = 3
	_multimesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "ParticleMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)


# ------------------------------------------------------------------
# Trail mesh (ImmediateMesh rebuilt each frame for flow ribbons)
# ------------------------------------------------------------------

func _create_trail_mesh() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "TrailMesh"
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh.material_override = mat
	add_child(_trail_mesh)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "CURL NOISE"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, bounds.y / 2.0 + 0.06, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.85, 0.9, 1.0)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 14
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, bounds.y / 2.0 + 0.02, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.6, 0.65, 0.8, 0.85)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_info_label.text = "divergence-free flow  |  %d particles" % particle_count
	add_child(_info_label)


# ------------------------------------------------------------------
# Particle spawning
# ------------------------------------------------------------------

func _spawn_particles() -> void:
	_positions = PackedVector3Array()
	_velocities = PackedVector3Array()
	_positions.resize(particle_count)
	_velocities.resize(particle_count)

	var hx = bounds.x * 0.45
	var hy = bounds.y * 0.45
	var hz = bounds.z * 0.45

	for i in range(particle_count):
		_positions[i] = Vector3(
			_rng.randf_range(-hx, hx),
			_rng.randf_range(-hy, hy),
			_rng.randf_range(-hz, hz)
		)
		_velocities[i] = Vector3.ZERO


# ------------------------------------------------------------------
# Noise functions — sin-based layered noise
# ------------------------------------------------------------------

func _noise_3d(p: Vector3, offset: Vector3) -> float:
	var q = p + offset
	# 3-octave sin-based noise for smooth turbulence
	var val = sin(q.x * 1.7 + q.y * 2.3 + q.z * 1.1) * 0.5
	val += sin(q.x * 3.1 - q.z * 2.7 + q.y * 0.9) * 0.25
	val += sin(q.y * 4.3 + q.x * 1.3 - q.z * 3.1) * 0.125
	return val


func _curl_noise(p: Vector3) -> Vector3:
	# Curl noise = cross product of gradient of potential fields
	# For divergence-free flow, we compute:
	#   curl(F) = (dFz/dy - dFy/dz, dFx/dz - dFz/dx, dFy/dx - dFx/dy)
	# Using three independent noise fields as the potential
	var eps = 0.01
	var sp = p * noise_scale + Vector3(_time * time_scale, _time * time_scale * 0.7, _time * time_scale * 0.3)

	# Partial derivatives of noise field A (used for potential)
	var na_dx = _noise_3d(sp + Vector3(eps, 0, 0), _offset_a) - _noise_3d(sp - Vector3(eps, 0, 0), _offset_a)
	var na_dy = _noise_3d(sp + Vector3(0, eps, 0), _offset_a) - _noise_3d(sp - Vector3(0, eps, 0), _offset_a)
	var na_dz = _noise_3d(sp + Vector3(0, 0, eps), _offset_a) - _noise_3d(sp - Vector3(0, 0, eps), _offset_a)

	# Partial derivatives of noise field B
	var nb_dx = _noise_3d(sp + Vector3(eps, 0, 0), _offset_b) - _noise_3d(sp - Vector3(eps, 0, 0), _offset_b)
	var nb_dy = _noise_3d(sp + Vector3(0, eps, 0), _offset_b) - _noise_3d(sp - Vector3(0, eps, 0), _offset_b)
	var nb_dz = _noise_3d(sp + Vector3(0, 0, eps), _offset_b) - _noise_3d(sp - Vector3(0, 0, eps), _offset_b)

	# Curl = cross product of the two gradient fields
	# This guarantees divergence-free (incompressible) flow
	var curl_x = na_dy * nb_dz - na_dz * nb_dy
	var curl_y = na_dz * nb_dx - na_dx * nb_dz
	var curl_z = na_dx * nb_dy - na_dy * nb_dx

	var inv_eps2 = 1.0 / (2.0 * eps * 2.0 * eps)
	return Vector3(curl_x, curl_y, curl_z) * inv_eps2


# ------------------------------------------------------------------
# Simulation
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)
	_update_multimesh()
	_update_trails()


func _update_particles(delta: float) -> void:
	var hx = bounds.x / 2.0
	var hy = bounds.y / 2.0
	var hz = bounds.z / 2.0

	for i in range(particle_count):
		var pos = _positions[i]

		# Sample curl noise at particle position
		var vel = _curl_noise(pos) * flow_speed
		_velocities[i] = vel

		# Integrate position
		pos += vel * delta
		_positions[i] = pos

		# Respawn particles that exit bounds
		if absf(pos.x) > hx or absf(pos.y) > hy or absf(pos.z) > hz:
			_positions[i] = Vector3(
				randf_range(-hx * 0.9, hx * 0.9),
				randf_range(-hy * 0.9, hy * 0.9),
				randf_range(-hz * 0.9, hz * 0.9)
			)
			_velocities[i] = Vector3.ZERO


func _update_multimesh() -> void:
	var max_speed_sq: float = 0.0

	# First pass: find max speed for normalization
	for i in range(particle_count):
		var spd_sq = _velocities[i].length_squared()
		if spd_sq > max_speed_sq:
			max_speed_sq = spd_sq

	var max_spd = sqrt(max_speed_sq) if max_speed_sq > 0.0001 else 1.0

	# Second pass: update transforms and colors
	for i in range(particle_count):
		var t = Transform3D()
		t.origin = _positions[i]
		_multimesh.set_instance_transform(i, t)

		# Color by speed: slow=blue, mid=cyan, fast=white
		var spd = _velocities[i].length()
		var t_norm = clampf(spd / max_spd, 0.0, 1.0)

		var color: Color
		if t_norm < 0.5:
			var f = t_norm * 2.0
			color = _color_slow.lerp(_color_mid, f)
		else:
			var f = (t_norm - 0.5) * 2.0
			color = _color_mid.lerp(_color_fast, f)
		color.a = 0.7 + t_norm * 0.3
		_multimesh.set_instance_color(i, color)


func _update_trails() -> void:
	# Draw short trail lines behind a subset of particles for flow visualization
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)

	var max_speed_sq: float = 0.0
	for i in range(particle_count):
		var spd_sq = _velocities[i].length_squared()
		if spd_sq > max_speed_sq:
			max_speed_sq = spd_sq
	var max_spd = sqrt(max_speed_sq) if max_speed_sq > 0.0001 else 1.0

	# Draw trails for every 3rd particle to keep it readable
	var trail_length: float = 0.025
	for i in range(0, particle_count, 3):
		var pos = _positions[i]
		var vel = _velocities[i]
		var spd = vel.length()
		if spd < 0.001:
			continue

		var tail = pos - vel.normalized() * trail_length

		var t_norm = clampf(spd / max_spd, 0.0, 1.0)
		var color: Color
		if t_norm < 0.5:
			color = _color_slow.lerp(_color_mid, t_norm * 2.0)
		else:
			color = _color_mid.lerp(_color_fast, (t_norm - 0.5) * 2.0)

		var head_color = Color(color, 0.5)
		var tail_color = Color(color, 0.08)

		im.surface_set_color(tail_color)
		im.surface_add_vertex(tail)
		im.surface_set_color(head_color)
		im.surface_add_vertex(pos)

	im.surface_end()
	_trail_mesh.mesh = im


# ------------------------------------------------------------------
# Grid system integration
# ------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("particle_count"):
		particle_count = int(config_data["particle_count"])
	if config_data.has("noise_scale"):
		noise_scale = float(config_data["noise_scale"])
	if config_data.has("flow_speed"):
		flow_speed = float(config_data["flow_speed"])
	if config_data.has("time_scale"):
		time_scale = float(config_data["time_scale"])
