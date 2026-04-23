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

# -- Living ground (presence-driven terrain) --
const _PresenceGridScript = preload("res://algorithms/nature_system/systems/presence_grid.gd")
const _GroundSpawnerScript = preload("res://algorithms/nature_system/systems/ground_spawner.gd")
var _living_ground_mesh: MeshInstance3D = null
var _presence_grid = null  # PresenceGrid instance
var _ground_spawner = null  # GroundSpawner instance
var _living_ground_active: bool = false

# -- Evolution + Transmutation (self_generating mode) --
var _evolution_system = null  # EvolutionSystem instance
var _transmutation_manager = null  # TransmutationManager instance

# -- Per-map environment overrides --
var _map_overrides: Dictionary = {}

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
	# Capture-mode guard: when `--no-bridges` is passed, skip all ecosystem
	# hookup, particle allocation, and living-ground init. These need a
	# populated EcosystemManager + WorldEnvironment that the capture
	# scaffold doesn't provide, and the resulting null derefs were
	# blocking glass-rack / interactable-scenes / big-pipe renders.
	if "--no-bridges" in OS.get_cmdline_user_args() or "--no-bridges" in OS.get_cmdline_args():
		print("NatureRenderer: disabled by --no-bridges")
		return

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

	# Apply per-map overrides if present
	var effective_density: float = _map_overrides.get("vegetation_density", density)
	var effective_terrain: String = _map_overrides.get("terrain_mode", terrain)

	_update_fog(effective_density)
	_update_sky(effective_density)
	_update_ground_tint(effective_density)
	_update_particles(effective_density)
	_update_living_ground(effective_terrain, effective_density, kingdoms)


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


func _find_grid_data() -> GridDataComponent:
	var root := get_tree().current_scene
	if root == null:
		return null
	var gd := root.find_child("GridDataComponent", true, false)
	if gd and gd is GridDataComponent:
		return gd as GridDataComponent
	return null


# ---------------------------------------------------------------------------
# Living Ground — presence-driven terrain overlay
# ---------------------------------------------------------------------------

func _update_living_ground(terrain_mode: String, density: float, kingdoms: Array) -> void:
	# Living ground overlay disabled — biome ring handles ground visuals.
	# The shader PlaneMesh was rendering as a black rectangle in VR.
	var should_be_active: bool = false

	if should_be_active and not _living_ground_active:
		_activate_living_ground(terrain_mode, density, kingdoms)
	elif not should_be_active and _living_ground_active:
		_deactivate_living_ground()

	# Update presence deposits from nearby organisms
	if _living_ground_active and _presence_grid:
		_deposit_nearby_organisms()
		_presence_grid.process(POLL_INTERVAL)
		# Update shader texture
		if _living_ground_mesh and _living_ground_mesh.material_override is ShaderMaterial:
			(_living_ground_mesh.material_override as ShaderMaterial).set_shader_parameter(
				"presence_map", _presence_grid.get_texture()
			)
		# Run ground spawner + evolution for self-generating mode
		if terrain_mode == "self_generating":
			if _ground_spawner:
				_ground_spawner.process(POLL_INTERVAL)
			if _evolution_system and _evolution_system.has_method("process"):
				_evolution_system.process(POLL_INTERVAL)


