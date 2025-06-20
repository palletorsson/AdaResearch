# GameManager.gd
# Updated singleton for score management
# Add this script as an AutoLoad/Singleton in Project Settings

extends Node

# Game state
var player_score: int = 0
var current_message: String = ""
var game_started: bool = false
var game_paused: bool = false

# Game settings
var sound_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 0.7

# Signals
signal score_updated(new_score: int)
signal pickup_collected(pickup_position: Vector3)
signal message_updated(message: String)
signal game_state_changed(is_started: bool, is_paused: bool)

# Called when the game starts
func _ready() -> void:
	print("GameManager: Singleton initialized")
	reset_game_state()

# Reset the game state
func reset_game_state() -> void:
	player_score = 0
	current_message = ""
	game_started = false
	game_paused = false
	emit_signal("game_state_changed", game_started, game_paused)
	emit_signal("score_updated", player_score)

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

# Message management
func set_message(message: String) -> void:
	current_message = message
	emit_signal("message_updated", current_message)
	print("GameManager: Message set to: " + message)

func get_message() -> String:
	return current_message

# Audio management
func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

# Save and load game state
func save_game() -> void:
	var save_data = {
		"player_score": player_score,
		"sound_enabled": sound_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
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
		
		emit_signal("score_updated", player_score)
		print("GameManager: Game loaded successfully - Score: %d" % player_score)
		return true
	else:
		push_error("GameManager: Failed to load game")
		return false

# Debug functions
func add_test_points(amount: int = 10) -> void:
	add_points(amount, Vector3(randf_range(-5, 5), 1, randf_range(-5, 5)))

func reset_score() -> void:
	set_score(0)
	print("GameManager: Score reset to 0")
