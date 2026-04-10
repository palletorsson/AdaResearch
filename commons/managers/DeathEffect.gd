# DeathEffect.gd — VR damage and death feedback
#
# Two modes:
#   HURT: Red flash + teleport to spawn point. Player keeps remaining health.
#         Triggered by hazards (fire, laser, electric, falling).
#   DEATH: Full sequence (red flash, shake, particles, fade) + map reload.
#         Triggered when health reaches 0.
#
# Autoload singleton — GameManager routes damage and death through here.

extends Node

# Timing
const HURT_FLASH_DURATION := 0.4      # Red flash on damage
const HURT_TELEPORT_DELAY := 0.3      # Teleport after brief flash
const DEATH_FLASH_DURATION := 0.15
const DEATH_SHAKE_DURATION := 0.4
const DEATH_SHAKE_INTENSITY := 0.08
const DEATH_FADE_DURATION := 0.8
const DEATH_TOTAL_DURATION := 1.5

# State
var _playing: bool = false
var _is_death: bool = false  # true = full death, false = hurt+respawn
var _timer: float = 0.0
var _death_pos: Vector3 = Vector3.ZERO
var _vignette_quad: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _original_camera_pos: Vector3 = Vector3.ZERO
var _xr_camera: XRCamera3D = null
var _rng := RandomNumberGenerator.new()

signal hurt_effect_complete()
signal death_effect_complete()


func _ready() -> void:
	_rng.randomize()
	# Clean up on scene changes (autoload survives scene reloads)
	get_tree().node_added.connect(_on_node_added)


## When a new XRCamera3D appears (scene reloaded), clean any stale vignette state.
func _on_node_added(node: Node) -> void:
	if node is XRCamera3D:
		# New camera means scene reloaded — force cleanup
		if _playing:
			_playing = false
			Engine.time_scale = 1.0
		_vignette_quad = null
		_particles = null
		_xr_camera = null
		# Remove any orphaned vignettes on this camera
		for child in node.get_children():
			if child.name == "DamageVignette":
				child.queue_free()


func _process(delta: float) -> void:
	if not _playing:
		return
	_timer += delta

	if _is_death:
		_process_death(delta)
	else:
		_process_hurt(delta)


# ═══════════════════════════════════════════════════════════════════════════
# HURT — Red flash + teleport to spawn (player survives)
# ═══════════════════════════════════════════════════════════════════════════

## Flash red and teleport player back to spawn. Health is NOT restored.
func hurt(damage_pos: Vector3) -> void:
	if _playing:
		return
	_playing = true
	_is_death = false
	_timer = 0.0
	_death_pos = damage_pos

	_xr_camera = _find_xr_camera()
	_create_vignette(Color(0.7, 0.0, 0.0, 0.6))
	_haptic_burst(0.15, 0.5)


func _process_hurt(_delta: float) -> void:
	# Flash phase
	if _timer < HURT_FLASH_DURATION:
		var t := _timer / HURT_FLASH_DURATION
		var alpha := 0.6 * (1.0 - t)  # Fade out
		_update_vignette_color(Color(0.7, 0.0, 0.0, alpha))
	else:
		# Reset the scene (reload map, keep health)
		_cleanup()
		var tree := get_tree()
		if tree:
			tree.reload_current_scene()
		hurt_effect_complete.emit()


func _teleport_to_spawn() -> void:
	# Find the spawn position from the grid system
	var spawn_pos := _find_spawn_position()
	var xr_origin := _find_xr_origin()
	if xr_origin and spawn_pos != Vector3.ZERO:
		xr_origin.global_position = spawn_pos
		print("[DeathEffect] Teleported to spawn at %s" % spawn_pos)
	else:
		print("[DeathEffect] Could not find spawn — no teleport")


func _find_spawn_position() -> Vector3:
	# Try GridSpawnComponent
	var grid_system := _find_node_by_group("grid_system")
	if grid_system:
		var spawn_comp = grid_system.get_node_or_null("GridSpawnComponent")
		if spawn_comp and "last_spawn_position" in spawn_comp:
			return spawn_comp.last_spawn_position

	# Try spawn utility positions from the scene tree
	var spawn_nodes := get_tree().get_nodes_in_group("spawn_point")
	if spawn_nodes.size() > 0:
		return spawn_nodes[0].global_position

	# Fallback: find "sp" utility marker
	var utilities := get_tree().get_nodes_in_group("utility_spawn")
	if utilities.size() > 0:
		return utilities[0].global_position

	# Last resort: find any node named SpawnPoint or similar
	var root := get_tree().current_scene
	if root:
		var sp := _find_node_by_name(root, "SpawnPoint")
		if sp and sp is Node3D:
			return (sp as Node3D).global_position

	return Vector3.ZERO


# ═══════════════════════════════════════════════════════════════════════════
# DEATH — Full sequence when health reaches 0
# ═══════════════════════════════════════════════════════════════════════════

