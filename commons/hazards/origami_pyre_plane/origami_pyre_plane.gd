# OrigamiPyrePlane — floor hazard for the transformation sequence
# A flat origami rectangle that smolders with paper-fire beneath transport cubes.
# Its creased edges glow orange as it cycles through affine transformations —
# scaling, rotating, and translating — while preserving its rectangular identity.
# The invariant is the shape; the hazard is the heat. Lethal on contact.
extends Node3D
class_name OrigamiPyrePlane

signal player_killed(player: Node3D)

enum AffinePhase { SCALE, ROTATE, TRANSLATE }

# ── Geometry ─────────────────────────────────────────────────────────────
@export var base_width: float = 2.0
@export var base_depth: float = 3.0
@export var crease_count: int = 4

# ── Affine Cycle ─────────────────────────────────────────────────────────
@export var scale_pulse_range: Vector2 = Vector2(0.8, 1.2)
@export var rotation_speed: float = 0.3
@export var translation_drift: float = 0.5
@export var cycle_duration: float = 4.0

# ── Combat ───────────────────────────────────────────────────────────────
@export var damage_on_enter: float = 100.0

# ── Appearance ───────────────────────────────────────────────────────────
@export var parchment_color: Color = Color(0.82, 0.72, 0.55, 1.0)
@export var ember_color: Color = Color(1.0, 0.45, 0.05, 1.0)
@export var crease_glow_color: Color = Color(1.0, 0.55, 0.1, 1.0)

# Internal state
var _current_phase: AffinePhase = AffinePhase.SCALE
var _phase_time: float = 0.0
var _total_time: float = 0.0
var _origin_pos: Vector3 = Vector3.ZERO
var _origin_rotation: float = 0.0

# Visual nodes
var _mesh_root: Node3D = null
var _paper_mesh: MeshInstance3D = null
var _paper_im: ImmediateMesh = null
var _paper_material: StandardMaterial3D = null
var _crease_mesh: MeshInstance3D = null
var _crease_im: ImmediateMesh = null
var _crease_material: StandardMaterial3D = null
var _kill_zone: Area3D = null
var _ember_particles: GPUParticles3D = null
var _glow_light: OmniLight3D = null


func _ready() -> void:
	_origin_pos = position
	_origin_rotation = rotation.y
	_create_materials()
	_build_mesh_root()
	_build_paper_geometry()
	_build_crease_lines()
	_build_kill_zone()
	_build_ember_particles()
	_build_glow_light()


func _process(delta: float) -> void:
	_total_time += delta
	_phase_time += delta

	if _phase_time >= cycle_duration:
		_phase_time -= cycle_duration
		_advance_phase()

	_process_affine_cycle(delta)
	_update_crease_glow()
	_update_fold_breathe()


# ── Materials ────────────────────────────────────────────────────────────

func _create_materials() -> void:
	_paper_material = StandardMaterial3D.new()
	_paper_material.albedo_color = parchment_color
	_paper_material.metallic = 0.0
	_paper_material.roughness = 0.85
	_paper_material.emission_enabled = true
	_paper_material.emission = ember_color * 0.3
	_paper_material.emission_energy_multiplier = 0.4
	_paper_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_glow_color
	_crease_material.metallic = 0.1
	_crease_material.roughness = 0.3
	_crease_material.emission_enabled = true
	_crease_material.emission = crease_glow_color
	_crease_material.emission_energy_multiplier = 1.5


# ── Mesh Construction ────────────────────────────────────────────────────

func _build_mesh_root() -> void:
	_mesh_root = Node3D.new()
	_mesh_root.name = "PaperMesh"
	add_child(_mesh_root)


func _build_paper_geometry() -> void:
	_paper_im = ImmediateMesh.new()
	_paper_mesh = MeshInstance3D.new()
	_paper_mesh.name = "PaperSurface"
	_paper_mesh.mesh = _paper_im
	_paper_mesh.material_override = _paper_material
	_mesh_root.add_child(_paper_mesh)
	_rebuild_paper()


func _rebuild_paper() -> void:
	if not _paper_im:
		return

	_paper_im.clear_surfaces()
	_paper_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var hw: float = base_width * 0.5
	var hd: float = base_depth * 0.5
	# Number of subdivisions along depth for crease panels
	var panels: int = crease_count + 1
	var panel_depth: float = base_depth / float(panels)

	for p in range(panels):
		var z0: float = -hd + float(p) * panel_depth
		var z1: float = z0 + panel_depth
		# Slight Y lift at crease lines to simulate folded paper
		var y0: float = _fold_height(p)
		var y1: float = _fold_height(p + 1)

		var v00: Vector3 = Vector3(-hw, y0, z0)
		var v10: Vector3 = Vector3(hw, y0, z0)
		var v01: Vector3 = Vector3(-hw, y1, z1)
		var v11: Vector3 = Vector3(hw, y1, z1)

		var normal: Vector3 = (v10 - v00).cross(v01 - v00).normalized()

		# Triangle 1
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v00)
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v10)
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v01)

		# Triangle 2
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v10)
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v11)
		_paper_im.surface_set_normal(normal)
		_paper_im.surface_add_vertex(v01)

	_paper_im.surface_end()


