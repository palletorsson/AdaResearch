# @identity
# essence: effect(player, mediator) = hazard XOR benefit -- dual-nature zone where context determines outcome
# desire: a force field that burns or warms, poisons or reveals, depending on what the player brings
# critical_parameter: mediator_object presence -- same field produces opposite effects based on relational context
# triggers: player enters Area3D; field checks for mediator; mode determined by carried objects
# emerges: Q-FEP made spatial -- identical potential under different constraint produces opposite outcomes
# needs: Area3D [has]; mediator detection [has]; multi-mode effects [has]; VR interaction [missing]
# relationships: central Q-FEP demonstration; pairs with plasma_critter (creature vs zone dual-nature)
# truth: the force that burns also warms -- constraint determines outcome, not the force itself.

# ForceField.gd
# Dual-nature force zone: every hazard is also medicine.
# In HAZARD mode the force damages. In TRANSMUTED mode it benefits.
# The player's relational context determines which mode is active.
#
# Q-FEP: same potential, different restraint, different manifestation.
# Fire warms or burns. Poison kills or reveals. Electricity shocks or powers.
#
# Transmutation occurs when the player introduces a mediator object (VR grab)
# into the force field, or endures the hazard long enough (courage path).
extends Area3D
class_name ForceField

# ── Enums ─────────────────────────────────────────────────────────────────
enum ForceMode { HAZARD, TRANSMUTING, TRANSMUTED }
enum ForceType {
	FIRE,
	VACUUM,
	ELECTRIC,
	TOXIC,
	RADIATION,
	FREEZING,
	ACID,
	MAGNETIC,
	GRAVITY,
	ENTROPY,
	RESONANCE,
	VOID,
}

# ── Configuration ─────────────────────────────────────────────────────────
@export_group("Force")
@export var force_type: ForceType = ForceType.FIRE
@export var force_intensity: float = 1.0  ## Multiplier for damage/benefit
@export var zone_radius: float = 1.5
@export var zone_height: float = 2.5

@export_group("Transmutation")
@export var transmutation_enabled: bool = true
@export var transmutation_threshold: float = -1.0  ## -1 = use config default
@export var courage_enabled: bool = true  ## Allow transmutation by endurance
@export var revert_after: float = 0.0  ## 0 = stays transmuted permanently

@export_group("Visual")
@export var show_label: bool = true
@export var show_particles: bool = true

# ── State ─────────────────────────────────────────────────────────────────
var current_mode: ForceMode = ForceMode.HAZARD
var _transmutation_progress: float = 0.0  ## 0.0 → 1.0
var _exposure_time: float = 0.0
var _damage_timer: float = 0.0
var _player_inside: bool = false
var _mediator_present: bool = false
var _mediator_node: Node3D = null
var _revert_timer: float = 0.0
var _pulse_time: float = 0.0

# ── Cached configs ────────────────────────────────────────────────────────
var _hazard_cfg: Dictionary = {}
var _transmuted_cfg: Dictionary = {}
var _conditions: Dictionary = {}

# ── Visual controller ────────────────────────────────────────────────────
var _visuals: ForceVisualController = ForceVisualController.new()

# ── Collision ────────────────────────────────────────────────────────────
var _collision_shape: CollisionShape3D

# ── Signals ───────────────────────────────────────────────────────────────
signal mode_changed(new_mode: ForceMode)
signal transmutation_started()
signal transmutation_complete()
signal transmutation_reverted()
signal player_entered_force(force_type_id: int)
signal player_exited_force(force_type_id: int)
signal damage_dealt(amount: float)


# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Load config from transmutation registry
	var type_int: int = force_type as int
	_hazard_cfg = ForceTransmutationConfig.get_hazard_config(type_int)
	_transmuted_cfg = ForceTransmutationConfig.get_transmuted_config(type_int)
	_conditions = ForceTransmutationConfig.get_conditions(type_int)

	# Override threshold if not set
	if transmutation_threshold < 0.0:
		transmutation_threshold = _conditions.get("exposure_threshold", 3.0)

	# Area3D setup (same pattern as PlasmaCritter + DangerZone)
	monitoring = true
	monitorable = true
	collision_layer = 0
	# Player body (layer 20 = bit 19), Pickable (layer 3 = bit 2), XR held (layer 17 = bit 16)
	collision_mask = (1 << 19) | (1 << 2) | (1 << 16)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	# Build collision
	_setup_collision()

	# Build visuals
	_visuals.build(self, zone_radius, zone_height)
	_apply_mode_visuals()

	# Groups
	add_to_group("force_field")
	add_to_group("hazard")

	var force_name: String = ForceTransmutationConfig.get_force_name(type_int)
	print("[ForceField] Ready: %s at %s (intensity=%.1f)" % [force_name, global_position, force_intensity])


