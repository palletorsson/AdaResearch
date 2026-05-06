# @identity
# essence: form(contact) -> transmute(effect) -- raw energy that takes shape from what touches it
# desire: plasma that shocks raw, becomes fire via stick, becomes healing via water -- dual-nature
# critical_parameter: current_form -- raw/fire/healing determined by what mediator contacts the plasma
# triggers: stick_tool contact -> fire form; water -> healing; no mediator -> raw damage
# emerges: Q-FEP dual-nature at creature scale -- same energy, different relation, different outcome
# needs: Area3D [has]; form state machine [has]; mediator detection [has]; multiple effects [has]; VR interaction [missing]
# relationships: paired with stick_tool and force_field; central Q-FEP dual-nature demonstration
# truth: the plasma is the same substance whether it burns or heals -- the mediator determines manifestation.

# PlasmaCritter.gd
# A shapeshifting energy substance — the first critter.
# In its raw form it shocks on contact. Touch it with a stick → fire torch.
# Future forms: heal (water), power (crystal), gel (surface coating).
# Q-FEP: same substance, different relational context, different manifestation.
extends Area3D
class_name PlasmaCritter

# ── Forms ──────────────────────────────────────────────────────────────────
enum Form { RAW, FIRE, HEAL, POWER, GEL }

# ── Configuration ──────────────────────────────────────────────────────────
@export_group("Plasma")
@export var starting_form: Form = Form.RAW
@export var interaction_radius: float = 0.6
@export var raw_damage: float = 5.0
@export var fire_damage: float = 15.0
@export var burn_duration: float = 60.0   ## Seconds of fuel when in a non-RAW form
@export var respawn_delay: float = 5.0    ## Seconds before reappearing at home
@export var heal_per_second: float = 8.0

@export_group("Combat")
@export var damage_cooldown: float = 0.8
@export var contact_damage_enabled: bool = true

@export_group("Visual")
@export var core_radius: float = 0.18
@export var particle_count: int = 50
@export var light_range: float = 6.0
@export var light_energy: float = 2.5

# ── State ──────────────────────────────────────────────────────────────────
var current_form: Form = Form.RAW
var _home_position: Vector3 = Vector3.ZERO
var _fuel: float = 0.0
var _attached_to: Node3D = null     # The node we're riding (e.g. stick tip)
var _damage_timer: float = 0.0
var _pulse_time: float = 0.0
var _is_depleted: bool = false      # Waiting to respawn
var _respawn_timer: float = 0.0

# ── Visual nodes ───────────────────────────────────────────────────────────
var _visual_root: Node3D = null
var _core_mesh: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _light: OmniLight3D = null
var _collision: CollisionShape3D = null

# ── Form visual configs ───────────────────────────────────────────────────
const FORM_VISUALS := {
	Form.RAW: {
		"core_color": Color(0.7, 0.85, 1.0, 1.0),
		"emission": Color(0.5, 0.7, 1.0),
		"emission_energy": 2.0,
		"light_color": Color(0.6, 0.75, 1.0),
		"light_energy": 1.5,
		"particle_color_start": Color(0.6, 0.8, 1.0, 0.9),
		"particle_color_end": Color(0.3, 0.5, 0.8, 0.0),
		"particle_direction": Vector3(0, 0.5, 0),
		"particle_spread": 60.0,
		"particle_velocity_min": 0.3,
		"particle_velocity_max": 1.5,
	},
	Form.FIRE: {
		"core_color": Color(1.0, 0.85, 0.5, 1.0),
		"emission": Color(1.0, 0.5, 0.1),
		"emission_energy": 3.0,
		"light_color": Color(1.0, 0.65, 0.2),
		"light_energy": 2.5,
		"particle_color_start": Color(1.0, 0.9, 0.4, 0.9),
		"particle_color_end": Color(1.0, 0.2, 0.0, 0.0),
		"particle_direction": Vector3(0, 1, 0),
		"particle_spread": 35.0,
		"particle_velocity_min": 0.8,
		"particle_velocity_max": 2.5,
	},
	Form.HEAL: {
		"core_color": Color(0.4, 1.0, 0.7, 1.0),
		"emission": Color(0.2, 0.9, 0.5),
		"emission_energy": 1.8,
		"light_color": Color(0.3, 0.9, 0.5),
		"light_energy": 1.8,
		"particle_color_start": Color(0.3, 1.0, 0.6, 0.7),
		"particle_color_end": Color(0.1, 0.6, 0.4, 0.0),
		"particle_direction": Vector3(0, 1, 0),
		"particle_spread": 25.0,
		"particle_velocity_min": 0.2,
		"particle_velocity_max": 0.8,
	},
	Form.POWER: {
		"core_color": Color(0.8, 0.4, 1.0, 1.0),
		"emission": Color(0.7, 0.2, 1.0),
		"emission_energy": 2.8,
		"light_color": Color(0.6, 0.2, 1.0),
		"light_energy": 2.2,
		"particle_color_start": Color(1.0, 1.0, 1.0, 1.0),
		"particle_color_end": Color(0.5, 0.1, 0.8, 0.0),
		"particle_direction": Vector3(0, 0, 1),
		"particle_spread": 70.0,
		"particle_velocity_min": 2.0,
		"particle_velocity_max": 5.0,
	},
	Form.GEL: {
		"core_color": Color(0.5, 0.9, 0.8, 0.7),
		"emission": Color(0.4, 0.8, 0.7),
		"emission_energy": 1.0,
		"light_color": Color(0.4, 0.8, 0.7),
		"light_energy": 0.8,
		"particle_color_start": Color(0.4, 0.9, 0.8, 0.5),
		"particle_color_end": Color(0.3, 0.6, 0.5, 0.0),
		"particle_direction": Vector3(0, -1, 0),
		"particle_spread": 15.0,
		"particle_velocity_min": 0.1,
		"particle_velocity_max": 0.4,
	},
}