## Full death: flash, shake, particles, fade, map reload.
func play(death_position: Vector3) -> void:
	if _playing:
		return
	_playing = true
	_is_death = true
	_timer = 0.0
	_death_pos = death_position
	Engine.time_scale = 1.0

	_xr_camera = _find_xr_camera()
	if _xr_camera:
		_original_camera_pos = _xr_camera.position

	_create_vignette(Color(0.8, 0.0, 0.0, 0.7))
	_create_particles(death_position)
	_haptic_burst(0.3, 0.8)


func _process_death(_delta: float) -> void:
	if _timer < DEATH_FLASH_DURATION:
		Engine.time_scale = 0.05

	elif _timer < DEATH_FLASH_DURATION + DEATH_SHAKE_DURATION:
		Engine.time_scale = 1.0
		var shake_t := (_timer - DEATH_FLASH_DURATION) / DEATH_SHAKE_DURATION
		var intensity := DEATH_SHAKE_INTENSITY * (1.0 - shake_t)
		if _xr_camera and is_instance_valid(_xr_camera):
			_xr_camera.position = _original_camera_pos + Vector3(
				_rng.randf_range(-intensity, intensity),
				_rng.randf_range(-intensity, intensity),
				_rng.randf_range(-intensity, intensity)
			)
		_update_vignette_color(Color(0.5, 0.0, 0.0, 0.7 * (1.0 - shake_t * 0.5)))

	elif _timer < DEATH_FLASH_DURATION + DEATH_SHAKE_DURATION + DEATH_FADE_DURATION:
		var fade_t := (_timer - DEATH_FLASH_DURATION - DEATH_SHAKE_DURATION) / DEATH_FADE_DURATION
		_update_vignette_color(Color(0, 0, 0, fade_t))

	elif _timer >= DEATH_TOTAL_DURATION:
		_cleanup()
		death_effect_complete.emit()


func cancel() -> void:
	if _playing:
		_cleanup()


# ═══════════════════════════════════════════════════════════════════════════
# VIGNETTE
# ═══════════════════════════════════════════════════════════════════════════

func _create_vignette(color: Color) -> void:
	if not _xr_camera or not is_instance_valid(_xr_camera):
		return
	_vignette_quad = MeshInstance3D.new()
	_vignette_quad.name = "DamageVignette"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	_vignette_quad.mesh = quad
	_vignette_quad.position = Vector3(0, 0, -0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.render_priority = 100
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_vignette_quad.material_override = mat
	_xr_camera.add_child(_vignette_quad)


func _update_vignette_color(color: Color) -> void:
	if _vignette_quad and is_instance_valid(_vignette_quad) and _vignette_quad.material_override:
		(_vignette_quad.material_override as StandardMaterial3D).albedo_color = color


# ═══════════════════════════════════════════════════════════════════════════
# PARTICLES (death only)
# ═══════════════════════════════════════════════════════════════════════════

func _create_particles(pos: Vector3) -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "DeathParticles"
	_particles.amount = 40
	_particles.lifetime = 1.2
	_particles.one_shot = true
	_particles.explosiveness = 0.95
	_particles.global_position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.03
	mat.scale_max = 0.1
	mat.color = Color(0.8, 0.15, 0.1)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.9, 0.2, 0.1, 1.0))
	gradient.add_point(0.4, Color(0.5, 0.05, 0.05, 0.9))
	gradient.add_point(1.0, Color(0.2, 0.02, 0.02, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	_particles.process_material = mat

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.05, 0.03, 0.04)
	_particles.draw_pass_1 = mesh
	var draw_mat := StandardMaterial3D.new()
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.6, 0.1, 0.05)
	draw_mat.emission_energy_multiplier = 2.0
	_particles.material_override = draw_mat

	get_tree().current_scene.add_child(_particles)
	_particles.emitting = true


# ═══════════════════════════════════════════════════════════════════════════
# HAPTIC + CLEANUP + UTILITIES
# ═══════════════════════════════════════════════════════════════════════════

func _haptic_burst(duration: float, amplitude: float) -> void:
	var xr_origin := _find_xr_origin()
	if not xr_origin:
		return
	for child in xr_origin.get_children():
		if child is XRController3D:
			child.trigger_haptic_pulse("haptic", 0.0, duration, amplitude, 0.0)


func _cleanup() -> void:
	Engine.time_scale = 1.0
	_playing = false
	if _vignette_quad and is_instance_valid(_vignette_quad):
		_vignette_quad.queue_free()
	_vignette_quad = null
	if _particles and is_instance_valid(_particles):
		_particles.queue_free()
	_particles = null
	if _xr_camera and is_instance_valid(_xr_camera) and _is_death:
		_xr_camera.position = _original_camera_pos
	_xr_camera = null


func _find_xr_camera() -> XRCamera3D:
	var origins := get_tree().get_nodes_in_group("xr_origin")
	for origin in origins:
		for child in origin.get_children():
			if child is XRCamera3D:
				return child
	return null


func _find_xr_origin() -> XROrigin3D:
	var origins := get_tree().get_nodes_in_group("xr_origin")
	if origins.size() > 0:
		return origins[0] as XROrigin3D
	return null


func _find_node_by_group(group_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		return nodes[0]
	return null


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null
