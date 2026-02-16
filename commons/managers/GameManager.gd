# GameManager.gd
# Updated singleton for score management
# Add this script as an AutoLoad/Singleton in Project Settings

extends Node

const DEATH_CROSS_SCENE: PackedScene = preload("res://commons/primitives/plus/plus.tscn")
const TESTPLUS_SEQUENCE_INDEX_PATH := "res://commons/maps/sequences/sequence_index.json"

# Game Modes
enum GameMode {
	STORY,      # Full sequence playthrough (default)
	TEST,       # Skip to last map of each sequence, then lab
	EXPLORER,   # Full lab unlocked, all paths available
	TESTPLUS    # Test flow with sequence filtering and optional full-sequence traversal
}

@export var game_mode: GameMode = GameMode.STORY # Default to TEST for quick iteration
@export var testplus_full_sequence_active: bool = false
@export var testplus_excluded_sequences: Array[String] = []
@export var testplus_available_sequence_ids: Array[String] = []
@export var testplus_available_sequence_names: Array[String] = []
@export_multiline var testplus_available_sequence_named_list: String = "Loads names from res://commons/maps/sequences/sequence_index.json at runtime."
var _testplus_sequence_alias_to_id: Dictionary = {}
var _testplus_sequence_id_to_name: Dictionary = {}

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
	_refresh_testplus_sequence_reference()
	print("GameManager: Singleton initialized - game_mode before load: %s" % get_game_mode_name())
	reset_game_state()
	
	# Load saved settings (game mode, colors, etc.)
	if FileAccess.file_exists("user://savegame.save"):
		print("GameManager: Save file exists, loading...")
		load_game()
		print("GameManager: After load - game_mode: %s (is_test=%s, is_testplus=%s)" % [get_game_mode_name(), is_test_mode(), is_testplus_mode()])
	
	add_test_console_messages()

func _refresh_testplus_sequence_reference() -> void:
	testplus_available_sequence_ids.clear()
	testplus_available_sequence_names.clear()
	testplus_available_sequence_named_list = ""
	_testplus_sequence_alias_to_id.clear()
	_testplus_sequence_id_to_name.clear()

	if not FileAccess.file_exists(TESTPLUS_SEQUENCE_INDEX_PATH):
		testplus_available_sequence_named_list = "Sequence index not found: %s" % TESTPLUS_SEQUENCE_INDEX_PATH
		return

	var file = FileAccess.open(TESTPLUS_SEQUENCE_INDEX_PATH, FileAccess.READ)
	if not file:
		testplus_available_sequence_named_list = "Could not open: %s" % TESTPLUS_SEQUENCE_INDEX_PATH
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		testplus_available_sequence_named_list = "Failed to parse sequence index JSON: %s" % json.get_error_message()
		return

	var data = json.data
	var sequence_entries = data.get("sequences", [])
	if not (sequence_entries is Array):
		testplus_available_sequence_named_list = "Invalid sequence index format: sequences must be an array"
		return

	var named_lines: Array[String] = []
	for entry in sequence_entries:
		if not (entry is Dictionary):
			continue
		var sequence_id = str(entry.get("id", "")).strip_edges()
		if sequence_id.is_empty():
			continue
		var sequence_name = str(entry.get("name", sequence_id)).strip_edges()
		testplus_available_sequence_ids.append(sequence_id)
		testplus_available_sequence_names.append(sequence_name)

		var normalized_id = sequence_id.to_lower()
		var normalized_name = sequence_name.to_lower()
		_testplus_sequence_alias_to_id[normalized_id] = sequence_id
		_testplus_sequence_alias_to_id[normalized_name] = sequence_id
		_testplus_sequence_id_to_name[normalized_id] = sequence_name
		named_lines.append(sequence_name)

	testplus_available_sequence_named_list = "\n".join(named_lines)

func _resolve_testplus_sequence_id(sequence_ref: String) -> String:
	if _testplus_sequence_alias_to_id.is_empty() and FileAccess.file_exists(TESTPLUS_SEQUENCE_INDEX_PATH):
		_refresh_testplus_sequence_reference()
	var normalized_ref = sequence_ref.strip_edges().to_lower()
	if normalized_ref.is_empty():
		return ""
	if _testplus_sequence_alias_to_id.has(normalized_ref):
		return str(_testplus_sequence_alias_to_id[normalized_ref]).strip_edges().to_lower()
	return normalized_ref
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
	# Try checkpoint respawn first
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_checkpoint():
		checkpoint_manager.respawn_at_checkpoint()
		reset_level_state()
		return
	
	# Fallback: reload scene
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
	var player_node: Node3D = _resolve_player_node()
	var is_xr_mode: bool = _is_xr_active()

	# Spawn death cross at ground level
	_spawn_death_cross(scene_root, memorial_position)

	# CCTV camera position: offset (1, 5, 1) from death position
	var cctv_offset = Vector3(1.0, 5.0, 1.0)
	var cctv_position = memorial_position + cctv_offset
	
	# Create CCTV camera
	var death_camera: Camera3D = Camera3D.new()
	death_camera.name = "DeathCCTVCamera"
	death_camera.fov = 60.0
	scene_root.add_child(death_camera)
	death_camera.global_position = cctv_position
	death_camera.look_at(memorial_position, Vector3.UP)

	if not is_xr_mode:
		death_camera.current = true
	elif is_instance_valid(player_node):
		# In VR, move player to CCTV position
		player_node.global_position = cctv_position
	
	# Create restart button UI
	_show_death_ui(scene_root)
	
	print("[GameManager] Death sequence - CCTV at %s looking at %s" % [cctv_position, memorial_position])

