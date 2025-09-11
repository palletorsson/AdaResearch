# TimeLimitHazard.gd
# Time pressure system that restarts the level when time runs out
extends Control
class_name TimeLimitHazard

# Time settings
@export var time_limit: float = 60.0  # Time in seconds
@export var warning_threshold: float = 10.0  # Start warning when this much time left
@export var critical_threshold: float = 5.0   # Critical warning threshold
@export var auto_restart: bool = true  # Automatically restart level
@export var show_countdown: bool = true

# Visual settings
@export var normal_color: Color = Color.WHITE
@export var warning_color: Color = Color.YELLOW
@export var critical_color: Color = Color.RED
@export var font_size: int = 48
@export var timer_position: Vector2 = Vector2(50, 50)

# Audio
@export var tick_sound: AudioStream
@export var warning_sound: AudioStream
@export var timeout_sound: AudioStream
@export var tick_interval: float = 1.0  # Play tick every second

# Restart settings
@export var restart_delay: float = 2.0  # Delay before restart
@export var fade_out_time: float = 1.0

# Internal state
var current_time: float
var is_running: bool = false
var is_paused: bool = false
var tick_timer: float = 0.0
var last_tick_second: int = -1

# UI elements
var timer_label: Label
var background_panel: Panel
var warning_overlay: ColorRect
var audio_player: AudioStreamPlayer

# Game manager reference
var game_manager: Node
var level_scene_path: String

signal time_warning(time_left: float)
signal time_critical(time_left: float)
signal time_expired()
signal countdown_tick(seconds_left: int)

func _ready():
	# Setup UI
	_setup_ui()
	
	# Find game manager
	_find_game_manager()
	
	# Initialize timer
	reset_timer()
	
	print("TimeLimitHazard: Initialized with ", time_limit, " seconds")

func _setup_ui():
	# Create background panel
	background_panel = Panel.new()
	background_panel.size = Vector2(200, 80)
	background_panel.position = timer_position
	
	# Create panel style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	background_panel.add_theme_stylebox_override("panel", style_box)
	add_child(background_panel)
	
	# Create timer label
	timer_label = Label.new()
	timer_label.text = _format_time(time_limit)
	timer_label.add_theme_font_size_override("font_size", font_size)
	timer_label.add_theme_color_override("font_color", normal_color)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.anchors_preset = Control.PRESET_FULL_RECT
	background_panel.add_child(timer_label)
	
	# Create warning overlay (for screen flash effects)
	warning_overlay = ColorRect.new()
	warning_overlay.color = Color(1, 0, 0, 0)  # Transparent red
	warning_overlay.anchors_preset = Control.PRESET_FULL_RECT
	warning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warning_overlay)
	
	# Setup audio
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Set visibility
	background_panel.visible = show_countdown

func _find_game_manager():
	# Try multiple ways to find game manager
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		game_manager = get_tree().current_scene.find_child("*GameManager*", true, false)
	if not game_manager:
		game_manager = get_tree().current_scene.find_child("*Manager*", true, false)
	
	if game_manager:
		print("TimeLimitHazard: Found game manager: ", game_manager.name)
	else:
		print("TimeLimitHazard: Warning - No game manager found")
	
	# Store current scene path for restart
	level_scene_path = get_tree().current_scene.scene_file_path

func _process(delta):
	if not is_running or is_paused:
		return
	
	# Update timer
	current_time -= delta
	tick_timer += delta
	
	# Update display
	if show_countdown:
		_update_display()
	
	# Check for tick sound
	if tick_timer >= tick_interval:
		_handle_tick()
		tick_timer = 0.0
	
	# Check thresholds
	_check_time_thresholds()
	
	# Check if time is up
	if current_time <= 0:
		_time_expired()

func _update_display():
	if not timer_label:
		return
	
	timer_label.text = _format_time(max(0, current_time))
	
	# Update color based on time remaining
	var color = normal_color
	if current_time <= critical_threshold:
		color = critical_color
	elif current_time <= warning_threshold:
		color = warning_color
	
	timer_label.add_theme_color_override("font_color", color)
	
	# Pulse effect when critical
	if current_time <= critical_threshold:
		var pulse = 0.7 + 0.3 * sin(Time.get_time_dict_from_system().second * 10.0)
		timer_label.modulate = Color(1, 1, 1, pulse)
	else:
		timer_label.modulate = Color.WHITE

func _handle_tick():
	var seconds_left = int(ceil(current_time))
	
	# Only emit tick if second changed
	if seconds_left != last_tick_second:
		last_tick_second = seconds_left
		emit_signal("countdown_tick", seconds_left)
		
		# Play tick sound
		if tick_sound and (current_time <= warning_threshold):
			audio_player.stream = tick_sound
			audio_player.play()

