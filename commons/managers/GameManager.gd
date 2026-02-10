# GameManager.gd
# Updated singleton for score management
# Add this script as an AutoLoad/Singleton in Project Settings

extends Node

const DEATH_CROSS_SCENE: PackedScene = preload("res://commons/primitives/plus/plus.tscn")

# Game Modes
enum GameMode {
	STORY,      # Full sequence playthrough (default)
	TEST,       # Skip to last map of each sequence, then lab
	EXPLORER    # Full lab unlocked, all paths available
}

@export var game_mode: GameMode = GameMode.STORY # Default to TEST for quick iteration

signal game_mode_changed(new_mode: GameMode)

# Game state
var player_score: int = 0
var current_message: String = ""
var game_started: bool = false
var game_paused: bool = false

var max_player_health: float = 100.0
var player_health: float = 100.0

@export var death_sequence_enabled: bool = true
@export var death_sequence_duration: float = 3.0
@export var death_orbit_radius: float = 4.0
@export var death_orbit_height: float = 2.2
@export var death_orbit_speed: float = 1.6
@export var death_start_radius: float = 0.8
@export var death_start_height: float = 1.1
@export var death_cross_scale: Vector3 = Vector3(0.7, 1.5, 0.2)
@export var death_cross_color: Color = Color(0.92, 0.92, 0.92, 1.0)
@export var death_cross_y_offset: float = 0.05
var _death_sequence_running: bool = false

# Map tracking
var current_map_name: String = ""

# Player tracking
var current_player: Node3D = null
signal player_registered(player: Node3D)


# Game settings
var sound_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 0.7
var show_infoboard: bool = true  

# Player customization
var nail_color: Color = Color(1.0, 0.5, 0.7, 1.0)  # Default pink
var hand_color: Color = Color(0.8, 0.6, 0.5, 1.0)  # Default skin tone

@export var debug = true
# Signals
signal score_updated(new_score: int)
signal pickup_collected(pickup_position: Vector3)
signal message_updated(message: String)
signal game_state_changed(is_started: bool, is_paused: bool)
signal regenerate_requested(origin: Vector3, targets: Array, metadata: Dictionary)
signal health_updated(new_health: float)
signal player_damaged(amount: float, new_health: float)
signal player_died(position: Vector3)
signal current_map_changed(map_name: String)
signal nail_color_changed(new_color: Color)
signal hand_color_changed(new_color: Color)
signal settings_changed(setting_name: String, value: Variant) # New signal

var console_messages: Array[Dictionary] = []
var max_console_messages: int = 100

# Color Manager (migrated from GridColorizer)
var gradient_palettes: Dictionary = {
	"rainbow_gradient": [
		Color(1.0, 0.0, 0.8),   # Magenta
		Color(1.0, 0.2, 0.4),   # Hot pink
		Color(1.0, 0.5, 0.0),   # Orange
		Color(1.0, 0.9, 0.0),   # Yellow
		Color(0.5, 1.0, 0.0),   # Lime
		Color(0.2, 0.9, 0.4),   # Green
		Color(0.0, 0.8, 0.8),   # Cyan
		Color(0.2, 0.6, 1.0),   # Blue
		Color(0.6, 0.2, 1.0)    # Purple
	],
	"sunset_gradient": [
		Color(0.1, 0.1, 0.3),   # Deep purple (night)
		Color(0.4, 0.1, 0.5),   # Purple
		Color(0.8, 0.2, 0.4),   # Magenta
		Color(1.0, 0.4, 0.2),   # Orange-red
		Color(1.0, 0.6, 0.1),   # Orange
		Color(1.0, 0.8, 0.3),   # Yellow-orange
		Color(1.0, 0.9, 0.7),   # Warm yellow
		Color(0.9, 0.9, 0.8)    # Pale yellow
	],
	"ocean_gradient": [
		Color(0.0, 0.1, 0.2),   # Deep ocean
		Color(0.0, 0.2, 0.4),   # Deep blue
		Color(0.0, 0.4, 0.6),   # Ocean blue
		Color(0.1, 0.6, 0.8),   # Bright blue
		Color(0.3, 0.8, 0.9),   # Light blue
		Color(0.5, 0.9, 0.9),   # Cyan
		Color(0.7, 0.95, 0.95), # Light cyan
		Color(0.9, 0.98, 0.98)  # Almost white
	],
	"pink_gradient": [
		Color(0.4, 0.1, 0.2),   # Deep magenta
		Color(0.6, 0.2, 0.4),   # Dark pink
		Color(0.8, 0.3, 0.5),   # Medium pink
		Color(0.9, 0.4, 0.6),   # Rose pink
		Color(1.0, 0.5, 0.7),   # Hot pink
		Color(1.0, 0.7, 0.8),   # Light pink
		Color(1.0, 0.85, 0.9),  # Very light pink
		Color(1.0, 0.95, 0.97)  # Almost white pink
	]
}

