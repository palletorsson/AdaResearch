# QuitGameController.gd - Area3D-based quit game cube (like teleport cube)
extends Node3D
class_name QuitGameController

# Quit game cube functionality - follows teleport cube pattern
signal quit_game_requested()
signal quit_confirmed()
signal quit_cancelled()

# Configuration properties (can be set in editor)
@export var require_confirmation: bool = true
@export var confirmation_timeout: float = 2.0
@export var quit_cube_color: Color = Color.RED
@export var warning_color: Color = Color.ORANGE_RED

# Internal state
var player_in_area: bool = false
var confirmation_active: bool = false
var quit_timer: Timer

# Node references (set up like teleport cube)
@onready var quit_area: Area3D = $QuitArea
@onready var cube_mesh: MeshInstance3D = $Cube
@onready var quit_label: Label3D = $QuitLabel

# Audio support (like teleport cube)
var audio_player: Node3D
var warning_tween: Tween

func _ready():
	print("QuitGameController: Initializing quit cube...")
	
	# Setup Area3D collision detection (EXACTLY like teleport cube)
	_setup_quit_area()
	
	# Setup visual elements
	_setup_visual_elements()
	
	# Setup timer for confirmation
	_setup_confirmation_timer()
	
	# Setup audio (optional)
	_setup_audio()
	
	print("QuitGameController: Quit cube ready")

func _setup_quit_area():
	"""Setup Area3D collision detection - CRITICAL: Must match teleport cube pattern"""
	if not quit_area:
		push_error("QuitGameController: QuitArea not found! Check scene structure.")
		return
	
	print("QuitGameController: Setting up quit area collision...")
	
	# EXACT same settings as teleport cube
	quit_area.collision_layer = 0      # This area doesn't provide collision
	quit_area.collision_mask = 524288  # Detect layer 20 (XR-Tools PlayerBody)
	quit_area.monitoring = true        # Enable detection
	quit_area.monitorable = false      # Other areas don't need to detect this
	
	# Connect the body_entered signal (CRITICAL - like teleport cube)
	if not quit_area.is_connected("body_entered", Callable(self, "_on_quit_area_body_entered")):
		quit_area.body_entered.connect(_on_quit_area_body_entered)
		print("QuitGameController: ✅ Connected body_entered signal")
	
	# Also connect body_exited for cancellation
	if not quit_area.is_connected("body_exited", Callable(self, "_on_quit_area_body_exited")):
		quit_area.body_exited.connect(_on_quit_area_body_exited)
		print("QuitGameController: ✅ Connected body_exited signal")
	
	print("QuitGameController: Area collision setup complete")

func _setup_visual_elements():
	"""Setup cube appearance and warning label"""
	# Setup cube material (red like danger)
	if cube_mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = quit_cube_color
		material.emission_enabled = true
		material.emission = quit_cube_color
		material.emission_energy = 0.8
		material.metallic = 0.1
		material.roughness = 0.9
		cube_mesh.material_override = material
		print("QuitGameController: Cube material applied")
	
	# Setup warning label (like teleport cube debug label)
	if quit_label:
		quit_label.text = "⚠️ QUIT GAME ⚠️\nWalk Into Cube"
		quit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		quit_label.font_size = 28
		quit_label.modulate = Color.WHITE
		print("QuitGameController: Warning label configured")

func _setup_confirmation_timer():
	"""Setup timer for quit confirmation"""
	quit_timer = Timer.new()
	quit_timer.name = "QuitTimer"
	quit_timer.wait_time = confirmation_timeout
	quit_timer.one_shot = true
	add_child(quit_timer)
	
	# Connect timer signal
	quit_timer.timeout.connect(_on_quit_timer_timeout)
	
	print("QuitGameController: Confirmation timer setup complete")

func _setup_audio():
	"""Setup audio player (optional - like teleport cube)"""
	# Create audio node similar to teleport cube
	audio_player = Node3D.new()
	audio_player.name = "QuitAudio"
	add_child(audio_player)
	
	print("QuitGameController: Audio setup complete")

# MAIN EVENT HANDLERS (following teleport cube pattern)

func _on_quit_area_body_entered(body: Node3D):
	"""Handle player entering quit area - MAIN ACTIVATION like teleport cube"""
	# Validate it's the player body (same logic as teleport cube)
	if not _is_player_body(body):
		return
	
	print("QuitGameController: Player entered quit area!")
	player_in_area = true
	
	# Start quit sequence
	if require_confirmation:
		_start_confirmation_sequence()
	else:
		_quit_immediately()

func _on_quit_area_body_exited(body: Node3D):
	"""Handle player leaving quit area - CANCELLATION"""
	if not _is_player_body(body):
		return
	
	print("QuitGameController: Player left quit area")
	player_in_area = false
	
	# Cancel any ongoing confirmation
	if confirmation_active:
		_cancel_quit_sequence()

func _is_player_body(body: Node3D) -> bool:
	"""Check if body is player - same logic as teleport/reset cubes"""
	# Check for XR-Tools PlayerBody (primary detection method)
	if body.get_script() and body.get_script().get_global_name() == "XRToolsPlayerBody":
		return true
	
	# Check for player group membership
	if body.is_in_group("player_body") or body.is_in_group("player"):
		return true
	
	# Check by name (fallback)
	var body_name = body.name.to_lower()
	if "player" in body_name or "character" in body_name:
		return true
	
	return false

