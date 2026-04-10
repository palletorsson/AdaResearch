# DeathEffect.gd — Visceral VR death feedback
#
# Triggered when player dies. Plays a fast, punchy sequence:
#   1. Red vignette flash (screen-space quad in front of VR camera)
#   2. Camera shake (rapid oscillation on XR camera)
#   3. Meat/debris particles burst outward from death position
#   4. Brief freeze-frame (time scale pause)
#   5. Fade to black
#   6. Map reload
#
# Autoload singleton — GameManager calls DeathEffect.play(death_position)

extends Node
class_name DeathEffect

# Timing
const FLASH_DURATION := 0.15        # Red flash
const SHAKE_DURATION := 0.4         # Camera shake
const SHAKE_INTENSITY := 0.08       # Meters of shake offset
const FREEZE_DURATION := 0.2        # Time-freeze on hit
const FADE_DURATION := 0.8          # Fade to black
const RELOAD_DELAY := 1.5           # Total time before map reload

# State
var _playing: bool = false
var _timer: float = 0.0
var _death_pos: Vector3 = Vector3.ZERO
var _vignette_quad: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _original_camera_pos: Vector3 = Vector3.ZERO
var _shake_offset: Vector3 = Vector3.ZERO
var _xr_camera: XRCamera3D = null
var _rng := RandomNumberGenerator.new()

signal death_effect_complete()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if not _playing:
		return

	_timer += delta

	# Phase 1: Red flash + freeze (0 → 0.15s)
	if _timer < FLASH_DURATION:
		_update_vignette(1.0)
		Engine.time_scale = 0.05  # Near-freeze

	# Phase 2: Shake + unfreeze (0.15 → 0.55s)
	elif _timer < FLASH_DURATION + SHAKE_DURATION:
		Engine.time_scale = 1.0
		var shake_t: float = (_timer - FLASH_DURATION) / SHAKE_DURATION
		var intensity: float = SHAKE_INTENSITY * (1.0 - shake_t)  # Decay
		_shake_offset = Vector3(
			_rng.randf_range(-intensity, intensity),
			_rng.randf_range(-intensity, intensity),
			_rng.randf_range(-intensity, intensity)
		)
		if _xr_camera and is_instance_valid(_xr_camera):
			_xr_camera.position = _original_camera_pos + _shake_offset
		_update_vignette(1.0 - shake_t * 0.5)  # Fade vignette

	# Phase 3: Fade to black (0.55 → 1.35s)
	elif _timer < FLASH_DURATION + SHAKE_DURATION + FADE_DURATION:
		var fade_t: float = (_timer - FLASH_DURATION - SHAKE_DURATION) / FADE_DURATION
		_update_vignette(0.5 + fade_t * 0.5)  # Darken to full black
		if _vignette_quad and _vignette_quad.material_override:
			(_vignette_quad.material_override as StandardMaterial3D).albedo_color = Color(0, 0, 0, fade_t)

	# Phase 4: Reload
	elif _timer >= RELOAD_DELAY:
		_cleanup()
		death_effect_complete.emit()


## Play the death effect at a world position.
func play(death_position: Vector3) -> void:
	if _playing:
		return
	_playing = true
	_timer = 0.0
	_death_pos = death_position
	Engine.time_scale = 1.0

	# Find VR camera
	_xr_camera = _find_xr_camera()
	if _xr_camera:
		_original_camera_pos = _xr_camera.position

	_create_vignette()
	_create_particles(death_position)
	_haptic_burst()


## Cancel and clean up (e.g., if scene is changing).
func cancel() -> void:
	if _playing:
		_cleanup()


# ═══════════════════════════════════════════════════════════════════════════
# VIGNETTE — Red flash quad attached to VR camera
# ═══════════════════════════════════════════════════════════════════════════

func _create_vignette() -> void:
	if not _xr_camera or not is_instance_valid(_xr_camera):
		return

	_vignette_quad = MeshInstance3D.new()
	_vignette_quad.name = "DeathVignette"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # Large enough to fill VR view
	_vignette_quad.mesh = quad
	_vignette_quad.position = Vector3(0, 0, -0.5)  # Close to camera

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 0.0, 0.7)  # Red flash
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.render_priority = 100
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_vignette_quad.material_override = mat

	_xr_camera.add_child(_vignette_quad)


func _update_vignette(intensity: float) -> void:
	if not _vignette_quad or not is_instance_valid(_vignette_quad):
		return
	var mat: StandardMaterial3D = _vignette_quad.material_override
	if mat:
		mat.albedo_color.a = clampf(intensity * 0.8, 0.0, 1.0)


# ═══════════════════════════════════════════════════════════════════════════
# PARTICLES — Meat/debris burst from death position
# ═══════════════════════════════════════════════════════════════════════════

func _create_particles(pos: Vector3) -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "DeathParticles"
	_particles.amount = 40
	_particles.lifetime = 1.2
	_particles.one_shot = true
	_particles.explosiveness = 0.95
	_particles.global_position = pos

	# Particle material
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0  # Omnidirectional burst
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.03
	mat.scale_max = 0.1
	mat.color = Color(0.8, 0.15, 0.1)  # Dark red chunks
	# Color ramp: red → dark → fade
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.9, 0.2, 0.1, 1.0))
	gradient.add_point(0.4, Color(0.5, 0.05, 0.05, 0.9))
	gradient.add_point(1.0, Color(0.2, 0.02, 0.02, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex
	_particles.process_material = mat

	# Mesh for each particle — small irregular chunks
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
# HAPTIC — Controller vibration burst
# ═══════════════════════════════════════════════════════════════════════════

func _haptic_burst() -> void:
	var xr_origin := _find_xr_origin()
	if not xr_origin:
		return
	for child in xr_origin.get_children():
		if child is XRController3D:
			child.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.8, 0.0)


# ═══════════════════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════════════════

func _cleanup() -> void:
	Engine.time_scale = 1.0
	_playing = false
	if _vignette_quad and is_instance_valid(_vignette_quad):
		_vignette_quad.queue_free()
	_vignette_quad = null
	if _particles and is_instance_valid(_particles):
		_particles.queue_free()
	_particles = null
	if _xr_camera and is_instance_valid(_xr_camera):
		_xr_camera.position = _original_camera_pos
	_xr_camera = null


func _find_xr_camera() -> XRCamera3D:
	var origins := get_tree().get_nodes_in_group("xr_origin")
	for origin in origins:
		for child in origin.get_children():
			if child is XRCamera3D:
				return child
	# Fallback: search scene tree
	return _find_typed(get_tree().root, "XRCamera3D") as XRCamera3D


func _find_xr_origin() -> XROrigin3D:
	var origins := get_tree().get_nodes_in_group("xr_origin")
	if origins.size() > 0:
		return origins[0] as XROrigin3D
	return _find_typed(get_tree().root, "XROrigin3D") as XROrigin3D


func _find_typed(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found := _find_typed(child, type_name)
		if found:
			return found
	return null
