# DangerZone.gd
# Hazard volume that damages players on contact
# Supports multiple danger types with unique visuals/audio

extends Area3D
class_name DangerZone

enum Type { 
	FIRE,       # Burning - damage ramps with heat
	VACUUM,     # Suffocation - oxygen depletion
	ELECTRIC,   # Shock pulses - periodic bursts
	TOXIC,      # Poison - lingers after exit
	RADIATION,  # Invisible - Geiger warning
	GENERIC     # Basic damage
}

@export var danger_type: Type = Type.GENERIC
@export var damage_per_tick: float = 10.0
@export var tick_interval: float = 0.5
@export var instant_kill: bool = false  ## Dumb ways to die

# Type-specific configuration
const TYPE_CONFIG = {
	Type.FIRE: {
		"color": Color(1.0, 0.4, 0.0, 0.4),
		"emission_color": Color(1.0, 0.3, 0.0),
		"description": "Fire hazard"
	},
	Type.VACUUM: {
		"color": Color(0.1, 0.1, 0.3, 0.3),
		"emission_color": Color(0.2, 0.2, 0.5),
		"description": "Vacuum hazard"
	},
	Type.ELECTRIC: {
		"color": Color(0.0, 0.8, 1.0, 0.4),
		"emission_color": Color(0.3, 0.9, 1.0),
		"description": "Electric hazard"
	},
	Type.TOXIC: {
		"color": Color(0.2, 0.8, 0.2, 0.4),
		"emission_color": Color(0.3, 1.0, 0.3),
		"description": "Toxic hazard"
	},
	Type.RADIATION: {
		"color": Color(1.0, 1.0, 0.0, 0.2),
		"emission_color": Color(1.0, 1.0, 0.3),
		"description": "Radiation hazard"
	},
	Type.GENERIC: {
		"color": Color(0.8, 0.0, 0.0, 0.4),
		"emission_color": Color(1.0, 0.2, 0.2),
		"description": "Danger zone"
	}
}

var player_inside: bool = false
var damage_timer: float = 0.0
var config: Dictionary

# Type-specific state
var heat_level: float = 0.0  # Fire
var oxygen_level: float = 100.0  # Vacuum
var pulse_timer: float = 0.0  # Electric

# Visual nodes (created dynamically)
var zone_mesh: MeshInstance3D
var warning_label: Label3D
var ambient_audio: AudioStreamPlayer3D

signal player_entered_danger(danger_type: Type)
signal player_exited_danger(danger_type: Type)
signal damage_dealt(amount: float, danger_type: Type)

func _ready() -> void:
	print("[DangerZone] _ready() called - type: %s, position: %s" % [Type.keys()[danger_type], global_position])
	config = TYPE_CONFIG.get(danger_type, TYPE_CONFIG[Type.GENERIC])
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_setup_collision()
	_setup_visuals()
	_setup_audio()
	print("[DangerZone] Setup complete")

func _setup_collision() -> void:
	# Ensure we have monitoring enabled - match subtitle_trigger settings
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 524288  # Layer 20 - player body (same as subtitle_trigger)

func _setup_visuals() -> void:
	# Create mesh visualization if we have a collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		return
	
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "ZoneMesh"
	
	var shape = collision_shape.shape
	if shape is BoxShape3D:
		var box_mesh = BoxMesh.new()
		box_mesh.size = shape.size
		zone_mesh.mesh = box_mesh
	elif shape is SphereShape3D:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = shape.radius
		sphere_mesh.height = shape.radius * 2
		zone_mesh.mesh = sphere_mesh
	elif shape is CylinderShape3D:
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = shape.radius
		cyl_mesh.bottom_radius = shape.radius
		cyl_mesh.height = shape.height
		zone_mesh.mesh = cyl_mesh
	
	if zone_mesh.mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = config.color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = config.emission_color
		mat.emission_energy_multiplier = 0.3
		zone_mesh.set_surface_override_material(0, mat)
		zone_mesh.position = collision_shape.position
		add_child(zone_mesh)
	
	# Warning label
	warning_label = Label3D.new()
	warning_label.name = "WarningLabel"
	warning_label.text = "⚠ " + config.description.to_upper()
	warning_label.font_size = 48
	warning_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	warning_label.no_depth_test = true
	warning_label.modulate = config.emission_color
	warning_label.position.y = 1.5
	add_child(warning_label)

