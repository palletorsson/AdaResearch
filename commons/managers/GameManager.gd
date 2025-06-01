# GameManager.gd
# Add this script as an AutoLoad/Singleton in Project Settings
extends Node

# Game state
var player_xp: int = 0
var current_message: String = ""
var game_started: bool = false
var game_paused: bool = false

# Game settings
var sound_enabled: bool = true
var music_volume: float = 0.8
var sfx_volume: float = 0.7

# Signals
signal xp_updated(new_xp)
signal message_updated(message)
signal game_state_changed(is_started, is_paused)

# Called when the game starts
func _ready() -> void:
	# Initialize game state
	reset_game_state()

# Reset the game state
func reset_game_state() -> void:
	player_xp = 0
	current_message = ""
	game_started = false
	game_paused = false
	emit_signal("game_state_changed", game_started, game_paused)

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

# XP management

func update_xp(amount: int) -> void:
	player_xp += amount
	emit_signal("xp_updated", player_xp)
	print("GameManager: XP updated to " + str(player_xp))

func get_xp() -> int:
	return player_xp

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
	# You would have additional code here to mute/unmute in-game audio

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	# You would have additional code here to set your music player's volume

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	# You would have additional code here to set your SFX player's volume

# Save and load game state

func save_game() -> void:
	var save_data = {
		"player_xp": player_xp,
		"sound_enabled": sound_enabled,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		# Add other data you want to save
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		print("GameManager: Game saved successfully")
	else:
		push_error("GameManager: Failed to save game")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.save"):
		push_error("GameManager: No save file found")
		return false
		
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		
		player_xp = save_data.get("player_xp", 0)
		sound_enabled = save_data.get("sound_enabled", true)
		music_volume = save_data.get("music_volume", 0.8)
		sfx_volume = save_data.get("sfx_volume", 0.7)
		
		emit_signal("xp_updated", player_xp)
		print("GameManager: Game loaded successfully")
		return true
	else:
		push_error("GameManager: Failed to load game")
		return false
