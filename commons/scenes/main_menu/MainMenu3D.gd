extends Node3D

signal start_game_requested
signal quit_requested

@onready var start_button = $Buttons/StartButton
@onready var settings_button = $Buttons/SettingsButton
@onready var quit_button = $Buttons/QuitButton
@onready var about_display = $AboutDisplay

func _ready():
	start_button.clicked.connect(_on_start_clicked)
	settings_button.clicked.connect(_on_settings_clicked)
	quit_button.clicked.connect(_on_quit_clicked)
	
	# Setup About text
	_setup_about_text()

func _setup_about_text():
	var about_text = """[center][b]Ada Research[/b][/center]

[b]Purpose and Aims[/b]
With the increasing role of algorithms in our daily lives, there is a growing need to understand the black boxes that shape our world.

This project is a collaboration between Konstfack, The Royal Institute of Technology Stockholm and Design.

[b]Instructions:[/b]
- Hover over buttons to select.
- Explore the labs to discover new algorithms.
- Use the clipboard to collect code snippets.

[b]Credits:[/b]
Developed by the Ada Research Team.
Powered by Godot Engine 4.

[i]"We can only see a short distance ahead, but we can see plenty there that needs to be done." - Alan Turing[/i]
"""
	if about_display.has_method("set_tutorial_from_text"):
		about_display.set_tutorial_from_text(about_text)

func _on_start_clicked():
	print("MainMenu: Start Game clicked")
	start_game_requested.emit()

const SETTINGS_SCENE = preload("res://commons/scenes/main_menu/objects/settings_ui.tscn")
var settings_instance: Node3D = null

func _on_settings_clicked():
	print("MainMenu: Settings clicked")
	
	# If already open, close it (toggle behavior)
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null
		if about_display:
			about_display.visible = true
		return

	# Instantiate Settings UI
	settings_instance = SETTINGS_SCENE.instantiate()
	add_child(settings_instance)
	
	# Swap in position: Use exact transform of About Display
	if about_display:
		settings_instance.transform = about_display.transform
		about_display.visible = false
	else:
		# Fallback if About Display is missing
		settings_instance.position = Vector3(0.6, 0, 0)
		settings_instance.rotation_degrees.y = 0

func _on_quit_clicked():
	print("MainMenu: Quit clicked")
	quit_requested.emit()
	get_tree().quit()