func _setup_audio() -> void:
	ambient_audio = AudioStreamPlayer3D.new()
	ambient_audio.name = "AmbientAudio"
	ambient_audio.max_distance = 15.0
	ambient_audio.unit_size = 3.0
	add_child(ambient_audio)
	# TODO: Load type-specific ambient sounds

func _process(delta: float) -> void:
	if not player_inside:
		# Decay type-specific states
		heat_level = max(0.0, heat_level - delta)
		oxygen_level = min(100.0, oxygen_level + delta * 20.0)
		return
	
	# Type-specific processing
	match danger_type:
		Type.FIRE:
			_process_fire(delta)
		Type.VACUUM:
			_process_vacuum(delta)
		Type.ELECTRIC:
			_process_electric(delta)
		Type.TOXIC:
			_process_toxic(delta)
		Type.RADIATION:
			_process_radiation(delta)
		Type.GENERIC:
			_process_generic(delta)

func _process_generic(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick)

func _process_fire(delta: float) -> void:
	# Heat accumulates, damage increases
	heat_level = min(heat_level + delta * 0.5, 3.0)
	
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		var heat_multiplier = 1.0 + heat_level
		_deal_damage(damage_per_tick * heat_multiplier)

func _process_vacuum(delta: float) -> void:
	# Oxygen depletes, damage starts when low
	oxygen_level = max(0.0, oxygen_level - delta * 15.0)
	
	if oxygen_level < 50.0:
		damage_timer += delta
		if damage_timer >= tick_interval:
			damage_timer = 0.0
			var severity = 1.0 - (oxygen_level / 50.0)
			_deal_damage(damage_per_tick * severity)

func _process_electric(delta: float) -> void:
	# Periodic shock pulses
	pulse_timer += delta
	if pulse_timer >= 1.5:  # Shock every 1.5 seconds
		pulse_timer = 0.0
		_deal_damage(damage_per_tick * 2.0)
		_flash_screen(Color.CYAN)

func _process_toxic(delta: float) -> void:
	# Standard tick damage, poison effect handled separately
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick * 0.7)
		# TODO: Apply poison status effect

func _process_radiation(delta: float) -> void:
	# Slow constant damage, Geiger clicks
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick * 0.5)
		# TODO: Geiger click sound

func _on_body_entered(body: Node3D) -> void:
	if not _is_player(body):
		return
	
	print("[DangerZone] Player entered! Type: %s" % Type.keys()[danger_type])
	player_inside = true
	damage_timer = 0.0
	player_entered_danger.emit(danger_type)
	
	if instant_kill:
		_instant_kill()
	else:
		# Immediate first tick
		_deal_damage(damage_per_tick * 0.5)

func _on_body_exited(body: Node3D) -> void:
	if not _is_player(body):
		return
	
	print("[DangerZone] Player exited")
	player_inside = false
	player_exited_danger.emit(danger_type)

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player"):
		return true
	if body.is_in_group("player_body"):
		return true
	if body.name.contains("Player") or body.name.contains("XR"):
		return true
	return false

func _deal_damage(amount: float) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("apply_health_damage"):
		game_manager.apply_health_damage(amount)
	
	_play_pain_sound()
	damage_dealt.emit(amount, danger_type)

func _instant_kill() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_health"):
		game_manager.set_health(0.0)

func _flash_screen(_color: Color) -> void:
	# TODO: Add screen flash effect
	pass

func _play_pain_sound() -> void:
	# TODO: Play pain sound from pool based on danger_type
	pass

# ============================================================================
# UTILITY SPAWNER INTEGRATION
# ============================================================================

static func create_from_notation(notation: String) -> DangerZone:
	"""Create DangerZone from utility notation like h:fire:20"""
	var parts = notation.split(":")
	if parts.size() < 2:
		return null
	
	var zone = DangerZone.new()
	var type_str = parts[1].to_lower()
	
	match type_str:
		"fire": zone.danger_type = Type.FIRE
		"vacuum": zone.danger_type = Type.VACUUM
		"electric": zone.danger_type = Type.ELECTRIC
		"toxic": zone.danger_type = Type.TOXIC
		"radiation": zone.danger_type = Type.RADIATION
		"death": zone.instant_kill = true
		_: zone.danger_type = Type.GENERIC
	
	if parts.size() >= 3:
		zone.damage_per_tick = float(parts[2])
	
	# Add default collision shape (1x1x1 cube)
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(1, 2, 1)
	zone.add_child(collision)
	
	return zone
