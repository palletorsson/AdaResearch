extends Control
class_name GameSettingsPanel

## Standalone Game Settings Panel
## Run this scene directly to configure game settings
## Changes only apply when you hit SAVE

@onready var game_mode_option: OptionButton = %GameModeOption
@onready var score_spinbox: SpinBox = %ScoreSpinBox
@onready var health_slider: HSlider = %HealthSlider
@onready var health_label: Label = %HealthValue

@onready var completed_maps_label: Label = %CompletedMapsLabel
@onready var unlocked_maps_label: Label = %UnlockedMapsLabel
@onready var current_state_label: Label = %CurrentStateLabel
@onready var sequence_list: ItemList = %SequenceList

@onready var infoboard_check: CheckButton = %InfoboardCheck
@onready var debug_check: CheckButton = %DebugCheck
@onready var sound_check: CheckButton = %SoundCheck

@onready var status_label: Label = %StatusLabel

# Pending changes (not applied until Save)
var pending_changes: Dictionary = {}
var has_unsaved_changes: bool = false

func _ready():
	_setup_ui()
	_load_current_values()
	_connect_signals()
	_update_status("Ready - changes apply on Save")

func _setup_ui():
	# Setup game mode dropdown
	game_mode_option.clear()
	game_mode_option.add_item("Story Mode", 0)
	game_mode_option.add_item("Test Mode", 1)
	game_mode_option.add_item("Explorer Mode", 2)
	game_mode_option.add_item("TestPlus Mode", 3)
	
	# Setup health slider
	health_slider.min_value = 0
	health_slider.max_value = 100
	health_slider.step = 1

func _load_current_values():
	# Game state
	if GameManager:
		game_mode_option.selected = GameManager.game_mode
		score_spinbox.value = GameManager.get_score()
		health_slider.value = GameManager.get_health()
		health_label.text = "%d%%" % int(GameManager.get_health())
		infoboard_check.button_pressed = GameManager.show_infoboard
		debug_check.button_pressed = GameManager.debug
		sound_check.button_pressed = GameManager.sound_enabled
	
	# Progression state
	_update_progression_display()
	_populate_sequence_list()

func _connect_signals():
	# GameManager signals
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.health_updated.connect(_on_health_updated)
		GameManager.game_mode_changed.connect(_on_game_mode_changed)
	
	# MapProgressionManager signals
	if MapProgressionManager:
		MapProgressionManager.map_completed.connect(_on_map_completed)
		MapProgressionManager.map_unlocked.connect(_on_map_unlocked)
		MapProgressionManager.sequence_completed.connect(_on_sequence_completed)

func _update_progression_display():
	if MapProgressionManager:
		var completed = MapProgressionManager.get_completed_maps()
		var unlocked = MapProgressionManager.get_unlocked_maps()
		completed_maps_label.text = "Completed: %d maps" % completed.size()
		unlocked_maps_label.text = "Unlocked: %d maps" % unlocked.size()
	
	# LabManager is not a singleton - try to find instance in tree
	var lab_manager = _get_lab_manager_instance()
	if lab_manager:
		current_state_label.text = "Lab State: %s" % lab_manager.get_current_lab_state()
	else:
		current_state_label.text = "Lab State: (no lab loaded)"

func _get_lab_manager_instance() -> Node:
	"""Find LabManager instance in scene tree if it exists"""
	var lab_managers = get_tree().get_nodes_in_group("lab_manager")
	if lab_managers.size() > 0:
		return lab_managers[0]
	
	# Try to find by class name
	var root = get_tree().current_scene
	if root:
		var found = root.find_child("LabManager", true, false)
		if found:
			return found
	
	return null

func _populate_sequence_list():
	sequence_list.clear()
	
	if not MapProgressionManager:
		return
	
	var sequences = MapProgressionManager.get_all_sequence_names()
	for seq_name in sequences:
		var info = MapProgressionManager.get_sequence_info(seq_name)
		var status = "âœ“" if info.get("is_completed", false) else "â—‹"
		var pct = info.get("completion_percentage", 0)
		var text = "%s %s (%.0f%%)" % [status, seq_name, pct]
		sequence_list.add_item(text)

# === UI CALLBACKS (store pending, don't apply yet) ===

func _on_game_mode_option_item_selected(index: int):
	print("GameSettingsPanel: Game mode selected: %d" % index)
	pending_changes["game_mode"] = index
	_mark_unsaved()