# ── Signals ────────────────────────────────────────────────────────────────
signal form_changed(new_form: Form)
signal plasma_attached(target: Node3D)
signal plasma_detached()
signal plasma_depleted()
signal plasma_respawned()

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_home_position = global_position

	# Area3D setup
	monitoring = true
	monitorable = true
	collision_layer = 0
	# Player (layer 2) + Pickable (layer 3) + Held-object (layer 17, XRToolsPickable when grabbed)
	collision_mask = 2 | 4 | 0b0000_0000_0000_0001_0000_0000_0000_0000

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)

	# Build visuals
	_build_visuals()
	_setup_collision()

	# Apply starting form
	set_form(starting_form)

	add_to_group("plasma")
	add_to_group("critter")
	print("[PlasmaCritter] Ready at %s — form: %s" % [global_position, Form.keys()[current_form]])

func _process(delta: float) -> void:
	_damage_timer = max(0.0, _damage_timer - delta)
	_pulse_time += delta

	if _is_depleted:
		_process_depleted(delta)
		return

	# Pulse animation
	_animate_pulse(delta)

	# Fuel consumption when in a non-RAW form
	if current_form != Form.RAW and _attached_to != null:
		_fuel -= delta
		_update_fuel_visuals()

		if _fuel <= 0.0:
			_deplete()

	# Heal form: heal nearby player
	if current_form == Form.HEAL and _attached_to != null:
		_process_heal(delta)

# ═══════════════════════════════════════════════════════════════════════════
# FORM SYSTEM
# ═══════════════════════════════════════════════════════════════════════════

func set_form(new_form: Form) -> void:
	current_form = new_form
	_fuel = burn_duration
	_apply_form_visuals()
	form_changed.emit(new_form)
	print("[PlasmaCritter] Form changed to: %s" % Form.keys()[new_form])

func _apply_form_visuals() -> void:
	var config: Dictionary = FORM_VISUALS.get(current_form, FORM_VISUALS[Form.RAW])

	# Core material
	if _core_mesh:
		var mat: StandardMaterial3D = _core_mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = config.core_color
			mat.emission = config.emission
			mat.emission_energy_multiplier = config.emission_energy

	# Light
	if _light:
		_light.light_color = config.light_color
		_light.light_energy = config.light_energy
		_light.omni_range = light_range

	# Particles
	if _particles:
		_particles.emitting = true
		var pmat: ParticleProcessMaterial = _particles.process_material as ParticleProcessMaterial
		if pmat:
			pmat.direction = config.particle_direction
			pmat.spread = config.particle_spread
			pmat.initial_velocity_min = config.particle_velocity_min
			pmat.initial_velocity_max = config.particle_velocity_max

			# Color gradient
			var gradient := Gradient.new()
			gradient.add_point(0.0, config.particle_color_start)
			gradient.add_point(1.0, config.particle_color_end)
			var gradient_tex := GradientTexture1D.new()
			gradient_tex.gradient = gradient
			pmat.color_ramp = gradient_tex

# ═══════════════════════════════════════════════════════════════════════════
# ATTACHMENT
# ═══════════════════════════════════════════════════════════════════════════

