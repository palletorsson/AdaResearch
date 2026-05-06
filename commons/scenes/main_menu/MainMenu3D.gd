extends Node3D

signal start_game_requested
signal load_game_requested
signal quit_requested

@onready var new_game_button = $Buttons/NewGameButton
@onready var load_game_button = $Buttons/LoadGameButton
@onready var browse_button = $Buttons/BrowseButton
@onready var settings_button = $Buttons/SettingsButton
@onready var quit_button = $Buttons/QuitButton
@onready var about_display = $AboutDisplay

const MAP_BROWSER_SCENE = preload("res://commons/scenes/main_menu/components/MapBrowser3D.tscn")
const DESKTOP_MENU_PIXELS_PER_UNIT := 1800.0
const MOBILE_MENU_PIXELS_PER_UNIT := 1200.0
var map_browser_instance: Node3D = null

func _ready():
	_configure_menu_rendering()

	new_game_button.clicked.connect(_on_new_game_clicked)
	load_game_button.clicked.connect(_on_load_game_clicked)
	if browse_button:
		browse_button.clicked.connect(_on_browse_clicked)
	settings_button.clicked.connect(_on_settings_clicked)
	quit_button.clicked.connect(_on_quit_clicked)

	# Setup About text
	_setup_about_text()
	
	# Update Load Game button visibility based on save existence
	_update_load_button()

func _configure_menu_rendering() -> void:
	var root_viewport := get_viewport()
	if root_viewport:
		var target_msaa := Viewport.MSAA_2X if OS.has_feature("android") else Viewport.MSAA_4X
		if root_viewport.msaa_3d < target_msaa:
			root_viewport.msaa_3d = target_msaa
		if root_viewport.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED:
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	_configure_embedded_viewport_quality(about_display)

func _configure_embedded_viewport_quality(root: Node) -> void:
	if not root:
		return

	var viewport_2d = root.get_node_or_null("Viewport2Din3D")
	if not viewport_2d:
		return

	var pixels_per_unit := MOBILE_MENU_PIXELS_PER_UNIT if OS.has_feature("android") else DESKTOP_MENU_PIXELS_PER_UNIT
	var screen_size: Vector2 = viewport_2d.screen_size
	viewport_2d.viewport_size = Vector2(
		max(1.0, round(screen_size.x * pixels_per_unit)),
		max(1.0, round(screen_size.y * pixels_per_unit))
	)

	var content_viewport: SubViewport = viewport_2d.get_node_or_null("Viewport")
	if content_viewport:
		content_viewport.msaa_2d = Viewport.MSAA_2X if OS.has_feature("android") else Viewport.MSAA_4X

func _setup_about_text():
	var about_text = """[center][font_size=48][b]THRESHOLD PROTOCOL[/b][/font_size][/center]

[font_size=36]The outside is no longer survivable; the lab and its simulations endure as a shrinking threshold, where the subject must reassemble [b]X[/b]—a queer energy principle—to make return possible.[/font_size]

[center][font_size=32][color=cyan][b]QFE = F − λE(S) + φΔE(S,t)[/b][/color][/font_size][/center]

[center][font_size=28][color=gray][i]"We can only see a short distance ahead, but we can see plenty there that needs to be done."[/i]
— Alan Turing[/color][/font_size][/center]
"""
	if about_display.has_method("set_tutorial_from_text"):
		about_display.set_tutorial_from_text(about_text)

func _update_load_button():
	# Dim Load Game button if no save exists
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	var has_save = false
	
	if checkpoint_manager and checkpoint_manager.has_method("has_checkpoint"):
		has_save = checkpoint_manager.has_checkpoint()
	else:
		# Fallback: check if save file exists
		has_save = FileAccess.file_exists("user://checkpoint.save")
	
	if not load_game_button:
		return
	
	var target_color: Color
	var label_alpha: float
	
	if has_save:
		target_color = Color(0.3, 0.7, 0.9, 1)  # Cyan
		label_alpha = 1.0
	else:
		target_color = Color(0.3, 0.3, 0.3, 1)  # Gray/dimmed
		label_alpha = 0.4
	
	# Update button color property
	load_game_button.color = target_color
	
	# Update material if already created
	var cube = load_game_button.get_node_or_null("InteractionCube")
	if cube and cube.material_override:
		cube.material_override.set_shader_parameter("modelColor", target_color)
		cube.material_override.set_shader_parameter("emissionColor", target_color)
	
	# Update label opacity
	var label = load_game_button.get_node_or_null("Label3D")
	if label:
		label.modulate.a = label_alpha

func _on_new_game_clicked():
	print("MainMenu: New Game clicked")
	
	# Clear any existing checkpoints
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_method("clear_checkpoints"):
		checkpoint_manager.clear_checkpoints()
	
	# Reset map progression
	var progression_manager = get_node_or_null("/root/MapProgressionManager")
	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()
	
	start_game_requested.emit()

func _on_load_game_clicked():
	print("MainMenu: Load Game clicked")
	
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_method("has_checkpoint"):
		if checkpoint_manager.has_checkpoint():
			print("MainMenu: Resuming from checkpoint")
			checkpoint_manager.respawn_at_checkpoint()
			load_game_requested.emit()
		else:
			print("MainMenu: No save found, starting new game")
			_on_new_game_clicked()
	else:
		print("MainMenu: CheckpointManager not available, starting new game")
		_on_new_game_clicked()

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
	_configure_embedded_viewport_quality(settings_instance)

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
