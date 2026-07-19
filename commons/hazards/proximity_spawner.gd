extends Node3D

# @identity
# essence: monitors distance from player each physics frame; spawns enemy_type when player enters spawn_radius, despawns when past despawn_radius, and waits respawn_delay seconds before trying again
# desire: to make the world feel inhabited — the learner never knows exactly when a creature will appear, so proximity itself becomes a kind of alertness
# critical_parameter: spawn_radius vs despawn_radius (15m vs 30m) — the asymmetry creates a hysteresis zone where the creature stays alive even as the player backs away; avoids the flickering of a symmetric threshold
# triggers: _physics_process polls distance every frame; _deferred_init finds the player node after scene load; _spawn_enemy() instantiates from ENEMY_SCENES dictionary by type name
# emerges: respawn_delay creates rhythm — after a creature dies, there is a 2-second silence before the next appears; that gap is where the learner exhales
# needs: VR visual feedback on spawn [missing — no sound, no flash]; enemy_type selector in VR [missing]; apply_grid_config [missing]
# relationships: used in LSystems_Competition and LSystems_Living to place folding hazard creatures; works with miura_crawler, kresling_spire, scissor_stalker, and origami_droideka; relies on GameManager to find player node
# truth: presence is not a property of the creature — it is a function of distance; the spawner makes explicit what is always true: things only exist for you within a radius

class_name ProximitySpawner
## Spawns enemies when player enters radius, respawns after death.

@export var enemy_type: String = "miura_crawler"
@export var spawn_radius: float = 15.0
@export var despawn_radius: float = 30.0
@export var respawn_delay: float = 2.0
@export var spawn_offset: Vector3 = Vector3(0, 0.5, 0)

var _current_enemy: Node3D = null
var _respawn_timer: float = 0.0
var _player_node: Node3D = null
var _spawn_attempted: bool = false

const ENEMY_SCENES: Dictionary = {
	"miura_crawler": "res://commons/hazards/miura_crawler/miura_crawler.tscn",
	"kresling_spire": "res://commons/hazards/kresling_spire/kresling_spire.tscn",
	"scissor_stalker": "res://commons/hazards/scissor_stalker/scissor_stalker.tscn",
	"kaleidocycle_enemy": "res://commons/hazards/kaleidocycle/kaleidocycle_enemy.tscn",
	"origami_droideka": "res://commons/hazards/armadillo_droideka/origami_droideka.tscn",
	"armadillo_droideka": "res://commons/hazards/armadillo_droideka/armadillo_droideka.tscn",
	"goomba_box": "res://commons/hazards/goomba_box/goomba_box.tscn",
	"shell_roller": "res://commons/hazards/shell_roller/shell_roller.tscn",
	"spring_hopper": "res://commons/hazards/spring_hopper/spring_hopper.tscn",
	# The pink critter's octapod stage — scene existed and Chamber_Random
	# already asked for it by name; the registration was the missing meeting.
	"octapod_crawler": "res://commons/hazards/octapod_crawler/octapod_crawler.tscn",
}


func _ready() -> void:
	print("ProximitySpawner: READY at %s, type='%s', spawn_radius=%s" % [global_position, enemy_type, spawn_radius])
	# Delay player search to ensure scene is fully loaded
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_find_player()
	if _player_node:
		print("ProximitySpawner: Found player: %s" % _player_node.name)
	else:
		print("ProximitySpawner: WARNING - No player found yet, will keep searching")


func _physics_process(delta: float) -> void:
	# Keep trying to find player if not found
	if not is_instance_valid(_player_node):
		_find_player()
		if not is_instance_valid(_player_node):
			return
	
	var dist: float = global_position.distance_to(_player_node.global_position)
	
	# Check if current enemy is dead/gone
	if is_instance_valid(_current_enemy):
		# Despawn if player too far
		if dist > despawn_radius:
			print("ProximitySpawner: Player too far (%s), despawning %s" % [dist, enemy_type])
			_current_enemy.queue_free()
			_current_enemy = null
	else:
		# Respawn timer
		if _respawn_timer > 0.0:
			_respawn_timer -= delta
		elif dist <= spawn_radius:
			if not _spawn_attempted:
				print("ProximitySpawner: Player in range (%s <= %s), spawning %s" % [dist, spawn_radius, enemy_type])
			_spawn_enemy()


func _spawn_enemy() -> void:
	_spawn_attempted = true
	
	if not ENEMY_SCENES.has(enemy_type):
		push_error("ProximitySpawner: Unknown enemy type '%s'. Available: %s" % [enemy_type, ENEMY_SCENES.keys()])
		return
	
	var scene_path: String = ENEMY_SCENES[enemy_type]
	
	if not ResourceLoader.exists(scene_path):
		push_error("ProximitySpawner: Scene not found at '%s'" % scene_path)
		return
	
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_error("ProximitySpawner: Failed to load scene '%s'" % scene_path)
		return
	
	_current_enemy = scene.instantiate()
	if not _current_enemy:
		push_error("ProximitySpawner: Failed to instantiate '%s'" % scene_path)
		return
	
	_current_enemy.global_position = global_position + spawn_offset

	# Pass personality from HazardManager
	var hm = get_node_or_null("/root/HazardManager")
	if hm and _current_enemy.has_method("set_personality"):
		var personality: String = hm.get_hazard_personality(enemy_type)
		_current_enemy.set_personality(personality)

	# Connect to death signal if available
	if _current_enemy.has_signal("enemy_destroyed"):
		_current_enemy.connect("enemy_destroyed", _on_enemy_destroyed)

	# Add to scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(_current_enemy)
	else:
		get_parent().add_child(_current_enemy)

	var p_label: String = ""
	if hm:
		p_label = " [%s]" % hm.get_hazard_personality(enemy_type)
	print("ProximitySpawner: Spawned %s%s at %s" % [enemy_type, p_label, _current_enemy.global_position])


func _on_enemy_destroyed(_enemy: Node3D) -> void:
	print("ProximitySpawner: Enemy %s destroyed, will respawn in %ss" % [enemy_type, respawn_delay])
	_current_enemy = null
	_respawn_timer = respawn_delay
	_spawn_attempted = false


func _find_player() -> void:
	# Method 1: Check player group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players:
			if p is Node3D:
				_player_node = p
				return
	
	# Method 2: Find XROrigin3D (VR player)
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin and xr_origin is Node3D:
		_player_node = xr_origin
		return
	
	# Method 3: Search scene tree
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	
	# Try common player node names
	for node_name in ["XROrigin3D", "Player", "PlayerController", "CharacterBody3D"]:
		var found = scene.find_child(node_name, true, false)
		if found and found is Node3D:
			_player_node = found
			return
	
	# Method 4: Find any CharacterBody3D that might be the player
	var bodies = scene.find_children("*", "CharacterBody3D", true, false)
	for body in bodies:
		if body is Node3D and body.is_in_group("player"):
			_player_node = body
			return
	
	# Method 5: Last resort - find first CharacterBody3D
	if bodies.size() > 0 and bodies[0] is Node3D:
		_player_node = bodies[0]
		return


func configure(config: Dictionary) -> void:
	print("ProximitySpawner: configure() called with: %s" % config)
	if config.has("type"):
		enemy_type = str(config["type"])
	if config.has("spawn_radius"):
		spawn_radius = float(config["spawn_radius"])
	if config.has("despawn_radius"):
		despawn_radius = float(config["despawn_radius"])
	if config.has("respawn_delay"):
		respawn_delay = float(config["respawn_delay"])
	print("ProximitySpawner: Configured - type=%s, spawn_radius=%s" % [enemy_type, spawn_radius])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