func _on_score_spin_box_value_changed(value: float):
	pending_changes["score"] = int(value)
	_mark_unsaved()

func _on_health_slider_value_changed(value: float):
	pending_changes["health"] = value
	health_label.text = "%d%%" % int(value)
	_mark_unsaved()

func _on_infoboard_check_toggled(toggled_on: bool):
	pending_changes["show_infoboard"] = toggled_on
	_mark_unsaved()

func _on_debug_check_toggled(toggled_on: bool):
	pending_changes["debug"] = toggled_on
	_mark_unsaved()

func _on_sound_check_toggled(toggled_on: bool):
	pending_changes["sound_enabled"] = toggled_on
	_mark_unsaved()

func _mark_unsaved():
	has_unsaved_changes = true
	_update_status("âš ï¸ Unsaved changes - hit Save to apply")

func _on_reset_progress_pressed():
	if MapProgressionManager:
		MapProgressionManager.reset_progress()
	
	var lab_manager = _get_lab_manager_instance()
	if lab_manager:
		lab_manager.reset_progression()
	
	_update_progression_display()
	_populate_sequence_list()
	_update_status("Progress reset!")

func _on_unlock_all_pressed():
	if MapProgressionManager:
		MapProgressionManager.unlock_all_sequences()
	_update_progression_display()
	_populate_sequence_list()
	_update_status("All sequences unlocked!")

func _on_save_pressed():
	print("GameSettingsPanel: Save pressed - pending_changes: %s" % str(pending_changes))
	
	# Apply all pending changes NOW
	_apply_pending_changes()
	
	# Then save to file
	if GameManager:
		print("GameSettingsPanel: Saving - current game_mode: %s" % GameManager.get_game_mode_name())
		GameManager.save_game()
	if MapProgressionManager:
		MapProgressionManager.save_player_progress()
	
	has_unsaved_changes = false
	pending_changes.clear()
	_update_status("âœ… Settings saved and applied!")

func _apply_pending_changes():
	"""Apply all pending changes to GameManager"""
	if not GameManager:
		return
	
	if pending_changes.has("game_mode"):
		var mode = pending_changes["game_mode"]
		GameManager.set_game_mode(mode as GameManager.GameMode)
		if mode == GameManager.GameMode.EXPLORER:
			MapProgressionManager.unlock_all_sequences()
			_populate_sequence_list()
		print("Applied game mode: %s" % GameManager.get_game_mode_name())
	
	if pending_changes.has("score"):
		GameManager.set_score(pending_changes["score"])
	
	if pending_changes.has("health"):
		GameManager.set_health(pending_changes["health"])
	
	if pending_changes.has("show_infoboard"):
		GameManager.set_show_infoboard(pending_changes["show_infoboard"])
	
	if pending_changes.has("debug"):
		GameManager.debug = pending_changes["debug"]
	
	if pending_changes.has("sound_enabled"):
		GameManager.set_sound_enabled(pending_changes["sound_enabled"])

func _on_load_pressed():
	if GameManager:
		GameManager.load_game()
	if MapProgressionManager:
		MapProgressionManager.load_player_progress()
	_load_current_values()
	pending_changes.clear()
	has_unsaved_changes = false
	_update_status("Settings loaded!")

func _on_sequence_list_item_activated(index: int):
	# Double-click to complete a sequence
	var sequences = MapProgressionManager.get_all_sequence_names()
	if index < sequences.size():
		var seq_name = sequences[index]
		var maps = MapProgressionManager.get_sequence_maps(seq_name)
		for map_name in maps:
			MapProgressionManager.complete_map(map_name)
		_populate_sequence_list()
		_update_status("Completed sequence: %s" % seq_name)

# === SIGNAL HANDLERS ===

func _on_score_updated(new_score: int):
	score_spinbox.value = new_score

func _on_health_updated(new_health: float):
	health_slider.value = new_health
	health_label.text = "%d%%" % int(new_health)

func _on_game_mode_changed(new_mode):
	game_mode_option.selected = new_mode

func _on_map_completed(_map_name: String):
	_update_progression_display()
	_populate_sequence_list()

func _on_map_unlocked(_map_name: String):
	_update_progression_display()

func _on_sequence_completed(sequence_name: String):
	_update_progression_display()
	_populate_sequence_list()
	_update_status("Sequence completed: %s" % sequence_name)

func _update_status(message: String):
	status_label.text = message
	print("GameSettingsPanel: %s" % message)