func _show_death_ui(scene_root: Node) -> void:
	# Create a simple 3D restart button
	var ui_root = Node3D.new()
	ui_root.name = "DeathUI"
	scene_root.add_child(ui_root)
	
	# Position UI in front of CCTV camera
	var camera = scene_root.get_node_or_null("DeathCCTVCamera")
	if camera:
		ui_root.global_position = camera.global_position + (-camera.global_transform.basis.z * 2.0)
		ui_root.look_at(camera.global_position, Vector3.UP)
		ui_root.rotate_y(PI)  # Face camera
	
	# "YOU DIED" text
	var died_label = Label3D.new()
	died_label.text = "YOU DIED"
	died_label.font_size = 72
	died_label.modulate = Color(0.9, 0.2, 0.2)
	died_label.position.y = 0.5
	died_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ui_root.add_child(died_label)
	
	# Restart button (using Area3D for VR interaction)
	var restart_button = _create_death_button("RESTART", Vector3(0, 0, 0), Color(0.2, 0.8, 0.3))
	restart_button.name = "RestartButton"
	ui_root.add_child(restart_button)
	
	# Menu button
	var menu_button = _create_death_button("MENU", Vector3(0, -0.4, 0), Color(0.3, 0.5, 0.8))
	menu_button.name = "MenuButton"
	ui_root.add_child(menu_button)

func _create_death_button(text: String, pos: Vector3, color: Color) -> Area3D:
	var button = Area3D.new()
	button.position = pos
	button.collision_layer = 0
	button.collision_mask = 524288  # Player layer
	
	# Collision shape
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 0.25, 0.1)
	collision.shape = box
	button.add_child(collision)
	
	# Visual box
	var mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.25, 0.05)
	mesh.mesh = box_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	button.add_child(mesh)
	
	# Label
	var label = Label3D.new()
	label.text = text
	label.font_size = 48
	label.position.z = 0.03
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	button.add_child(label)
	
	# Connect body entered for VR hands
	button.body_entered.connect(_on_death_button_pressed.bind(text))
	button.area_entered.connect(_on_death_button_area.bind(text))
	
	return button

func _on_death_button_pressed(body: Node3D, button_name: String) -> void:
	_handle_death_button(button_name)

func _on_death_button_area(area: Area3D, button_name: String) -> void:
	if area.name.contains("Hand") or area.name.contains("Pointer"):
		_handle_death_button(button_name)

func _handle_death_button(button_name: String) -> void:
	print("[GameManager] Death button pressed: %s" % button_name)
	_death_sequence_running = false
	
	match button_name:
		"RESTART":
			call_deferred("_reload_scene")
		"MENU":
			# Go to main menu
			var scene_manager = get_node_or_null("/root/SceneManager")
			if scene_manager and scene_manager.has_method("load_main_menu"):
				scene_manager.load_main_menu()
			else:
				get_tree().change_scene_to_file("res://commons/scenes/main_menu/MainMenu3D.tscn")

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
		"testplus_full_sequence_active": testplus_full_sequence_active,
		"testplus_excluded_sequences": testplus_excluded_sequences,
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
		testplus_full_sequence_active = bool(save_data.get("testplus_full_sequence_active", false))
		testplus_excluded_sequences.clear()
		var saved_testplus_exclusions = save_data.get("testplus_excluded_sequences", [])
		if saved_testplus_exclusions is Array:
			for seq_name in saved_testplus_exclusions:
				testplus_excluded_sequences.append(str(seq_name))
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

func is_testplus_mode() -> bool:
	return game_mode == GameMode.TESTPLUS

func is_sequence_excluded_in_testplus(sequence_name: String) -> bool:
	if sequence_name.is_empty():
		return false
	var normalized = _resolve_testplus_sequence_id(sequence_name)
	for excluded_sequence in testplus_excluded_sequences:
		if _resolve_testplus_sequence_id(str(excluded_sequence)) == normalized:
			return true
	return false

func should_testplus_play_full_sequence(sequence_name: String = "") -> bool:
	if not is_testplus_mode():
		return false
	if not sequence_name.is_empty() and is_sequence_excluded_in_testplus(sequence_name):
		return false
	return testplus_full_sequence_active

func should_testplus_sample_sequence(sequence_name: String = "") -> bool:
	if not is_testplus_mode():
		return false
	if not sequence_name.is_empty() and is_sequence_excluded_in_testplus(sequence_name):
		return false
	return not testplus_full_sequence_active

func set_testplus_full_sequence_active(active: bool) -> void:
	if testplus_full_sequence_active == active:
		return
	testplus_full_sequence_active = active
	emit_signal("settings_changed", "testplus_full_sequence_active", active)
	save_game()

func set_testplus_excluded_sequences(sequence_names: Array[String]) -> void:
	testplus_excluded_sequences.clear()
	var seen: Dictionary = {}
	for sequence_name in sequence_names:
		var normalized = str(sequence_name).strip_edges()
		if normalized.is_empty():
			continue
		var canonical_id = _resolve_testplus_sequence_id(normalized)
		if seen.has(canonical_id):
			continue
		seen[canonical_id] = true

		if _testplus_sequence_id_to_name.has(canonical_id):
			testplus_excluded_sequences.append(str(_testplus_sequence_id_to_name[canonical_id]))
		else:
			testplus_excluded_sequences.append(normalized)
	emit_signal("settings_changed", "testplus_excluded_sequences", testplus_excluded_sequences.duplicate())
	save_game()

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