func _activate_living_ground(terrain_mode: String, density: float, kingdoms: Array) -> void:
	print("NatureRenderer: Activating living ground (mode=%s)" % terrain_mode)

	# Create presence grid sized to the map
	var grid_data := _find_grid_data()
	var map_size: Vector2 = Vector2(20.0, 20.0)  # default
	if grid_data:
		var dims: Vector3i = grid_data.get_grid_dimensions()
		var cube_size: float = grid_data.get_settings().get("cube_size", 1.0)
		map_size = Vector2(float(dims.x) * cube_size, float(dims.z) * cube_size)

	_presence_grid = _PresenceGridScript.new(128, map_size)

	# Create ground spawner + evolution system for self_generating mode
	if terrain_mode == "self_generating":
		var scene_root: Node3D = get_tree().current_scene as Node3D
		if not scene_root:
			return

		# Ground spawner: organisms propagate from fertile ground
		_ground_spawner = _GroundSpawnerScript.new()
		_ground_spawner.presence = _presence_grid
		_ground_spawner.terrain_size = maxf(map_size.x, map_size.y)
		var spawner := CritterSpawner.new(scene_root)
		spawner.max_population = 30
		_ground_spawner.spawner = spawner

		# Evolution system: generational cycles, breeding, culling
		if ClassDB.class_exists("EvolutionSystem") or ResourceLoader.exists("res://algorithms/nature_system/systems/evolution_system.gd"):
			var evo_script = load("res://algorithms/nature_system/systems/evolution_system.gd")
			if evo_script:
				_evolution_system = evo_script.new()
				_evolution_system.name = "EvolutionSystem"
				if "spawner" in _evolution_system:
					_evolution_system.spawner = spawner
				scene_root.add_child(_evolution_system)
				if _evolution_system.has_method("start"):
					_evolution_system.start()
				print("NatureRenderer: EvolutionSystem started (self_generating)")

		# Transmutation manager: player bonding with creatures
		if ResourceLoader.exists("res://algorithms/nature_system/systems/transmutation_manager.gd"):
			var trans_script = load("res://algorithms/nature_system/systems/transmutation_manager.gd")
			if trans_script:
				_transmutation_manager = trans_script.new()
				_transmutation_manager.name = "TransmutationManager"
				scene_root.add_child(_transmutation_manager)
				print("NatureRenderer: TransmutationManager started (self_generating)")

	# Create living ground mesh overlay
	var shader_path: String = "res://algorithms/nature_system/shaders/living_ground.gdshader"
	if ResourceLoader.exists(shader_path):
		_living_ground_mesh = MeshInstance3D.new()
		_living_ground_mesh.name = "LivingGround"
		var plane := PlaneMesh.new()
		plane.size = map_size
		plane.subdivide_depth = 32
		plane.subdivide_width = 32
		_living_ground_mesh.mesh = plane
		_living_ground_mesh.position.y = 0.01  # Slightly above grid floor to avoid z-fighting

		var shader: Shader = load(shader_path)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("world_size", map_size)
		mat.set_shader_parameter("world_offset", Vector2.ZERO)
		mat.set_shader_parameter("presence_map", _presence_grid.get_texture())
		# Make slightly transparent so grid cubes show through at edges
		mat.render_priority = 1
		_living_ground_mesh.material_override = mat

		# Add to current scene
		var current := get_tree().current_scene
		if current:
			current.add_child(_living_ground_mesh)

	_living_ground_active = true


func _deactivate_living_ground() -> void:
	if _living_ground_mesh and is_instance_valid(_living_ground_mesh):
		_living_ground_mesh.queue_free()
	_living_ground_mesh = null
	_presence_grid = null
	_ground_spawner = null
	if _evolution_system and is_instance_valid(_evolution_system):
		_evolution_system.queue_free()
	_evolution_system = null
	if _transmutation_manager and is_instance_valid(_transmutation_manager):
		_transmutation_manager.queue_free()
	_transmutation_manager = null
	_living_ground_active = false
	print("NatureRenderer: Deactivated living ground")


func _deposit_nearby_organisms() -> void:
	if not _presence_grid:
		return
	# Find CritterEntity nodes in scene
	var root := get_tree().current_scene
	if not root:
		return
	_deposit_recursive(root)


func _deposit_recursive(node: Node) -> void:
	if node is CritterEntity:
		var entity := node as CritterEntity
		if entity.dna:
			_presence_grid.deposit_from_entity(
				entity.global_position,
				entity.get_kingdom(),
				entity.dna.scent_strength,
				entity.dna.scale
			)
	elif node.has_meta("is_critter_placer"):
		# CritterPlacer grid artifacts — deposit their organism's presence
		var dna = node.get_meta("dna", null)
		if dna and dna is CritterDNA:
			_presence_grid.deposit_from_entity(
				node.global_position,
				(dna as CritterDNA).get_kingdom(),
				(dna as CritterDNA).scent_strength,
				(dna as CritterDNA).scale
			)
	for child in node.get_children():
		_deposit_recursive(child)


# ---------------------------------------------------------------------------
# Per-map environment overrides
# ---------------------------------------------------------------------------

## Called when a new map loads — checks for per-map "environment" overrides.
func load_map_overrides(overrides: Dictionary) -> void:
	_map_overrides = overrides
	if not overrides.is_empty():
		print("NatureRenderer: Loaded %d per-map overrides" % overrides.size())
	# Force re-poll to apply overrides
	_cached_density = -1.0
	if _initialized:
		_poll_and_update()


## Called when leaving a map — clear overrides.
func clear_map_overrides() -> void:
	_map_overrides = {}
	_cached_density = -1.0
	_deactivate_living_ground()
	if _initialized:
		_poll_and_update()


# ---------------------------------------------------------------------------
# Grid config compatibility
# ---------------------------------------------------------------------------

func apply_grid_config(config_data: Dictionary) -> void:
	# Reset to respond to new map context
	_cached_density = -1.0
	# Check for per-map overrides from GridDataComponent
	var grid_data := _find_grid_data()
	if grid_data:
		load_map_overrides(grid_data.get_environment_overrides())
	if _initialized:
		_poll_and_update()