func get_gradient_palette(palette_name: String) -> Array:
	if gradient_palettes.has(palette_name):
		return gradient_palettes[palette_name]
	return [Color.WHITE] # Fallback

func get_all_gradient_names() -> Array:
	return gradient_palettes.keys()


signal console_message_added(message_data: Dictionary)
signal console_cleared()

# Called when the game starts
func _ready() -> void:
	print("GameManager: Singleton initialized - game_mode before load: %s" % get_game_mode_name())
	reset_game_state()
	
	# Load saved settings (game mode, colors, etc.)
	if FileAccess.file_exists("user://savegame.save"):
		print("GameManager: Save file exists, loading...")
		load_game()
		print("GameManager: After load - game_mode: %s (is_test=%s)" % [get_game_mode_name(), is_test_mode()])
	
	add_test_console_messages()
# Reset the game state
func reset_game_state() -> void:
	player_score = 0
	current_message = ""
	game_started = false
	game_paused = false
	reset_level_state()
	emit_signal("game_state_changed", game_started, game_paused)
	emit_signal("score_updated", player_score)

func reset_level_state() -> void:
	player_health = max_player_health
	_death_sequence_running = false
	emit_signal("health_updated", player_health)

func _reload_scene() -> void:
	var tree = get_tree()
	if tree:
		tree.reload_current_scene()
		# Only reset level-specific state (health), preserving score and game config
		reset_level_state()

# Game state management
func start_game() -> void:
	game_started = true
	game_paused = false
	emit_signal("game_state_changed", game_started, game_paused)

func pause_game() -> void:
	if game_started:
		game_paused = true
		emit_signal("game_state_changed", game_started, game_paused)

func resume_game() -> void:
	if game_started and game_paused:
		game_paused = false
		emit_signal("game_state_changed", game_started, game_paused)

func end_game() -> void:
	game_started = false
	game_paused = false
	emit_signal("game_state_changed", game_started, game_paused)

# Score management - UPDATED FUNCTIONALITY
func add_points(amount: int, pickup_position: Vector3 = Vector3.ZERO) -> void:
	player_score += amount
	if debug:
		print("GameManager: Score increased by %d. Total: %d" % [amount, player_score])
	
	# Emit signals for UI updates and score cubes
	emit_signal("score_updated", player_score)
	emit_signal("pickup_collected", pickup_position)

func get_score() -> int:
	return player_score

func set_score(new_score: int) -> void:
	player_score = max(0, new_score)
	emit_signal("score_updated", player_score)

# Legacy XP compatibility - maps to score now
func update_xp(amount: int) -> void:
	add_points(amount)

func get_xp() -> int:
	return get_score()

# Health management
func get_health() -> float:
	return player_health

func set_health(new_health: float) -> void:
	var previous_health := player_health
	player_health = clamp(new_health, 0.0, max_player_health)
	emit_signal("health_updated", player_health)
	if player_health < previous_health:
		var damage := previous_health - player_health
		emit_signal("player_damaged", damage, player_health)
		if player_health <= 0.0 and previous_health > 0.0:
			_handle_player_death()

func apply_health_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	set_health(player_health - amount)

func heal_player(amount: float) -> void:
	if amount <= 0.0:
		return
	set_health(player_health + amount)

func set_max_health(new_max: float, refill: bool = true) -> void:
	max_player_health = max(new_max, 1.0)
	if refill:
		set_health(max_player_health)
	else:
		set_health(min(player_health, max_player_health))

# Player registration
func register_player(player: Node3D) -> void:
	current_player = player
	emit_signal("player_registered", player)
	if debug:
		print("GameManager: Player registered: %s" % player.name)

func get_player() -> Node3D:
	return current_player

func _handle_player_death() -> void:
	if _death_sequence_running:
		return

	var death_position: Vector3 = _get_player_death_position()
	emit_signal("player_died", death_position)

	if debug:
		print("GameManager: Player health depleted at %s" % str(death_position))

	if death_sequence_enabled:
		_death_sequence_running = true
		call_deferred("_run_death_sequence", death_position)
	else:
		call_deferred("_reload_scene")