# QUIT SEQUENCE METHODS

func _start_confirmation_sequence():
	"""Start quit confirmation sequence"""
	print("QuitGameController: Starting quit confirmation...")
	confirmation_active = true
	quit_game_requested.emit()
	
	# Update visual feedback
	if quit_label:
		quit_label.text = "⚠️ QUITTING IN %d ⚠️\nLeave to Cancel" % int(confirmation_timeout)
		quit_label.modulate = warning_color
	
	# Animate cube (pulsing red)
	_start_warning_animation()
	
	# Start countdown timer
	quit_timer.start()
	
	# Update countdown display
	_update_countdown_display()

func _update_countdown_display():
	"""Update countdown display during confirmation"""
	if not confirmation_active or not player_in_area:
		return
	
	var time_left = quit_timer.time_left
	if time_left > 0 and quit_label:
		quit_label.text = "⚠️ QUITTING IN %d ⚠️\nLeave to Cancel" % int(ceil(time_left))
		
		# Schedule next update
		await get_tree().create_timer(0.5).timeout
		_update_countdown_display()

func _cancel_quit_sequence():
	"""Cancel the quit sequence"""
	print("QuitGameController: Cancelling quit sequence")
	confirmation_active = false
	quit_timer.stop()
	quit_cancelled.emit()
	
	# Reset visual feedback
	if quit_label:
		quit_label.text = "⚠️ QUIT CANCELLED ⚠️"
		quit_label.modulate = Color.YELLOW
	
	# Stop warning animation
	_stop_warning_animation()
	
	# After brief pause, return to normal state
	await get_tree().create_timer(1.0).timeout
	
	if not player_in_area:
		_reset_to_normal_state()

func _reset_to_normal_state():
	"""Reset cube to normal waiting state"""
	if quit_label:
		quit_label.text = "⚠️ QUIT GAME ⚠️\nWalk Into Cube"
		quit_label.modulate = Color.WHITE
	
	_stop_warning_animation()

func _quit_immediately():
	"""Quit immediately without confirmation"""
	print("QuitGameController: Immediate quit!")
	quit_game_requested.emit()
	_execute_quit()

func _on_quit_timer_timeout():
	"""Handle quit timer timeout - actually quit the game"""
	if confirmation_active and player_in_area:
		print("QuitGameController: Confirmation timeout - executing quit")
		_execute_quit()

func _execute_quit():
	"""Actually quit the game"""
	print("QuitGameController: QUITTING GAME...")
	confirmation_active = false
	quit_confirmed.emit()
	
	# Final visual feedback
	if quit_label:
		quit_label.text = "⚠️ GOODBYE! ⚠️"
		quit_label.modulate = Color.WHITE
	
	# Save any important data before quitting
	_save_before_quit()
	
	# Brief pause for visual feedback
	await get_tree().create_timer(0.5).timeout
	
	# Actually quit the application
	get_tree().quit()

# VISUAL EFFECTS

func _start_warning_animation():
	"""Start warning animation (pulsing red cube)"""
	if not cube_mesh or not cube_mesh.material_override:
		return
	
	var material = cube_mesh.material_override as StandardMaterial3D
	if material:
		# Kill any existing tween to avoid duplicates
		if warning_tween:
			warning_tween.kill()
			warning_tween = null
		# Create pulsing animation
		warning_tween = create_tween()
		warning_tween.set_loops()
		warning_tween.tween_property(material, "emission_energy", 1.5, 0.5)
		warning_tween.tween_property(material, "emission_energy", 0.3, 0.5)

func _stop_warning_animation():
	"""Stop warning animation"""
	# Stop active tween if present
	if warning_tween:
		warning_tween.kill()
		warning_tween = null
	
	# Reset emission
	if cube_mesh and cube_mesh.material_override:
		var material = cube_mesh.material_override as StandardMaterial3D
		if material:
			material.emission_energy = 0.8

# UTILITY METHODS

func _save_before_quit():
	"""Save important data before quitting"""
	print("QuitGameController: Saving before quit...")
	
	# Save quit log
	var quit_data = {
		"quit_time": Time.get_datetime_string_from_system(),
		"quit_position": global_position,
		"confirmation_used": require_confirmation
	}
	
	var file = FileAccess.open("user://quit_log.save", FileAccess.WRITE)
	if file:
		file.store_var(quit_data)
		file.close()
		print("QuitGameController: Quit data saved")

# PUBLIC API (for external configuration)

func set_confirmation_required(required: bool):
	"""Set whether confirmation is required"""
	require_confirmation = required
	
	if quit_label:
		if required:
			quit_label.text = "⚠️ QUIT GAME ⚠️\nWalk Into Cube"
		else:
			quit_label.text = "⚠️ QUIT GAME ⚠️\nInstant Exit"

func set_confirmation_timeout(timeout: float):
	"""Set confirmation timeout duration"""
	confirmation_timeout = timeout
	if quit_timer:
		quit_timer.wait_time = timeout

func force_quit():
	"""Force quit immediately (for external systems)"""
	print("QuitGameController: Force quit requested")
	_execute_quit()

func get_quit_state() -> Dictionary:
	"""Get current quit cube state"""
	return {
		"player_in_area": player_in_area,
		"confirmation_active": confirmation_active,
		"require_confirmation": require_confirmation,
		"timeout": confirmation_timeout
	}