func _process(delta: float) -> void:
	_pulse_time += delta

	match current_mode:
		ForceMode.HAZARD:
			_process_hazard(delta)
		ForceMode.TRANSMUTING:
			_process_transmuting(delta)
		ForceMode.TRANSMUTED:
			_process_transmuted(delta)


# ═══════════════════════════════════════════════════════════════════════════
# MODE PROCESSING
# ═══════════════════════════════════════════════════════════════════════════

func _process_hazard(delta: float) -> void:
	if not _player_inside:
		# Decay exposure when player is outside
		_exposure_time = maxf(0.0, _exposure_time - delta * 0.5)
		return

	_exposure_time += delta

	# Deal damage on tick
	var tick: float = _hazard_cfg.get("tick_interval", 0.5)
	_damage_timer += delta
	if _damage_timer >= tick:
		_damage_timer = 0.0
		var dmg: float = _hazard_cfg.get("damage_per_tick", 10.0) * force_intensity
		_deal_damage(dmg)

	# Check if mediator triggers transmutation
	if transmutation_enabled and _mediator_present:
		_begin_transmutation()

	# Check courage path
	if transmutation_enabled and courage_enabled and not _mediator_present:
		var courage_threshold: float = _conditions.get("courage_threshold", -1.0)
		if courage_threshold > 0.0 and _exposure_time >= courage_threshold:
			_begin_transmutation()


func _process_transmuting(delta: float) -> void:
	if not _player_inside and not _mediator_present:
		# Player left and no mediator — revert
		_transmutation_progress = maxf(0.0, _transmutation_progress - delta * 0.3)
		if _transmutation_progress <= 0.0:
			_set_mode(ForceMode.HAZARD)
		else:
			_visuals.apply_transmuting_blend(_hazard_cfg, _transmuted_cfg, _transmutation_progress)
		return

	# Progress transmutation
	var threshold: float = transmutation_threshold
	_transmutation_progress += delta / maxf(threshold, 0.1)
	_transmutation_progress = clampf(_transmutation_progress, 0.0, 1.0)

	# Update visuals
	_visuals.apply_transmuting_blend(_hazard_cfg, _transmuted_cfg, _transmutation_progress)

	# Reduced damage during transmutation (fading out)
	var tick: float = _hazard_cfg.get("tick_interval", 0.5)
	_damage_timer += delta
	if _damage_timer >= tick:
		_damage_timer = 0.0
		var base_dmg: float = _hazard_cfg.get("damage_per_tick", 10.0) * force_intensity
		var reduced_dmg: float = base_dmg * (1.0 - _transmutation_progress * 0.8)
		if reduced_dmg > 0.5:
			_deal_damage(reduced_dmg)

	# Complete transmutation
	if _transmutation_progress >= 1.0:
		_complete_transmutation()


func _process_transmuted(delta: float) -> void:
	# Apply benefits
	if _player_inside:
		var heal: float = _transmuted_cfg.get("heal_per_second", 0.0) * force_intensity
		if heal > 0.0:
			_heal_player(heal * delta)

	# Revert timer (if configured)
	if revert_after > 0.0:
		_revert_timer += delta
		if _revert_timer >= revert_after:
			_revert_to_hazard()


# ═══════════════════════════════════════════════════════════════════════════
# TRANSMUTATION FLOW
# ═══════════════════════════════════════════════════════════════════════════

func _begin_transmutation() -> void:
	if current_mode == ForceMode.TRANSMUTING:
		return  # Already in progress
	if current_mode == ForceMode.TRANSMUTED:
		return  # Already done

	_set_mode(ForceMode.TRANSMUTING)
	_transmutation_progress = 0.0
	transmutation_started.emit()
	print("[ForceField] Transmutation started (%s)" % ForceTransmutationConfig.get_force_name(force_type as int))


func _complete_transmutation() -> void:
	_set_mode(ForceMode.TRANSMUTED)
	_revert_timer = 0.0
	transmutation_complete.emit()

	# Show pedagogical hint via subtitle system
	var hint: String = ForceTransmutationConfig.get_pedagogical_hint(force_type as int)
	if not hint.is_empty():
		_show_subtitle(hint)

	var force_name: String = ForceTransmutationConfig.get_force_name(force_type as int)
	print("[ForceField] Transmutation complete! %s → %s" % [force_name, _transmuted_cfg.get("description", "BENEFIT")])


func _revert_to_hazard() -> void:
	_set_mode(ForceMode.HAZARD)
	_transmutation_progress = 0.0
	_exposure_time = 0.0
	transmutation_reverted.emit()
	print("[ForceField] Reverted to hazard mode")


func _set_mode(new_mode: ForceMode) -> void:
	current_mode = new_mode
	_apply_mode_visuals()
	mode_changed.emit(new_mode)