func attach_to(target: Node3D) -> void:
	if _attached_to != null:
		return  # Already attached

	_attached_to = target

	# Find tip marker on target
	var tip: Node3D = target.find_child("Tip", false, false)
	if not tip:
		tip = target

	# Reparent visual root to target tip
	if _visual_root:
		var world_pos: Vector3 = _visual_root.global_position
		_visual_root.reparent(tip)
		_visual_root.position = Vector3.ZERO

	# Disable collision (no longer damages while attached as tool)
	if _collision:
		_collision.disabled = true

	_fuel = burn_duration
	plasma_attached.emit(target)
	print("[PlasmaCritter] Attached to: %s" % target.name)

func detach() -> void:
	if _attached_to == null:
		return

	var old_target: Node3D = _attached_to
	_attached_to = null

	# Reparent visual root back to self
	if _visual_root and is_instance_valid(_visual_root):
		_visual_root.reparent(self)
		_visual_root.position = Vector3.ZERO

	# Re-enable collision
	if _collision:
		_collision.disabled = false

	plasma_detached.emit()
	print("[PlasmaCritter] Detached from: %s" % old_target.name)

# ═══════════════════════════════════════════════════════════════════════════
# FUEL / DEPLETION
# ═══════════════════════════════════════════════════════════════════════════

func _update_fuel_visuals() -> void:
	var fuel_ratio: float = clamp(_fuel / max(burn_duration, 0.01), 0.0, 1.0)

	# Dim light as fuel depletes
	if _light:
		var config: Dictionary = FORM_VISUALS.get(current_form, FORM_VISUALS[Form.RAW])
		_light.light_energy = config.light_energy * fuel_ratio
		_light.omni_range = light_range * (0.3 + 0.7 * fuel_ratio)

	# Reduce particles
	if _particles:
		_particles.amount = max(5, int(particle_count * fuel_ratio))

	# Shrink core slightly
	if _core_mesh:
		var s: float = 0.5 + 0.5 * fuel_ratio
		_core_mesh.scale = Vector3(s, s, s)

func _deplete() -> void:
	_is_depleted = true
	_respawn_timer = respawn_delay

	# Detach from carrier
	detach()

	# Hide visuals
	if _visual_root:
		_visual_root.visible = false
	if _collision:
		_collision.disabled = true

	plasma_depleted.emit()
	print("[PlasmaCritter] Depleted — respawning in %.1fs" % respawn_delay)

func _process_depleted(delta: float) -> void:
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_respawn()

func _respawn() -> void:
	_is_depleted = false
	global_position = _home_position

	# Reset to RAW form
	set_form(Form.RAW)

	# Show visuals
	if _visual_root:
		_visual_root.visible = true
		_visual_root.reparent(self)
		_visual_root.position = Vector3.ZERO
	if _collision:
		_collision.disabled = false

	plasma_respawned.emit()
	print("[PlasmaCritter] Respawned at home position")

# ═══════════════════════════════════════════════════════════════════════════
# COLLISION HANDLING
# ═══════════════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node3D) -> void:
	if _is_depleted:
		return
	if _attached_to != null:
		return  # Don't interact while attached to something

	# Check if it's a stick / tool
	if _is_stick(body):
		_handle_stick_contact(body)
		return

	# Check if it's the player
	if _is_player(body):
		_handle_player_contact(body)
		return

func _on_body_exited(_body: Node3D) -> void:
	pass

func _on_area_entered(area: Area3D) -> void:
	if _is_depleted or _attached_to != null:
		return
	# Check if the area belongs to a stick tool
	var parent: Node = area.get_parent()
	if parent and _is_stick(parent):
		_handle_stick_contact(parent)

func _handle_player_contact(player: Node3D) -> void:
	if _damage_timer > 0.0:
		return
	if not contact_damage_enabled:
		return

	var damage_amount: float = raw_damage
	match current_form:
		Form.RAW:
			damage_amount = raw_damage
		Form.FIRE:
			damage_amount = fire_damage
		Form.HEAL:
			# Heal form doesn't damage
			return
		_:
			damage_amount = raw_damage

	# Apply damage via GameManager
	var game_manager: Node = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if game_manager == null:
		game_manager = player.get_node_or_null("/root/GameManager")

	if game_manager and game_manager.has_method("apply_health_damage"):
		game_manager.apply_health_damage(damage_amount)
	elif player.has_method("take_damage"):
		player.take_damage(damage_amount)
	elif player.has_method("apply_health_damage"):
		player.apply_health_damage(damage_amount)

	_damage_timer = damage_cooldown
	print("[PlasmaCritter] Damaged player: %.1f (%s form)" % [damage_amount, Form.keys()[current_form]])