func _fold_height(crease_index: int) -> float:
	# Alternating ridge/valley folds — subtle paper lift
	var breath: float = sin(_total_time * 1.2) * 0.02
	if crease_index == 0 or crease_index == crease_count + 1:
		return 0.0
	if crease_index % 2 == 1:
		return 0.04 + breath
	return -0.02 + breath * 0.5


func _build_crease_lines() -> void:
	_crease_im = ImmediateMesh.new()
	_crease_mesh = MeshInstance3D.new()
	_crease_mesh.name = "CreaseLines"
	_crease_mesh.mesh = _crease_im
	_crease_mesh.material_override = _crease_material
	_mesh_root.add_child(_crease_mesh)
	_rebuild_creases()


func _rebuild_creases() -> void:
	if not _crease_im:
		return

	_crease_im.clear_surfaces()
	_crease_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var hw: float = base_width * 0.5
	var hd: float = base_depth * 0.5
	var panel_depth: float = base_depth / float(crease_count + 1)

	for c in range(1, crease_count + 1):
		var z: float = -hd + float(c) * panel_depth
		var y: float = _fold_height(c)
		_crease_im.surface_set_normal(Vector3.UP)
		_crease_im.surface_add_vertex(Vector3(-hw, y + 0.005, z))
		_crease_im.surface_set_normal(Vector3.UP)
		_crease_im.surface_add_vertex(Vector3(hw, y + 0.005, z))

	_crease_im.surface_end()


# ── Kill Zone ────────────────────────────────────────────────────────────

func _build_kill_zone() -> void:
	_kill_zone = Area3D.new()
	_kill_zone.name = "KillZone"
	_kill_zone.collision_layer = 0
	_kill_zone.collision_mask = 2  # Player layer
	_kill_zone.monitoring = true

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	col_shape.name = "CollisionShape"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(base_width, 0.3, base_depth)
	col_shape.shape = box
	col_shape.position = Vector3(0.0, 0.15, 0.0)
	_kill_zone.add_child(col_shape)

	_kill_zone.body_entered.connect(_on_body_entered)
	_mesh_root.add_child(_kill_zone)


func _on_body_entered(body: Node3D) -> void:
	if not _is_player(body):
		return

	# Instant kill
	for method in ["die", "take_damage", "apply_damage", "damage"]:
		if body.has_method(method):
			if method == "die":
				body.call(method)
			else:
				body.call(method, damage_on_enter)
			break

	# Flare burst on kill
	_spawn_flare_burst()
	player_killed.emit(body)


func _is_player(body: Node3D) -> bool:
	return (body.is_in_group("player") or
			"player" in body.name.to_lower() or
			body.has_method("take_damage"))


func _spawn_flare_burst() -> void:
	var burst: GPUParticles3D = GPUParticles3D.new()
	burst.emitting = true
	burst.amount = 40
	burst.lifetime = 0.8
	burst.one_shot = true
	burst.explosiveness = 1.0

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 45.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0.0, -4.0, 0.0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = ember_color
	burst.process_material = mat
	burst.draw_pass_1 = QuadMesh.new()

	_mesh_root.add_child(burst)

	# Cleanup after burst completes
	var cleanup: Timer = Timer.new()
	cleanup.wait_time = 2.0
	cleanup.one_shot = true
	cleanup.timeout.connect(burst.queue_free)
	burst.add_child(cleanup)
	cleanup.start()


# ── Ember Particles ──────────────────────────────────────────────────────

