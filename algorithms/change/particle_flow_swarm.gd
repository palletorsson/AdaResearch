# Particle Flow Swarm — particles following a vector field
#
# Pairs with vector_field_grid: the same field, but instead of static arrows we see
# many small particles being carried along by it. Particles that drift off the plane
# re-spawn at the opposite side, so the flow visualization is continuous. Trails fade
# to suggest streamlines without saving them all.
#
# Demonstrates that a vector field acts on whatever rides it. Foreshadows forces and the
# integration phase (where settling = riding a gradient field).
#
# @identity: First map where the player sees a field's effect on bodies.
# @qfep_term: F (the field) + Δ(S,t) (the riding).

extends Node3D
class_name ParticleFlowSwarm

@export_category("Flow Settings")
@export var particle_color: Color = Color(0.7, 0.95, 1.0, 1.0)
@export var hot_color: Color = Color(1.0, 0.7, 0.4, 1.0)
@export var particle_count: int = 220
@export var domain_x: float = 2.4
@export var domain_z: float = 1.6
@export var step_scale: float = 0.012
@export var k: float = 2.5

var _particles: Array = []
var _multi_mesh_inst: MultiMeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_multimesh()
	_spawn_particles()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("particle_count"):
		particle_count = int(config_data["particle_count"])
		# Rebuild
		if is_instance_valid(_multi_mesh_inst):
			_multi_mesh_inst.queue_free()
		_particles.clear()
		_build_multimesh()
		_spawn_particles()


func _process(delta: float) -> void:
	_t += delta
	_step_particles(delta)
	_write_to_multimesh()


func _build_multimesh() -> void:
	_multi_mesh_inst = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	mm.mesh = sphere
	mm.instance_count = particle_count
	_multi_mesh_inst.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = particle_color
	mat.emission_enabled = true
	mat.emission = particle_color
	mat.emission_energy_multiplier = 1.5
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Apply via mesh's material_override.
	_multi_mesh_inst.material_override = mat
	add_child(_multi_mesh_inst)


func _spawn_particles() -> void:
	for i in particle_count:
		_particles.append({
			"x": randf_range(-domain_x * 0.5, domain_x * 0.5),
			"z": randf_range(-domain_z * 0.5, domain_z * 0.5),
		})


func _field_at(x: float, z: float) -> Vector3:
	# Same field as vector_field_grid: v = (∂Ψ/∂z, -∂Ψ/∂x), Ψ = sin(x*k + t)cos(z*k + t)
	var phase := _t * 0.4
	var psi_dz: float = -sin(x * k + phase) * sin(z * k + phase) * k
	var psi_dx: float = cos(x * k + phase) * cos(z * k + phase) * k
	return Vector3(psi_dz, 0.0, -psi_dx)


func _step_particles(delta: float) -> void:
	for p in _particles:
		var v := _field_at(p["x"], p["z"])
		p["x"] += v.x * step_scale
		p["z"] += v.z * step_scale
		# Wrap-around domain.
		if p["x"] > domain_x * 0.5:
			p["x"] -= domain_x
		elif p["x"] < -domain_x * 0.5:
			p["x"] += domain_x
		if p["z"] > domain_z * 0.5:
			p["z"] -= domain_z
		elif p["z"] < -domain_z * 0.5:
			p["z"] += domain_z


func _write_to_multimesh() -> void:
	if not is_instance_valid(_multi_mesh_inst):
		return
	var mm := _multi_mesh_inst.multimesh
	for i in min(particle_count, _particles.size()):
		var p: Dictionary = _particles[i]
		var x: float = p["x"]
		var z: float = p["z"]
		var v := _field_at(x, z)
		var speed: float = v.length()
		var t_speed: float = clamp(speed / 3.5, 0.0, 1.0)
		var col := particle_color.lerp(hot_color, t_speed)
		mm.set_instance_color(i, col)
		var t := Transform3D(Basis(), Vector3(x, 0.08, z))
		mm.set_instance_transform(i, t)