func _apply_mode_visuals() -> void:
	match current_mode:
		ForceMode.HAZARD:
			_visuals.apply_hazard_visuals(_hazard_cfg)
		ForceMode.TRANSMUTED:
			_visuals.apply_transmuted_visuals(_transmuted_cfg)
		ForceMode.TRANSMUTING:
			_visuals.apply_transmuting_blend(_hazard_cfg, _transmuted_cfg, _transmutation_progress)


# ═══════════════════════════════════════════════════════════════════════════
# COLLISION HANDLING
# ═══════════════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node3D) -> void:
	if _is_player(body):
		_player_inside = true
		player_entered_force.emit(force_type as int)
	elif _is_mediator(body):
		_mediator_present = true
		_mediator_node = body


func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		_player_inside = false
		player_exited_force.emit(force_type as int)
	elif body == _mediator_node:
		_mediator_present = false
		_mediator_node = null


func _on_area_entered(area: Area3D) -> void:
	# Check if the area's parent is a mediator (XRToolsPickable uses areas)
	var parent: Node = area.get_parent()
	if parent is Node3D and _is_mediator(parent):
		_mediator_present = true
		_mediator_node = parent as Node3D


func _on_area_exited(area: Area3D) -> void:
	var parent: Node = area.get_parent()
	if parent is Node3D and parent == _mediator_node:
		_mediator_present = false
		_mediator_node = null


# ═══════════════════════════════════════════════════════════════════════════
# DETECTION HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player") or body.is_in_group("player_body"):
		return true
	var lower_name: String = body.name.to_lower()
	return lower_name.contains("player") or lower_name.contains("xrorigin")


func _is_mediator(node: Node3D) -> bool:
	if not transmutation_enabled:
		return false
	var required_groups: Array = _conditions.get("mediator_groups", [])
	for group_name in required_groups:
		var g: String = str(group_name)
		if node.is_in_group(g):
			return true
	# Also check parent groups (for nested pickable scenes)
	var parent: Node = node.get_parent()
	if parent is Node3D:
		for group_name in required_groups:
			var g: String = str(group_name)
			if parent.is_in_group(g):
				return true
	return false


# ═══════════════════════════════════════════════════════════════════════════
# GAME INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

func _deal_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("apply_health_damage"):
		game_manager.apply_health_damage(amount)
	damage_dealt.emit(amount)


func _heal_player(amount: float) -> void:
	if amount <= 0.0:
		return
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("heal_player"):
		game_manager.heal_player(amount)


func _show_subtitle(text: String) -> void:
	# Try the subtitle system if available
	var game_manager: Node = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("show_subtitle"):
		game_manager.show_subtitle(text, 6.0)
	else:
		# Fallback: just print
		print("[ForceField] SUBTITLE: %s" % text)


# ═══════════════════════════════════════════════════════════════════════════
# COLLISION SETUP
# ═══════════════════════════════════════════════════════════════════════════

func _setup_collision() -> void:
	# Check if a collision shape already exists (from .tscn or parent)
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape:
		return

	# Create default cylinder collision
	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "CollisionShape3D"
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = zone_radius
	shape.height = zone_height
	_collision_shape.shape = shape
	_collision_shape.position.y = zone_height * 0.5
	add_child(_collision_shape)


# ═══════════════════════════════════════════════════════════════════════════
# GRID / UTILITY INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

## Called by GridUtilitiesComponent or GridInteractablesComponent
func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)


func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	if config_data.has("force_type"):
		var type_val: Variant = config_data["force_type"]
		if type_val is int:
			force_type = type_val as ForceType
		elif type_val is String:
			force_type = ForceTransmutationConfig.parse_force_type(str(type_val)) as ForceType

	if config_data.has("intensity"):
		force_intensity = _cfg_float(config_data["intensity"], force_intensity)
	if config_data.has("force_intensity"):
		force_intensity = _cfg_float(config_data["force_intensity"], force_intensity)
	if config_data.has("radius"):
		zone_radius = _cfg_float(config_data["radius"], zone_radius)
	if config_data.has("height"):
		zone_height = _cfg_float(config_data["height"], zone_height)
	if config_data.has("transmutation_enabled"):
		transmutation_enabled = bool(config_data["transmutation_enabled"])
	if config_data.has("revert_after"):
		revert_after = _cfg_float(config_data["revert_after"], revert_after)


## Static factory for utility notation: f:fire:20
static func create_from_notation(notation: String) -> ForceField:
	var parts: PackedStringArray = notation.split(":")
	if parts.size() < 2:
		return null

	var field: ForceField = ForceField.new()
	var type_str: String = parts[1].strip_edges().to_lower()
	field.force_type = ForceTransmutationConfig.parse_force_type(type_str) as ForceType

	if parts.size() >= 3 and parts[2].is_valid_float():
		field.force_intensity = float(parts[2])

	return field


func _cfg_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