func _build_ember_particles() -> void:
	_ember_particles = GPUParticles3D.new()
	_ember_particles.name = "EmberParticles"
	_ember_particles.amount = 30
	_ember_particles.lifetime = 1.5
	_ember_particles.emitting = true

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 1.0
	mat.gravity = Vector3(0.0, 0.5, 0.0)  # Embers drift upward
	mat.scale_min = 0.02
	mat.scale_max = 0.06
	mat.color = ember_color

	# Emission box matching the rectangle
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(base_width * 0.5, 0.02, base_depth * 0.5)

	# Fade over lifetime
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, ember_color)
	gradient.add_point(0.7, Color(ember_color.r, ember_color.g * 0.5, 0.0, 0.8))
	gradient.add_point(1.0, Color(0.3, 0.05, 0.0, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	_ember_particles.process_material = mat
	_ember_particles.draw_pass_1 = QuadMesh.new()
	_ember_particles.position = Vector3(0.0, 0.05, 0.0)

	_mesh_root.add_child(_ember_particles)


# ── Glow Light ───────────────────────────────────────────────────────────

func _build_glow_light() -> void:
	_glow_light = OmniLight3D.new()
	_glow_light.name = "GlowLight"
	_glow_light.light_color = ember_color
	_glow_light.light_energy = 0.6
	_glow_light.omni_range = max(base_width, base_depth) * 0.8
	_glow_light.omni_attenuation = 1.5
	_glow_light.position = Vector3(0.0, 0.1, 0.0)
	_mesh_root.add_child(_glow_light)


# ── Affine Cycle ─────────────────────────────────────────────────────────

func _advance_phase() -> void:
	match _current_phase:
		AffinePhase.SCALE:
			_current_phase = AffinePhase.ROTATE
		AffinePhase.ROTATE:
			_current_phase = AffinePhase.TRANSLATE
		AffinePhase.TRANSLATE:
			_current_phase = AffinePhase.SCALE


func _process_affine_cycle(_delta: float) -> void:
	var t: float = _phase_time / cycle_duration  # 0..1 within current phase

	match _current_phase:
		AffinePhase.SCALE:
			_apply_scale_phase(t)
		AffinePhase.ROTATE:
			_apply_rotate_phase(t)
		AffinePhase.TRANSLATE:
			_apply_translate_phase(t)


func _apply_scale_phase(t: float) -> void:
	# Pulse scale using a smooth sine curve, return to 1.0 at phase end
	var wave: float = sin(t * TAU)
	var s: float = lerp(1.0, lerp(scale_pulse_range.x, scale_pulse_range.y, (wave + 1.0) * 0.5), abs(wave))
	_mesh_root.scale = Vector3(s, 1.0, s)
	# Reset other transforms
	_mesh_root.rotation.y = _origin_rotation
	position = _origin_pos


func _apply_rotate_phase(t: float) -> void:
	# Smooth yaw sweep and return
	var sweep: float = sin(t * TAU) * rotation_speed * cycle_duration
	_mesh_root.rotation.y = _origin_rotation + sweep
	# Reset other transforms
	_mesh_root.scale = Vector3.ONE
	position = _origin_pos


func _apply_translate_phase(t: float) -> void:
	# Drift along X then return, using smooth sine
	var drift: float = sin(t * TAU) * translation_drift
	position = _origin_pos + Vector3(drift, 0.0, 0.0)
	# Reset other transforms
	_mesh_root.scale = Vector3.ONE
	_mesh_root.rotation.y = _origin_rotation


# ── Crease Glow Update ──────────────────────────────────────────────────

func _update_crease_glow() -> void:
	if not _crease_material:
		return

	# Brighten crease lines during active phase transition moments
	var phase_t: float = _phase_time / cycle_duration
	var intensity: float = 1.5 + sin(phase_t * TAU * 2.0) * 0.8
	_crease_material.emission_energy_multiplier = intensity


# ── Fold Breathe Animation ───────────────────────────────────────────────

func _update_fold_breathe() -> void:
	# Rebuild paper and crease geometry each frame for breathing effect
	_rebuild_paper()
	_rebuild_creases()

	# Pulse the underglow light
	if _glow_light:
		_glow_light.light_energy = 0.6 + sin(_total_time * 2.0) * 0.2


# ── Grid Config ──────────────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("base_width"):
		base_width = float(config_data["base_width"])
	if config_data.has("base_depth"):
		base_depth = float(config_data["base_depth"])
	if config_data.has("scale_pulse_range"):
		var r = config_data["scale_pulse_range"]
		if r is Array and r.size() >= 2:
			scale_pulse_range = Vector2(float(r[0]), float(r[1]))
	if config_data.has("rotation_speed"):
		rotation_speed = float(config_data["rotation_speed"])
	if config_data.has("translation_drift"):
		translation_drift = float(config_data["translation_drift"])
	if config_data.has("cycle_duration"):
		cycle_duration = float(config_data["cycle_duration"])
	if config_data.has("damage_on_enter"):
		damage_on_enter = float(config_data["damage_on_enter"])
	if config_data.has("crease_count"):
		crease_count = int(config_data["crease_count"])
	if config_data.has("ember_color"):
		var c = config_data["ember_color"]
		if c is String:
			ember_color = Color(c)
		elif c is Color:
			ember_color = c
