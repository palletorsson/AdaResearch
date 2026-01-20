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
[center][i]Algorithms as Living Systems[/i][/center]

[b]What This Is[/b]
An embodied journey through computational thinking. Not tutorials—explorations. Walk through the mathematics that shapes our world, from the simplest point to emergent swarm intelligence.

[b]The Progression[/b]
[color=yellow]Primitives[/color] → Ordered foundations (points, lines, cubes)
[color=yellow]Wavefunctions[/color] → Oscillation between poles (sine, Fourier, chaos)
[color=yellow]Randomness[/color] → Freedom from pattern (entropy as possibility)
[color=yellow]Emergence[/color] → Patterns without blueprint (swarm, cellular automata)

[b]The Principle[/b]
Systems survive by oscillating between order and chaos—never crystallizing, never dissolving. This is the edge of chaos, where adaptation happens.

[b]Instructions[/b]
- Wander. There is no correct path.
- Collect code snippets to your clipboard.
- Each sequence unlocks new territory.

[b]Credits[/b]
A collaboration between Konstfack, KTH Stockholm, and the edges of computational possibility. Powered by Godot Engine 4.

[i]"Entropy is not decay. Entropy is freedom."[/i]
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