func _check_time_thresholds():
	# Warning threshold
	if current_time <= warning_threshold and current_time > critical_threshold:
		if not _has_emitted_warning():
			emit_signal("time_warning", current_time)
			_play_warning_sound()
			_set_warning_emitted(true)
	
	# Critical threshold
	elif current_time <= critical_threshold:
		if not _has_emitted_critical():
			emit_signal("time_critical", current_time)
			_play_warning_sound()
			_create_screen_flash()
			_set_critical_emitted(true)

var warning_emitted: bool = false
var critical_emitted: bool = false

func _has_emitted_warning() -> bool:
	return warning_emitted

func _has_emitted_critical() -> bool:
	return critical_emitted

func _set_warning_emitted(value: bool):
	warning_emitted = value

func _set_critical_emitted(value: bool):
	critical_emitted = value

func _play_warning_sound():
	if warning_sound:
		audio_player.stream = warning_sound
		audio_player.play()

func _create_screen_flash():
	# Flash red screen
	if warning_overlay:
		var tween = create_tween()
		tween.tween_property(warning_overlay, "color", Color(1, 0, 0, 0.3), 0.1)
		tween.tween_property(warning_overlay, "color", Color(1, 0, 0, 0), 0.3)

func _time_expired():
	if current_time > 0:  # Prevent multiple calls
		return
	
	current_time = 0
	is_running = false
	
	print("TimeLimitHazard: Time expired!")
	emit_signal("time_expired")
	
	# Play timeout sound
	if timeout_sound:
		audio_player.stream = timeout_sound
		audio_player.play()
	
	# Create dramatic screen effect
	_create_timeout_effect()
	
	# Restart level if enabled
	if auto_restart:
		_restart_level()

func _create_timeout_effect():
	if not warning_overlay:
		return
	
	# Full screen red flash
	var tween = create_tween()
	tween.tween_property(warning_overlay, "color", Color(1, 0, 0, 0.8), 0.2)
	tween.tween_property(warning_overlay, "color", Color(1, 0, 0, 0.5), 0.5)
	tween.tween_property(warning_overlay, "color", Color(0, 0, 0, 1.0), fade_out_time)

func _restart_level():
	print("TimeLimitHazard: Restarting level in ", restart_delay, " seconds...")
	
	# Create restart timer
	var restart_timer = Timer.new()
	restart_timer.wait_time = restart_delay
	restart_timer.one_shot = true
	restart_timer.timeout.connect(_perform_restart)
	add_child(restart_timer)
	restart_timer.start()

func _perform_restart():
	print("TimeLimitHazard: Performing level restart")
	
	# Try different restart methods
	if game_manager and game_manager.has_method("restart_level"):
		game_manager.restart_level()
	elif game_manager and game_manager.has_method("reload_scene"):
		game_manager.reload_scene()
	elif level_scene_path != "":
		get_tree().change_scene_to_file(level_scene_path)
	else:
		# Fallback: reload current scene
		get_tree().reload_current_scene()

func _format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - floor(time_seconds)) * 100)
	
	if minutes > 0:
		return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
	else:
		return "%02d.%02d" % [seconds, milliseconds]

# Public API
func start_timer():
	is_running = true
	is_paused = false
	print("TimeLimitHazard: Timer started")

func stop_timer():
	is_running = false
	print("TimeLimitHazard: Timer stopped")

func pause_timer():
	is_paused = true
	print("TimeLimitHazard: Timer paused")

func resume_timer():
	is_paused = false
	print("TimeLimitHazard: Timer resumed")

func reset_timer():
	current_time = time_limit
	is_running = false
	is_paused = false
	tick_timer = 0.0
	last_tick_second = -1
	warning_emitted = false
	critical_emitted = false
	
	if timer_label:
		timer_label.text = _format_time(time_limit)
		timer_label.add_theme_color_override("font_color", normal_color)
		timer_label.modulate = Color.WHITE
	
	if warning_overlay:
		warning_overlay.color = Color(1, 0, 0, 0)
	
	print("TimeLimitHazard: Timer reset to ", time_limit, " seconds")

func add_time(seconds: float):
	current_time += seconds
	current_time = min(current_time, time_limit)  # Cap at original limit
	print("TimeLimitHazard: Added ", seconds, " seconds. New time: ", current_time)

func remove_time(seconds: float):
	current_time -= seconds
	current_time = max(current_time, 0)
	print("TimeLimitHazard: Removed ", seconds, " seconds. New time: ", current_time)

func set_time_limit(new_limit: float):
	time_limit = new_limit
	if current_time > time_limit:
		current_time = time_limit

func get_time_remaining() -> float:
	return current_time

func get_time_percentage() -> float:
	return current_time / time_limit

func is_timer_running() -> bool:
	return is_running and not is_paused

func set_visibility(visible: bool):
	show_countdown = visible
	if background_panel:
		background_panel.visible = visible
