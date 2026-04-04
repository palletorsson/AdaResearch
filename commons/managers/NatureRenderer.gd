# NatureRenderer.gd
# Reads EcosystemManager state and controls visual nature layers in VR.
# Fog, sky color, ground tint, ambient particles — all driven by vegetation_density.
# Lightweight: checks state once per second, tweens transitions, no per-frame alloc.

#class_name NatureRenderer  # Removed — autoload singleton
extends Node

# -- Cached references --
var _eco: Node = null
var _world_env: WorldEnvironment = null
var _env: Environment = null
var _particles: GPUParticles3D = null
var _particle_mat: ParticleProcessMaterial = null

# -- State cache (avoid redundant updates) --
var _cached_density: float = -1.0
var _cached_kingdoms: Array = []
var _cached_terrain: String = ""
var _poll_timer: float = 0.0
var _initialized: bool = false

const POLL_INTERVAL := 1.0
const TWEEN_DURATION := 2.0


func _ready() -> void:
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_eco = get_node_or_null("/root/EcosystemManager")
	if _eco == null:
		push_warning("NatureRenderer: EcosystemManager not found — rendering disabled.")
		return

	_world_env = _find_world_environment()
	if _world_env and _world_env.environment:
		_env = _world_env.environment
	else:
		push_warning("NatureRenderer: No WorldEnvironment found — fog/sky disabled.")

	_create_particle_system()
	_initialized = true
	_poll_and_update()


func _process(delta: float) -> void:
	if not _initialized:
		return
	_poll_timer += delta
	if _poll_timer >= POLL_INTERVAL:
		_poll_timer = 0.0
		_poll_and_update()


# ---------------------------------------------------------------------------
# Polling
# ---------------------------------------------------------------------------

func _poll_and_update() -> void:
	if _eco == null:
		return

	var density: float = _eco.get_vegetation_density()
	var kingdoms: Array = _eco.get_allowed_kingdoms()
	var terrain: String = _eco._current_terrain_mode

	var changed := false
	if not is_equal_approx(density, _cached_density):
		changed = true
	if kingdoms != _cached_kingdoms:
		changed = true
	if terrain != _cached_terrain:
		changed = true

	if not changed:
		return

	_cached_density = density
	_cached_kingdoms = kingdoms.duplicate()
	_cached_terrain = terrain

	print("NatureRenderer: density=%.2f kingdoms=[%s] terrain=%s" % [
		density, ",".join(PackedStringArray(kingdoms)), terrain
	])

	_update_fog(density)
	_update_sky(density)
	_update_ground_tint(density)
	_update_particles(density)


# ---------------------------------------------------------------------------
# Fog
# ---------------------------------------------------------------------------

func _update_fog(density: float) -> void:
	if _env == null:
		return

	var enable := density > 0.0
	_env.fog_enabled = enable
	if not enable:
		return

	# Fog thins as nature grows: 0.05 at density 0 → 0.01 at density 1
	var target_fog_density := lerpf(0.05, 0.01, density)
	# Grey → warm green tint
	var target_color := Color(0.6, 0.6, 0.6).lerp(Color(0.55, 0.7, 0.5), density)
	var target_aerial := lerpf(0.0, 0.5, density)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_env, "fog_density", target_fog_density, TWEEN_DURATION)
	tw.tween_property(_env, "fog_light_color", target_color, TWEEN_DURATION)
	tw.tween_property(_env, "fog_aerial_perspective", target_aerial, TWEEN_DURATION)


# ---------------------------------------------------------------------------
# Sky / Ambient
# ---------------------------------------------------------------------------

func _update_sky(density: float) -> void:
	if _env == null:
		return

	# Grey → warm green → rich blue-green
	var mid := Color(0.45, 0.6, 0.4)
	var full := Color(0.35, 0.6, 0.55)
	var target_color: Color
	if density < 0.5:
		target_color = Color(0.5, 0.5, 0.5).lerp(mid, density * 2.0)
	else:
		target_color = mid.lerp(full, (density - 0.5) * 2.0)

	var target_energy := lerpf(0.3, 0.6, density)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_env, "ambient_light_color", target_color, TWEEN_DURATION)
	tw.tween_property(_env, "ambient_light_energy", target_energy, TWEEN_DURATION)


# ---------------------------------------------------------------------------
# Ground tint
# ---------------------------------------------------------------------------

func _update_ground_tint(density: float) -> void:
	var ground := _find_ground_node()
	if ground == null:
		return
	var mat: Material = null
	if ground is MeshInstance3D:
		mat = ground.get_active_material(0)
	elif ground.has_method("get_active_material"):
		mat = ground.get_active_material(0)
	if mat and mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("vegetation_tint", density)


# ---------------------------------------------------------------------------
# Particles
# ---------------------------------------------------------------------------

func _update_particles(density: float) -> void:
	if _particles == null:
		return

	var active := density > 0.2
	_particles.emitting = active
	if not active:
		return

	# 10 at 0.2 → 100 at 1.0
	var t := clampf((density - 0.2) / 0.8, 0.0, 1.0)
	_particles.amount = int(lerpf(10.0, 100.0, t))

	# Tint particles based on kingdoms
	var color := Color(0.5, 0.75, 0.4, 0.6)
	if "fungus" in _cached_kingdoms:
		color = Color(0.65, 0.55, 0.7, 0.6)
	elif "flower" in _cached_kingdoms:
		color = Color(0.8, 0.6, 0.5, 0.6)
	_particle_mat.color = color


func _create_particle_system() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "NatureParticles"
	_particles.emitting = false
	_particles.amount = 10
	_particles.lifetime = 6.0
	_particles.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 8, 20))

	_particle_mat = ParticleProcessMaterial.new()
	_particle_mat.direction = Vector3(0.0, -1.0, 0.0)
	_particle_mat.spread = 45.0
	_particle_mat.initial_velocity_min = 0.05
	_particle_mat.initial_velocity_max = 0.15
	_particle_mat.gravity = Vector3(0.0, -0.02, 0.0)
	_particle_mat.scale_min = 0.01
	_particle_mat.scale_max = 0.02
	_particle_mat.color = Color(0.5, 0.75, 0.4, 0.6)
	_particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_particle_mat.emission_box_extents = Vector3(8.0, 0.5, 8.0)
	_particles.process_material = _particle_mat

	# Minimal quad mesh for particles
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.02, 0.02)
	_particles.draw_pass_1 = mesh

	add_child(_particles)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _find_world_environment() -> WorldEnvironment:
	var nodes := get_tree().get_nodes_in_group("world_environment")
	if nodes.size() > 0 and nodes[0] is WorldEnvironment:
		return nodes[0] as WorldEnvironment
	# Fallback: search scene tree
	return _recursive_find(get_tree().root, "WorldEnvironment") as WorldEnvironment


func _recursive_find(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found := _recursive_find(child, type_name)
		if found:
			return found
	return null


func _find_ground_node() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	var ground := root.find_child("GridStructureComponent", true, false)
	if ground:
		return ground
	return root.find_child("Ground", true, false)


# ---------------------------------------------------------------------------
# Grid config compatibility
# ---------------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	# Reset to respond to new map context
	_cached_density = -1.0
	if _initialized:
		_poll_and_update()
