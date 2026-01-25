extends Node3D

signal start_game_requested
signal quit_requested

@onready var start_button = $Buttons/StartButton
@onready var browse_button = $Buttons/BrowseButton
@onready var settings_button = $Buttons/SettingsButton
@onready var quit_button = $Buttons/QuitButton
@onready var about_display = $AboutDisplay

const MAP_BROWSER_SCENE = preload("res://commons/scenes/main_menu/components/MapBrowser3D.tscn")
var map_browser_instance: Node3D = null

func _ready():
	start_button.clicked.connect(_on_start_clicked)
	if browse_button:
		browse_button.clicked.connect(_on_browse_clicked)
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

func _on_browse_clicked():
	print("MainMenu: Browse clicked")

	# Close settings if open
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null

	# Toggle map browser
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null
		if about_display:
			about_display.visible = true
		return

	# Instantiate Map Browser
	map_browser_instance = MAP_BROWSER_SCENE.instantiate()
	add_child(map_browser_instance)

	# Connect signals
	map_browser_instance.sequence_selected.connect(_on_sequence_selected)
	map_browser_instance.map_selected.connect(_on_map_selected)
	map_browser_instance.back_requested.connect(_on_browser_back)

	# Position where About Display was
	if about_display:
		map_browser_instance.transform = about_display.transform
		about_display.visible = false
	else:
		map_browser_instance.position = Vector3(0.6, 0, 0)

func _on_sequence_selected(sequence_name: String):
	print("MainMenu: Starting sequence: %s" % sequence_name)
	# Use SceneManager to start the sequence
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.start_sequence(sequence_name)
	else:
		push_error("MainMenu: SceneManager not found")

func _on_map_selected(map_name: String):
	print("MainMenu: Loading map: %s" % map_name)
	# Use SceneManager to load the map directly
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.load_map(map_name)
	else:
		push_error("MainMenu: SceneManager not found")

func _on_browser_back():
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null
	if about_display:
		about_display.visible = true

func _on_settings_clicked():
	print("MainMenu: Settings clicked")

	# Close map browser if open
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null

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