func _run_death_sequence(death_position: Vector3) -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		_death_sequence_running = false
		call_deferred("_reload_scene")
		return

	var scene_root: Node = tree.current_scene
	var memorial_position: Vector3 = _resolve_memorial_position(death_position)
	var focus_position: Vector3 = memorial_position + Vector3(0.0, 0.9, 0.0)
	var player_node: Node3D = _resolve_player_node()
	var is_xr_mode: bool = _is_xr_active()

	_spawn_death_cross(scene_root, memorial_position)

	var camera_pivot: Node3D = Node3D.new()
	camera_pivot.name = "DeathCameraPivot"
	scene_root.add_child(camera_pivot)
	camera_pivot.global_position = memorial_position

	var camera_rig: Node3D = Node3D.new()
	camera_rig.name = "DeathCameraRig"
	camera_pivot.add_child(camera_rig)

	var death_camera: Camera3D = Camera3D.new()
	death_camera.name = "DeathCamera"
	death_camera.fov = 72.0
	camera_rig.add_child(death_camera)

	if not is_xr_mode:
		death_camera.current = true

	var total_time: float = max(0.3, death_sequence_duration)
	var elapsed: float = 0.0

	while elapsed < total_time and is_inside_tree() and tree.current_scene == scene_root:
		await tree.process_frame
		if tree == null:
			break

		var delta: float = max(0.001, tree.root.get_process_delta_time())
		elapsed += delta

		var t: float = clamp(elapsed / total_time, 0.0, 1.0)
		var eased: float = _ease_out_cubic(t)
		var radius: float = lerp(death_start_radius, death_orbit_radius, eased)
		var height: float = lerp(death_start_height, death_orbit_height, eased)

		camera_pivot.rotation.y += delta * death_orbit_speed
		camera_rig.position = Vector3(0.0, height, radius)

		if is_xr_mode and is_instance_valid(player_node):
			player_node.global_position = camera_pivot.global_transform * camera_rig.position
		else:
			death_camera.look_at(focus_position, Vector3.UP)

	_death_sequence_running = false
	call_deferred("_reload_scene")

func _get_player_death_position() -> Vector3:
	var player_node: Node3D = _resolve_player_node()
	if is_instance_valid(player_node):
		return player_node.global_position
	return Vector3.ZERO

func _resolve_player_node() -> Node3D:
	if is_instance_valid(current_player):
		return current_player

	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return null

	var scene_root: Node = tree.current_scene
	var candidate: Node = null

	candidate = tree.get_first_node_in_group("player")
	if candidate is Node3D:
		current_player = candidate as Node3D
		return current_player

	candidate = tree.get_first_node_in_group("player_body")
	if candidate is Node3D:
		current_player = candidate as Node3D
		return current_player

	var names: Array[String] = ["XROrigin3D", "DesktopPlayer", "Player", "PlayerBody"]
	for name in names:
		candidate = scene_root.find_child(name, true, false)
		if candidate is Node3D:
			current_player = candidate as Node3D
			return current_player

	return null

func _spawn_death_cross(scene_root: Node, world_position: Vector3) -> Node3D:
	if DEATH_CROSS_SCENE == null:
		return null

	var cross_instance: Node = DEATH_CROSS_SCENE.instantiate()
	if not (cross_instance is Node3D):
		return null

	var cross_node: Node3D = cross_instance as Node3D
	cross_node.name = "DeathCross"
	cross_node.global_position = world_position + Vector3(0.0, death_cross_y_offset, 0.0)
	cross_node.scale = death_cross_scale
	scene_root.add_child(cross_node)

	if cross_node.has_method("set_base_color"):
		cross_node.call("set_base_color", death_cross_color)

	return cross_node