func _handle_stick_contact(stick: Node3D) -> void:
	# Stick contact → become fire form and attach
	if current_form == Form.RAW:
		set_form(Form.FIRE)

	# Tell the stick it received plasma
	if stick.has_method("receive_plasma"):
		stick.receive_plasma(self)

	attach_to(stick)

# ═══════════════════════════════════════════════════════════════════════════
# HEAL FORM PROCESSING
# ═══════════════════════════════════════════════════════════════════════════

func _process_heal(delta: float) -> void:
	# Find player nearby and heal
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("heal_player"):
		game_manager.heal_player(heal_per_second * delta)

# ═══════════════════════════════════════════════════════════════════════════
# DETECTION HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player") or body.is_in_group("player_body"):
		return true
	var lower_name: String = body.name.to_lower()
	return lower_name.contains("player") or lower_name.contains("xrorigin")

func _is_stick(body: Node) -> bool:
	if not (body is Node3D):
		return false
	if body.has_method("is_stick"):
		return body.is_stick()
	if body.is_in_group("stick") or body.is_in_group("tool"):
		return true
	return body.name.to_lower().contains("stick")

# ═══════════════════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════════════════

func _animate_pulse(_delta: float) -> void:
	if not _core_mesh:
		return

	var base_scale: float = 1.0
	if _attached_to != null:
		# Smaller pulse when attached, affected by fuel
		var fuel_ratio: float = clamp(_fuel / max(burn_duration, 0.01), 0.0, 1.0)
		base_scale = 0.5 + 0.5 * fuel_ratio

	var pulse: float = 0.95 + 0.1 * sin(_pulse_time * 3.0)
	var s: float = base_scale * pulse
	_core_mesh.scale = Vector3(s, s, s)

	# Slight bobbing when idle and not attached
	if _attached_to == null and _visual_root:
		_visual_root.position.y = 0.05 * sin(_pulse_time * 1.5)

# ═══════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_visuals() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "PlasmaVisual"
	add_child(_visual_root)

	# Core sphere
	_core_mesh = MeshInstance3D.new()
	_core_mesh.name = "Core"
	var sphere := SphereMesh.new()
	sphere.radius = core_radius
	sphere.height = core_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	_core_mesh.mesh = sphere

	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.7, 0.85, 1.0)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.5, 0.7, 1.0)
	core_mat.emission_energy_multiplier = 2.0
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.albedo_color.a = 0.9
	_core_mesh.material_override = core_mat
	_visual_root.add_child(_core_mesh)

	# Particles
	_particles = GPUParticles3D.new()
	_particles.name = "Wisps"
	_particles.emitting = true
	_particles.amount = particle_count
	_particles.lifetime = 2.0

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0.5, 0)
	pmat.spread = 60.0
	pmat.initial_velocity_min = 0.3
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, 0.3, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.15
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = core_radius * 0.8

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.8, 1.0, 0.9))
	gradient.add_point(1.0, Color(0.3, 0.5, 0.8, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	pmat.color_ramp = grad_tex

	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	_visual_root.add_child(_particles)

	# Light
	_light = OmniLight3D.new()
	_light.name = "PlasmaLight"
	_light.light_color = Color(0.6, 0.75, 1.0)
	_light.light_energy = 1.5
	_light.omni_range = light_range
	_light.omni_attenuation = 1.5
	_light.shadow_enabled = false
	_visual_root.add_child(_light)

func _setup_collision() -> void:
	_collision = CollisionShape3D.new()
	_collision.name = "PlasmaCollision"
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = interaction_radius
	_collision.shape = sphere_shape
	add_child(_collision)

# ═══════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("form"):
		var form_str: String = str(config_data["form"]).to_lower()
		match form_str:
			"fire": starting_form = Form.FIRE
			"heal": starting_form = Form.HEAL
			"power": starting_form = Form.POWER
			"gel": starting_form = Form.GEL
			_: starting_form = Form.RAW

	if config_data.has("damage"):
		raw_damage = _cfg_float(config_data["damage"], raw_damage)
	if config_data.has("fire_damage"):
		fire_damage = _cfg_float(config_data["fire_damage"], fire_damage)
	if config_data.has("radius"):
		interaction_radius = _cfg_float(config_data["radius"], interaction_radius)
	if config_data.has("burn_duration"):
		burn_duration = _cfg_float(config_data["burn_duration"], burn_duration)
	if config_data.has("fuel"):
		burn_duration = _cfg_float(config_data["fuel"], burn_duration)
	if config_data.has("respawn"):
		respawn_delay = _cfg_float(config_data["respawn"], respawn_delay)
	if config_data.has("light_range"):
		light_range = _cfg_float(config_data["light_range"], light_range)

func _cfg_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
