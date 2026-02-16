extends ScrollContainer

@onready var infoboard_check = $VBoxContainer/InfoboardCheck
@onready var game_mode_option = $VBoxContainer/GameModeOption

func _ready():
	if GameManager:
		infoboard_check.button_pressed = GameManager.show_infoboard
		_setup_game_mode_option()

func _setup_game_mode_option():
	"""Setup game mode dropdown if it exists"""
	if not game_mode_option:
		return
	
	# Clear and add options
	game_mode_option.clear()
	game_mode_option.add_item("Story Mode", 0)
	game_mode_option.add_item("Test Mode (Skip)", 1)
	game_mode_option.add_item("Explorer Mode", 2)
	game_mode_option.add_item("TestPlus Mode", 3)
	
	# Set current selection
	game_mode_option.selected = GameManager.game_mode
	
	# Connect signal
	if not game_mode_option.item_selected.is_connected(_on_game_mode_changed):
		game_mode_option.item_selected.connect(_on_game_mode_changed)

func _on_game_mode_changed(index: int):
	"""Handle game mode selection change"""
	if GameManager:
		GameManager.set_game_mode(index as GameManager.GameMode)
		
		# If explorer mode, unlock all
		if index == GameManager.GameMode.EXPLORER:
			MapProgressionManager.unlock_all_sequences()
		
		print("Game mode changed to: %s" % GameManager.get_game_mode_name())

func _on_infoboard_check_toggled(toggled_on):
	if GameManager:
		GameManager.set_show_infoboard(toggled_on)