func _resolve_memorial_position(death_position: Vector3) -> Vector3:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return death_position

	var scene_root: Node = tree.current_scene
	if not (scene_root is Node3D):
		return death_position

	var scene_3d: Node3D = scene_root as Node3D
	var space_state: PhysicsDirectSpaceState3D = scene_3d.get_world_3d().direct_space_state
	if space_state == null:
		return death_position

	var from: Vector3 = death_position + Vector3(0.0, 3.0, 0.0)
	var to: Vector3 = death_position + Vector3(0.0, -8.0, 0.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.has("position") and hit["position"] is Vector3:
		return hit["position"]

	return death_position

func _is_xr_active() -> bool:
	var xr_interface: XRInterface = XRServer.get_primary_interface()
	return xr_interface != null and xr_interface.is_initialized()

func _ease_out_cubic(t: float) -> float:
	var clamped_t: float = clamp(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped_t, 3.0)



# Message management
func set_current_map(map_name: String) -> void:
	var normalized_name := str(map_name).strip_edges()
	if current_map_name == normalized_name:
		return
	current_map_name = normalized_name
	emit_signal("current_map_changed", current_map_name)
	if debug:
		print("GameManager: Current map set to %s" % current_map_name)

func get_current_map() -> String:
	return current_map_name

func set_message(message: String) -> void:
	current_message = message
	emit_signal("message_updated", current_message)
	if debug:
		print("GameManager: Message set to: " + message)

func get_message() -> String:
	return current_message

func add_console_message(text: String, type: String = "info", source: String = "system") -> void:
	var message_data = {
		"text": text,
		"type": type,  # "info", "warning", "error", "debug"
		"source": source,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	console_messages.append(message_data)
	
	# Keep only recent messages
	if console_messages.size() > max_console_messages:
		console_messages.pop_front()
	
	emit_signal("console_message_added", message_data)
	if debug:
		print("Console: [%s] %s: %s" % [type.to_upper(), source, text])

func clear_console() -> void:
	console_messages.clear()
	emit_signal("console_cleared")


func get_console_messages() -> Array[Dictionary]:
	return console_messages
	
func add_test_console_messages():
	add_console_message("Ada Research", "info", "system")
	add_console_message("A meta quest into the world of algorithms", "info", "system")	
	add_console_message("There was no time when there was nothing. First there was light and a body. Thrown into space. You, inside the experiment.", "warning", "health")
	

# Regenerate management
func request_regenerate(origin: Vector3, targets: Array = [], metadata: Dictionary = {}):
	if debug:
		print("GameManager: Regenerate requested from %s with %d target(s)" % [origin, targets.size()])
	emit_signal("regenerate_requested", origin, targets, metadata)

# Audio management
func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
 
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_show_infoboard(enabled: bool) -> void:
	show_infoboard = enabled
	emit_signal("settings_changed", "show_infoboard", enabled)
	save_game()

# Nail color management
func set_nail_color(color: Color) -> void:
	nail_color = color
	emit_signal("nail_color_changed", nail_color)


func get_nail_color() -> Color:
	return nail_color

# Hand color management
func set_hand_color(color: Color) -> void:
	hand_color = color
	emit_signal("hand_color_changed", hand_color)
	if debug:
		print("GameManager: Hand color set to %s" % color)

func get_hand_color() -> Color:
	return hand_color

# Save and load game state
func save_game() -> void:
	var save_data = {
		"player_score": player_score,
		"sound_enabled": sound_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"show_infoboard": show_infoboard,
		"game_mode": game_mode,
		"nail_color": {"r": nail_color.r, "g": nail_color.g, "b": nail_color.b, "a": nail_color.a},
		"hand_color": {"r": hand_color.r, "g": hand_color.g, "b": hand_color.b, "a": hand_color.a},
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
		print("GameManager: Game saved successfully")
	else:
		push_error("GameManager: Failed to save game")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.save"):
		print("GameManager: No save file found")
		return false
		
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()

		player_score = save_data.get("player_score", 0)
		sound_enabled = save_data.get("sound_enabled", true)
		music_volume = save_data.get("music_volume", 0.8)
		sfx_volume = save_data.get("sfx_volume", 0.7)
		show_infoboard = save_data.get("show_infoboard", false)
		# Skip loading game_mode - use default from script/scene instead
		# var loaded_mode = save_data.get("game_mode", GameMode.STORY)
		# print("GameManager: load_game() - raw game_mode from file: %s (type: %s)" % [loaded_mode, typeof(loaded_mode)])
		# game_mode = loaded_mode
		print("GameManager: load_game() - keeping game_mode from default: %s" % get_game_mode_name())

		# Load nail color
		var color_data = save_data.get("nail_color", null)
		if color_data:
			nail_color = Color(color_data.get("r", 1.0), color_data.get("g", 0.5), color_data.get("b", 0.7), color_data.get("a", 1.0))
			emit_signal("nail_color_changed", nail_color)

		# Load hand color
		var hand_color_data = save_data.get("hand_color", null)
		if hand_color_data:
			hand_color = Color(hand_color_data.get("r", 0.8), hand_color_data.get("g", 0.6), hand_color_data.get("b", 0.5), hand_color_data.get("a", 1.0))
			emit_signal("hand_color_changed", hand_color)

		emit_signal("score_updated", player_score)
		if debug:
			print("GameManager: Game loaded successfully - Score: %d" % player_score)
		return true
	else:
		push_error("GameManager: Failed to load game")
		return false

# Game Mode Management
func set_game_mode(mode: GameMode) -> void:
	if game_mode == mode:
		return
	game_mode = mode
	emit_signal("game_mode_changed", mode)
	if debug:
		print("GameManager: Game mode set to %s" % GameMode.keys()[mode])
	save_game()

func get_game_mode() -> GameMode:
	return game_mode

func is_test_mode() -> bool:
	return game_mode == GameMode.TEST

func is_explorer_mode() -> bool:
	return game_mode == GameMode.EXPLORER

func is_story_mode() -> bool:
	return game_mode == GameMode.STORY

func cycle_game_mode() -> void:
	var next_mode = (game_mode + 1) % GameMode.size()
	set_game_mode(next_mode as GameMode)

func get_game_mode_name() -> String:
	return GameMode.keys()[game_mode]

# Debug functions
func add_test_points(amount: int = 10) -> void:
	add_points(amount, Vector3(randf_range(-5, 5), 1, randf_range(-5, 5)))

func reset_score() -> void:
	set_score(0)
	if debug:
		print("GameManager: Score reset to 0")
